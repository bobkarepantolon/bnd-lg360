import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class NadirStamperService {
  /// 360° equirectangular görsele alt kör nokta (nadir) mührü basar.
  /// 
  /// - [inputBytes]: Ham JPEG bayt dizisi.
  /// - [stampText]: Mühür üzerine kavisli yazılacak metin (örn: "bendelimiyim.com • BND 360").
  /// - [radiusRatio]: Mührün görsel yüksekliğine oranı (Önerilen: 0.08 - 0.16 arası, varsayılan %12).
  /// - [backgroundColor]: Mühür zemin rengi (varsayılan mat siyah #0C0C0C).
  static Future<Uint8List> applyNadirStamp({
    required Uint8List inputBytes,
    String stampText = "bendelimiyim.com • BND 360",
    double radiusRatio = 0.12,
    img.Color? backgroundColor,
  }) async {
    // 1. Görseli çözümle
    final img.Image? original = img.decodeImage(inputBytes);
    if (original == null) {
      throw Exception("Görsel çözümlenemedi (Geçersiz JPEG/PNG formatı).");
    }

    final int width = original.width;
    final int height = original.height;

    // Nadir merkezi: 2:1 oranlı equirectangular görselin tam alt orta noktası (X = W/2, Y = H)
    final int centerX = width ~/ 2;
    final int centerY = height;

    // Mühür yarıçapı (piksel cinsinden)
    final int radius = (height * radiusRatio).toInt();
    final bgColor = backgroundColor ?? img.ColorRgb8(12, 12, 12);

    // 2. Taban Merkezli Dairesel Siyah Mühür Maskesi Çizimi
    // Küresel projeksiyonda alt kutbun izdüşümü için taban merkezli yarım disk doldurulur
    for (int y = height - radius; y < height; y++) {
      final int dy = centerY - y;
      final int dxLimit = math.sqrt(math.max(0, radius * radius - dy * dy)).toInt();

      final int startX = math.max(0, centerX - dxLimit);
      final int endX = math.min(width - 1, centerX + dxLimit);

      for (int x = startX; x <= endX; x++) {
        original.setPixel(x, y, bgColor);
      }
    }

    // İnce şık altın/amber renkli veya beyaz dış kontur çizgisi (1-2 px)
    final outlineColor = img.ColorRgb8(255, 179, 0); // Amber
    for (int deg = 0; deg <= 180; deg++) {
      final rad = deg * math.pi / 180.0;
      final px = (centerX + radius * math.cos(rad)).toInt();
      final py = (centerY - radius * math.sin(rad)).toInt();
      if (px >= 0 && px < width && py >= 0 && py < height) {
        original.setPixel(px, py, outlineColor);
      }
    }

    // 3. Çember Yayı Boyunca Kavisli Metin Çizimi
    if (stampText.trim().isNotEmpty) {
      _drawCurvedText(
        image: original,
        text: stampText.trim(),
        centerX: centerX,
        centerY: centerY,
        radius: (radius * 0.72).toInt(), // Metni diskin iç çemberine konumlandır
        textColor: img.ColorRgb8(245, 245, 245),
      );
    }

    // 4. Kalite kaybını minimize ederek JPEG olarak kodla (Varsayılan kalite: %95)
    return Uint8List.fromList(img.encodeJpg(original, quality: 95));
  }

  /// Metni radyan açısı boyunca yay şeklinde harf harf çizer
  static void _drawCurvedText({
    required img.Image image,
    required String text,
    required int centerX,
    required int centerY,
    required int radius,
    required img.Color textColor,
  }) {
    // Dahili bitmap yazı tipi (Görsel çözünürlüğüne göre ölçekle)
    final font = image.width > 3000 ? img.arial48 : img.arial24;

    // Metnin çember üzerinde kaplayacağı toplam açı genişliği (Radyan cinsinden, ~110°)
    const double arcSpan = math.pi * 0.65;
    final double startAngle = (math.pi - arcSpan) / 2;
    final double angleStep = arcSpan / math.max(1, text.length - 1);

    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      if (char == ' ') continue;

      // Üst yay boyunca açıyı hesapla (saat yönünün tersine simetrik)
      final double angle = math.pi - (startAngle + (i * angleStep));

      // Polar -> Kartezyen koordinat dönüşümü
      final int charX = (centerX + radius * math.cos(angle)).toInt();
      final int charY = (centerY - radius * math.sin(angle)).toInt();

      // Harfi oluşturup açısına göre döndür
      final charImage = img.Image(
        width: font.lineHeight * 2,
        height: font.lineHeight * 2,
        numChannels: 4,
      );
      charImage.clear(img.ColorRgba8(0, 0, 0, 0)); // Şeffaf arka plan

      img.drawString(
        charImage,
        char,
        font: font,
        x: font.lineHeight ~/ 2,
        y: font.lineHeight ~/ 4,
        color: textColor,
      );

      // Harfi teğet açıya göre döndür
      final double rotationDegrees = (angle * 180 / math.pi) - 90;
      final rotatedChar = img.copyRotate(charImage, angle: rotationDegrees);

      // Harfi ana görsel üzerine bindir (composite)
      img.compositeImage(
        image,
        rotatedChar,
        dstX: charX - (rotatedChar.width ~/ 2),
        dstY: charY - (rotatedChar.height ~/ 2),
      );
    }
  }

  /// Mühürlenen görseli Android 14 Scoped Storage (DCIM/BND360) dizinine kaydeder
  static Future<String> saveToPhoneGallery({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    // Gal paketinin izin kontrolü
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw Exception("Galeriye kaydetme izni reddedildi.");
      }
    }

    final tempDir = await getTemporaryDirectory();
    final stampedFileName = originalFileName.replaceAll(".jpg", "_BND360.jpg");
    final tempFilePath = "${tempDir.path}/$stampedFileName";
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(bytes);

    // DCIM/BND360 albümüne kaydet (Android 14 MediaStore otomatik indeksler)
    await Gal.putImage(tempFilePath, album: "BND360");

    return tempFilePath;
  }
}
