import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'network_bridge_service.dart';

class MjpegStreamService {
  http.Client? _client;
  StreamSubscription<List<int>>? _subscription;
  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get frameStream => _frameController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  // JPEG Sihirli Baytları (Magic Bytes)
  static const int _soiFirst = 0xFF;
  static const int _soiSecond = 0xD8;
  static const int _eoiFirst = 0xFF;
  static const int _eoiSecond = 0xD9;

  /// Kameradan canlı akışı başlatır (camera.getLivePreview)
  Future<void> startStream({
    String baseUrl = "http://192.168.43.1",
  }) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // Soketi Wi-Fi'a bağla
      await NetworkBridgeService.lockToCameraNetwork();

      _client = http.Client();
      final uri = Uri.parse("$baseUrl/osc/commands/execute");

      final request = http.Request("POST", uri)
        ..headers.addAll({
          "Content-Type": "application/json; charset=utf-8",
          "X-XSRF-Protected": "1",
        })
        ..body = jsonEncode({
          "name": "camera.getLivePreview",
        });

      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        throw Exception("Kamera canlı akışı reddetti: HTTP ${response.statusCode}");
      }

      final List<int> buffer = [];

      _subscription = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          while (true) {
            // 1. JPEG Başlangıcını (SOI: 0xFF 0xD8) ara
            final startIndex = _findSequence(buffer, _soiFirst, _soiSecond);
            if (startIndex == -1) {
              // SOI henüz gelmediyse veya baş kısımda çöp veri varsa buffer'ı temiz tut
              if (buffer.length > 4096) {
                buffer.removeRange(0, buffer.length - 2);
              }
              break;
            }

            // 2. JPEG Bitişini (EOI: 0xFF 0xD9) SOI sonrasından itibaren ara
            final endIndex =
                _findSequence(buffer, _eoiFirst, _eoiSecond, startIndex + 2);
            if (endIndex == -1) {
              // Henüz karenin tamamı gelmedi, yeni chunk bekle
              break;
            }

            // 3. Tam bir JPEG karesi bulundu (EOI baytları dahil: endIndex + 2)
            final frameBytes =
                Uint8List.fromList(buffer.sublist(startIndex, endIndex + 2));

            if (!_frameController.isClosed) {
              _frameController.add(frameBytes);
            }

            // 4. Okunan kareyi ve öncesini tampondan temizle
            buffer.removeRange(0, endIndex + 2);
          }
        },
        onError: (error) {
          stopStream();
        },
        onDone: () {
          stopStream();
        },
        cancelOnError: true,
      );
    } catch (e) {
      stopStream();
      rethrow;
    }
  }

  /// Bayt listesinde belirli iki ardışık baytı arar
  int _findSequence(List<int> data, int b1, int b2, [int startIndex = 0]) {
    for (int i = startIndex; i < data.length - 1; i++) {
      if (data[i] == b1 && data[i + 1] == b2) {
        return i;
      }
    }
    return -1;
  }

  /// Akışı güvenli bir şekilde kapatır ve soketi serbest bırakır
  void stopStream() {
    _isRunning = false;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }

  void dispose() {
    stopStream();
    _frameController.close();
  }
}
