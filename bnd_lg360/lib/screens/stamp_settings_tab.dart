import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../utils/circular_text_painter.dart';

class StampSettingsTab extends StatefulWidget {
  const StampSettingsTab({super.key});

  @override
  State<StampSettingsTab> createState() => _StampSettingsTabState();
}

class _StampSettingsTabState extends State<StampSettingsTab> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CameraProvider>();
    _textController = TextEditingController(text: provider.stampText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        title: const Text(
          "360° Nadir Mühür Ayarları",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Canlı Dinamik Mühür Önizleme Alanı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF14141A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  const Text(
                    "CANLI MÜHÜR ÖNİZLEMESİ",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: CircularTextPainter(
                        text: camera.stampText,
                        radiusRatio: camera.stampRadiusRatio,
                        diskColor: const Color(0xFF0E0E12),
                        textColor: Colors.white,
                        borderColor: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "360° Görsel Alt Taban Merkezi (X: W/2, Y: H)",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Otomatik Mühürleme Switch Kartı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.amber,
                title: const Text(
                  "Otomatik Mühür Uygula",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "İndirilen ve çekilen 360 fotoğrafların alt kör noktasına (tripod/el) mührü otomatik uygular.",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                value: camera.autoStampEnabled,
                onChanged: (val) {
                  camera.updateStampSettings(autoStamp: val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Metin Düzenleme Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mühür Metni",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F0F14),
                      hintText: "Örn: bendelimiyim.com • BND 360",
                      hintStyle: const TextStyle(color: Colors.white24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                    ),
                    onChanged: (val) {
                      camera.updateStampSettings(text: val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mühür Çapı Slider Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mühür Yarıçapı (Yükseklik Oranı)",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "%${(camera.stampRadiusRatio * 100).toInt()}",
                        style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: camera.stampRadiusRatio,
                    min: 0.08,
                    max: 0.20,
                    divisions: 12,
                    activeColor: Colors.amber,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      camera.updateStampSettings(radiusRatio: val);
                    },
                  ),
                  Text(
                    "Önerilen: %10 - %14. Tripod ve monopod kalınlığına göre ayarlayabilirsiniz.",
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Depolama ve Xiaomi HyperOS Bilgi Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121217),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.folder_special_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kayıt Konumu: DCIM/BND360",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Android 14 (HyperOS) Scoped Storage standartlarına uygun olarak galerinize doğrudan kaydedilir ve Google Fotoğraflar / Mi Galeri tarafından anında taranır.",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
