import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/camera_state.dart';
import '../models/media_file.dart';
import 'network_bridge_service.dart';

class OscApiService {
  static final OscApiService _instance = OscApiService._internal();
  factory OscApiService() => _instance;
  OscApiService._internal();

  final String baseUrl = "http://192.168.43.1";
  final Duration timeout = const Duration(seconds: 10);

  Map<String, String> get _headers => {
        "Content-Type": "application/json; charset=utf-8",
        "X-XSRF-Protected": "1",
      };

  /// Kameranın LGR105 olup olmadığını ve erişilebilirliğini doğrular
  Future<Map<String, dynamic>> checkConnection() async {
    // Android 14+ HyperOS Wi-Fi soketine kilitle
    await NetworkBridgeService.lockToCameraNetwork();

    final url = Uri.parse("$baseUrl/osc/info");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({}),
    ).timeout(timeout);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw HttpException("Kamera /osc/info yanıt vermedi: HTTP ${response.statusCode}");
    }
  }

  /// Kameranın pil seviyesi ve SD kart durumunu sorgular
  Future<CameraState> getDeviceState() async {
    final info = await checkConnection();

    final stateUrl = Uri.parse("$baseUrl/osc/state");
    final stateResponse = await http.post(
      stateUrl,
      headers: _headers,
      body: jsonEncode({}),
    ).timeout(timeout);

    if (stateResponse.statusCode == 200) {
      final stateJson = jsonDecode(utf8.decode(stateResponse.bodyBytes)) as Map<String, dynamic>;
      return CameraState.fromOscResponses(infoJson: info, stateJson: stateJson);
    } else {
      throw HttpException("Kamera /osc/state yanıt vermedi: HTTP ${stateResponse.statusCode}");
    }
  }

  /// Fotoğraf çekme komutu gönderir (camera.takePicture)
  Future<String?> takePhoto() async {
    final url = Uri.parse("$baseUrl/osc/commands/execute");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "name": "camera.takePicture",
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final state = json['state'] as String? ?? "";

      // Eğer doğrudan sonuç döndüyse
      if (state == "done") {
        final results = json['results'] as Map<String, dynamic>?;
        return results?['fileUrl'] as String?;
      }

      // Asenkron işlem (inProgress) ise kısa bir süre bekleyip son çekilen dosyayı bul
      await Future.delayed(const Duration(seconds: 2));
      final files = await fetchMediaList(entryCount: 1);
      if (files.isNotEmpty) {
        return files.first.fileUrl;
      }
      return null;
    } else {
      throw HttpException("Fotoğraf çekilemedi: HTTP ${response.statusCode} - ${response.body}");
    }
  }

  /// Video kaydını başlatır (camera.startCapture)
  Future<bool> startVideoCapture() async {
    final url = Uri.parse("$baseUrl/osc/commands/execute");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "name": "camera.startCapture",
      }),
    ).timeout(timeout);

    return response.statusCode == 200;
  }

  /// Video kaydını durdurur (camera.stopCapture)
  Future<String?> stopVideoCapture() async {
    final url = Uri.parse("$baseUrl/osc/commands/execute");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "name": "camera.stopCapture",
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final results = json['results'] as Map<String, dynamic>?;
      final fileUrls = results?['fileUrls'] as List<dynamic>?;
      if (fileUrls != null && fileUrls.isNotEmpty) {
        return fileUrls.first.toString();
      }
      return null;
    }
    return null;
  }

  /// SD karttaki medyaları listeler (camera.listFiles)
  Future<List<MediaFile>> fetchMediaList({int entryCount = 100}) async {
    final url = Uri.parse("$baseUrl/osc/commands/execute");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "name": "camera.listFiles",
        "parameters": {
          "fileType": "all",
          "entryCount": entryCount,
          "maxThumbSize": 160,
          "_detail": true,
        }
      }),
    ).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final results = json['results'] as Map<String, dynamic>? ?? {};
      final entries = results['entries'] as List<dynamic>? ?? [];

      return entries
          .map((item) => MediaFile.fromOscJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw HttpException("Medya listesi alınamadı: HTTP ${response.statusCode}");
    }
  }

  /// Dosyayı kameradan indirip yerel geçici dizine kaydeder, ilerlemeyi yayınlar
  Future<File> downloadFile({
    required String fileUrl,
    required String fileName,
    required void Function(double progress) onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request("GET", Uri.parse(fileUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException("Dosya indirilemedi: HTTP ${response.statusCode}");
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final localFile = File("${tempDir.path}/$fileName");

      final sink = localFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0) {
          onProgress(receivedBytes / contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      onProgress(1.0);
      return localFile;
    } finally {
      client.close();
    }
  }

  /// Kameradaki dosyayı siler (camera.delete)
  Future<bool> deleteFile(String fileUrl) async {
    final url = Uri.parse("$baseUrl/osc/commands/execute");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "name": "camera.delete",
        "parameters": {
          "fileUrls": [fileUrl]
        }
      }),
    ).timeout(timeout);

    return response.statusCode == 200;
  }

  /// Çekim modunu ayarlar (360 Fotoğraf, 360 Video, 180 Tek Lens)
  Future<bool> setCaptureMode({
    required String mode, // 'image', 'video'
    int? captureInterval,
  }) async {
    final url = Uri.parse("$baseUrl/osc/commands/execute");
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        "name": "camera.setOptions",
        "parameters": {
          "options": {
            "captureMode": mode,
            if (captureInterval != null) "captureInterval": captureInterval,
          }
        }
      }),
    ).timeout(timeout);

    return response.statusCode == 200;
  }
}
