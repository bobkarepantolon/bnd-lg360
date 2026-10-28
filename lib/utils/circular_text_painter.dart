import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Kullanıcı mühür ayarları ekranında metni ve yarıçapı değiştirirken
/// Canvas üzerinde anlık ve canlı önizleme sunan CustomPainter sınıfı.
class CircularTextPainter extends CustomPainter {
  final String text;
  final double radiusRatio; // 0.08 - 0.20
  final Color diskColor;
  final Color textColor;
  final Color borderColor;

  CircularTextPainter({
    required this.text,
    required this.radiusRatio,
    this.diskColor = const Color(0xFF101014),
    this.textColor = const Color(0xFFF5F5F7),
    this.borderColor = Colors.amber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Önizleme alanında görselleştirme yarıçapı
    final double maxR = math.min(size.width, size.height) / 2 - 16;
    final double radius = maxR * (radiusRatio / 0.15).clamp(0.5, 1.0);

    // 1. Dairesel Mühür Dolgusu
    final diskPaint = Paint()
      ..color = diskColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, diskPaint);

    // 2. Altın / Amber Kenarlık Çizgisi
    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);

    // İç süsleme halkası
    final innerRingPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.82, innerRingPaint);

    // Merkez minik logo/artı işareti
    final centerDotPaint = Paint()
      ..color = borderColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, centerDotPaint);

    if (text.trim().isEmpty) return;

    // 3. Çember Yayında Kavisli Metin Çizimi
    final double textRadius = radius * 0.72;
    final cleanText = text.trim();

    // Metnin çember üzerinde kaplayacağı yay açısı
    const double arcSpan = math.pi * 0.75; // ~135 derece
    final double startAngle = (math.pi - arcSpan) / 2;
    final double angleStep = arcSpan / math.max(1, cleanText.length - 1);

    final textStyle = TextStyle(
      color: textColor,
      fontSize: (radius * 0.14).clamp(10.0, 16.0),
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );

    for (int i = 0; i < cleanText.length; i++) {
      final char = cleanText[i];
      if (char == ' ') continue;

      final double angle = math.pi - (startAngle + (i * angleStep));

      final double charX = center.dx + textRadius * math.cos(angle);
      final double charY = center.dy - textRadius * math.sin(angle);

      final textSpan = TextSpan(text: char, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      // Harfin teğet açısına göre döndürme
      canvas.translate(charX, charY);
      final double rotationRad = -angle + (math.pi / 2);
      canvas.rotate(rotationRad);

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CircularTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.radiusRatio != radiusRatio ||
        oldDelegate.diskColor != diskColor ||
        oldDelegate.textColor != textColor;
  }
}
