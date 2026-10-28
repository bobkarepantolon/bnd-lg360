import 'package:flutter/services.dart';

class NetworkBridgeService {
  static const MethodChannel _channel = MethodChannel('com.bnd.bnd_lg360/network');

  /// Android 14+ HyperOS üzerinde soketi internetsiz kamera Wi-Fi'ına (192.168.43.1) bağlar.
  /// Bu sayede telefon hücresel veriye kaçmaz ve kamera istekleri başarıyla ulaşır.
  static Future<bool> lockToCameraNetwork() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('bindToCameraWifi');
      return success ?? false;
    } on PlatformException catch (e) {
      print("Ağ kilitleme hatası: ${e.message}");
      return false;
    } catch (e) {
      print("Ağ kilitleme genel hatası: $e");
      return false;
    }
  }

  /// Kameradan çıkıldığında veya uygulama kapandığında soket kilidini kaldırır,
  /// telefonun normal internete ve hücresel veriye dönmesini sağlar.
  static Future<void> releaseNetwork() async {
    try {
      await _channel.invokeMethod('releaseNetwork');
    } on PlatformException catch (e) {
      print("Ağ serbest bırakma hatası: ${e.message}");
    } catch (e) {
      print("Ağ serbest bırakma genel hatası: $e");
    }
  }
}
