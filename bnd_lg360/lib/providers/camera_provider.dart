import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/camera_state.dart';
import '../models/media_file.dart';
import '../services/osc_api_service.dart';
import '../services/mjpeg_stream_service.dart';
import '../services/nadir_stamper_service.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

enum CaptureMode {
  photo360,
  video360,
  singleLens180,
}

class CameraProvider extends ChangeNotifier {
  final OscApiService _oscApi = OscApiService();
  final MjpegStreamService streamService = MjpegStreamService();

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  ConnectionStatus get connectionStatus => _connectionStatus;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CameraState _cameraState = const CameraState();
  CameraState get cameraState => _cameraState;

  CaptureMode _captureMode = CaptureMode.photo360;
  CaptureMode get captureMode => _captureMode;

  bool _isCapturing = false;
  bool get isCapturing => _isCapturing;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  List<MediaFile> _mediaList = [];
  List<MediaFile> get mediaList => _mediaList;

  bool _isLoadingMedia = false;
  bool get isLoadingMedia => _isLoadingMedia;

  // İndirme ve İşleme Durumları
  final Map<String, double> _downloadProgress = {};
  Map<String, double> get downloadProgress => _downloadProgress;

  final Map<String, String> _processingStatus = {};
  Map<String, String> get processingStatus => _processingStatus;

  // Mühür Ayarları
  bool _autoStampEnabled = true;
  bool get autoStampEnabled => _autoStampEnabled;

  String _stampText = "bendelimiyim.com • BND 360";
  String get stampText => _stampText;

  double _stampRadiusRatio = 0.12; // Görsel yüksekliğinin %12'si
  double get stampRadiusRatio => _stampRadiusRatio;

  CameraProvider() {
    // Uygulama başladığında bağlanmayı dene
    connectToCamera();
  }

  /// Kameraya bağlanır ve cihaz bilgilerini çeker
  Future<void> connectToCamera() async {
    _connectionStatus = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final state = await _oscApi.getDeviceState();
      _cameraState = state;
      _connectionStatus = ConnectionStatus.connected;
      notifyListeners();

      // Canlı önizleme akışını başlat
      try {
        await streamService.startStream();
      } catch (streamError) {
        print("Canlı akış başlatma uyarısı: $streamError");
      }

      // SD kart medya listesini güncelle
      fetchMediaList();
    } catch (e) {
      _connectionStatus = ConnectionStatus.error;
      _errorMessage = "LG 360 Cam bağlantısı kurulamadı. Wi-Fi (LGR105_xxx) ağına bağlı olduğunuzdan emin olun.";
      notifyListeners();
    }
  }

  /// Cihaz durumunu (pil ve hafıza) yeniler
  Future<void> refreshState() async {
    if (_connectionStatus != ConnectionStatus.connected) return;
    try {
      _cameraState = await _oscApi.getDeviceState();
      notifyListeners();
    } catch (e) {
      print("Durum yenileme hatası: $e");
    }
  }

  /// Çekim modunu değiştirir
  void setCaptureMode(CaptureMode mode) {
    _captureMode = mode;
    notifyListeners();
  }

  /// Deklanşör tetikleme (Fotoğraf veya Video)
  Future<void> triggerShutter() async {
    if (_connectionStatus != ConnectionStatus.connected) return;

    if (_captureMode == CaptureMode.photo360 || _captureMode == CaptureMode.singleLens180) {
      await _takePicture();
    } else {
      await _toggleVideo();
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    _isCapturing = true;
    notifyListeners();

    try {
      final fileUrl = await _oscApi.takePhoto();
      _isCapturing = false;
      notifyListeners();

      await refreshState();
      await fetchMediaList();

      // Eğer otomatik mühürleme açıksa ve URL geldiyse otomatik indir & mühürle
      if (fileUrl != null && _autoStampEnabled) {
        final newFile = MediaFile(
          name: fileUrl.split("/").last,
          fileUrl: fileUrl,
          size: 0,
          dateTime: DateTime.now(),
        );
        downloadAndProcess(newFile);
      }
    } catch (e) {
      _isCapturing = false;
      _errorMessage = "Fotoğraf çekme başarısız: $e";
      notifyListeners();
    }
  }

  Future<void> _toggleVideo() async {
    if (_isRecording) {
      // Kaydı durdur
      try {
        _isCapturing = true;
        notifyListeners();
        await _oscApi.stopVideoCapture();
        _isRecording = false;
        _isCapturing = false;
        notifyListeners();
        await refreshState();
        await fetchMediaList();
      } catch (e) {
        _isCapturing = false;
        _errorMessage = "Video durdurulamadı: $e";
        notifyListeners();
      }
    } else {
      // Kaydı başlat
      try {
        final success = await _oscApi.startVideoCapture();
        if (success) {
          _isRecording = true;
          notifyListeners();
        }
      } catch (e) {
        _errorMessage = "Video başlatılamadı: $e";
        notifyListeners();
      }
    }
  }

  /// SD kart dosya listesini çeker
  Future<void> fetchMediaList() async {
    _isLoadingMedia = true;
    notifyListeners();

    try {
      _mediaList = await _oscApi.fetchMediaList();
      _isLoadingMedia = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMedia = false;
      notifyListeners();
    }
  }

  /// Dosyayı indirir, gerekirse Nadir mührünü basar ve galeriye kaydeder
  Future<void> downloadAndProcess(MediaFile media) async {
    final fileKey = media.fileUrl;
    _downloadProgress[fileKey] = 0.01;
    _processingStatus[fileKey] = "İndiriliyor...";
    notifyListeners();

    try {
      final File downloadedFile = await _oscApi.downloadFile(
        fileUrl: media.fileUrl,
        fileName: media.name,
        onProgress: (progress) {
          _downloadProgress[fileKey] = progress;
          notifyListeners();
        },
      );

      // Fotoğraf ve otomatik mühürleme açıksa mühür uygula
      if (!media.isVideo && _autoStampEnabled) {
        _processingStatus[fileKey] = "Nadir Mührü İşleniyor...";
        notifyListeners();

        final rawBytes = await downloadedFile.readAsBytes();
        final stampedBytes = await NadirStamperService.applyNadirStamp(
          inputBytes: rawBytes,
          stampText: _stampText,
          radiusRatio: _stampRadiusRatio,
        );

        _processingStatus[fileKey] = "Galeriye Kaydediliyor...";
        notifyListeners();

        await NadirStamperService.saveToPhoneGallery(
          bytes: stampedBytes,
          originalFileName: media.name,
        );
      } else {
        _processingStatus[fileKey] = "Galeriye Kaydediliyor...";
        notifyListeners();

        final rawBytes = await downloadedFile.readAsBytes();
        await NadirStamperService.saveToPhoneGallery(
          bytes: rawBytes,
          originalFileName: media.name,
        );
      }

      _downloadProgress.remove(fileKey);
      _processingStatus[fileKey] = "Tamamlandı (DCIM/BND360)";
      notifyListeners();

      // 4 saniye sonra bildirim durumunu temizle
      Future.delayed(const Duration(seconds: 4), () {
        _processingStatus.remove(fileKey);
        notifyListeners();
      });
    } catch (e) {
      _downloadProgress.remove(fileKey);
      _processingStatus[fileKey] = "Hata: $e";
      notifyListeners();
    }
  }

  /// Dosyayı kameranın SD kartından siler
  Future<bool> deleteMedia(MediaFile media) async {
    try {
      final success = await _oscApi.deleteFile(media.fileUrl);
      if (success) {
        _mediaList.removeWhere((item) => item.fileUrl == media.fileUrl);
        notifyListeners();
        await refreshState();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Dosya silinemedi: $e";
      notifyListeners();
      return false;
    }
  }

  /// Mühür ayarlarını günceller
  void updateStampSettings({
    String? text,
    double? radiusRatio,
    bool? autoStamp,
  }) {
    if (text != null) _stampText = text;
    if (radiusRatio != null) _stampRadiusRatio = radiusRatio;
    if (autoStamp != null) _autoStampEnabled = autoStamp;
    notifyListeners();
  }

  @override
  void dispose() {
    streamService.dispose();
    super.dispose();
  }
}
