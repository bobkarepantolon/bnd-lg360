import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/mjpeg_viewfinder.dart';

class ViewfinderTab extends StatelessWidget {
  const ViewfinderTab({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();
    final state = camera.cameraState;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E),
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bilgi Çubuğu (Status Bar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF121217),
              child: Row(
                children: [
                  // Bağlantı Durumu
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: camera.connectionStatus == ConnectionStatus.connected
                          ? const Color(0xFF10B981)
                          : (camera.connectionStatus == ConnectionStatus.connecting
                              ? Colors.amber
                              : const Color(0xFFEF4444)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    camera.connectionStatus == ConnectionStatus.connected
                        ? "LGR105 • BAĞLI"
                        : (camera.connectionStatus == ConnectionStatus.connecting
                            ? "BAĞLANIYOR..."
                            : "BAĞLANTI YOK"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),

                  // MicroSD Kalan Alan
                  if (camera.connectionStatus == ConnectionStatus.connected) ...[
                    const Icon(Icons.sd_card_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      state.storageRemainingFormatted,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 16),

                    // Pil Durumu
                    Icon(
                      state.isCharging
                          ? Icons.battery_charging_full_rounded
                          : (state.batteryLevel > 0.8
                              ? Icons.battery_full_rounded
                              : (state.batteryLevel > 0.3
                                  ? Icons.battery_5_bar_rounded
                                  : Icons.battery_alert_rounded)),
                      color: state.batteryLevel < 0.2 ? Colors.redAccent : Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.batteryPercentageString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.amber, size: 20),
                      onPressed: () => camera.connectToCamera(),
                      tooltip: "Yeniden Bağlan",
                    ),
                  ],
                ],
              ),
            ),

            // Hata / Bilgilendirme Banner'ı
            if (camera.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF7F1D1D),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        camera.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    TextButton(
                      onPressed: () => camera.connectToCamera(),
                      child: const Text(
                        "TEKRAR DENE",
                        style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Canlı Vizör (2:1 Equirectangular MJPEG Stream)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 2.0 / 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.symmetric(
                        horizontal: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                    child: camera.connectionStatus == ConnectionStatus.connected
                        ? MjpegViewfinder(streamService: camera.streamService)
                        : Container(
                            color: const Color(0xFF0F0F14),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(0.3), size: 44),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Kamera Wi-Fi Ağına Bağlanın",
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Wi-Fi SSID: LGR105_xxxxxx\nVarsayılan Şifre: Seri numarasının son 8 hanesi",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    onPressed: () => camera.connectToCamera(),
                                    icon: const Icon(Icons.sync_rounded),
                                    label: const Text("BAĞLANTIYI KONTROL ET", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Alt Kontrol Alanı (Deklanşör ve Mod Seçici)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF121217),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Çekim Modu Seçici
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E26),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeButton(
                          context,
                          mode: CaptureMode.photo360,
                          label: "360° Fotoğraf",
                          isSelected: camera.captureMode == CaptureMode.photo360,
                        ),
                        _buildModeButton(
                          context,
                          mode: CaptureMode.video360,
                          label: "360° Video",
                          isSelected: camera.captureMode == CaptureMode.video360,
                        ),
                        _buildModeButton(
                          context,
                          mode: CaptureMode.singleLens180,
                          label: "180° Tek Lens",
                          isSelected: camera.captureMode == CaptureMode.singleLens180,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Büyük Deklanşör Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Otomatik Mühür Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: camera.autoStampEnabled
                              ? Colors.amber.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: camera.autoStampEnabled ? Colors.amber : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: camera.autoStampEnabled ? Colors.amber : Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              camera.autoStampEnabled ? "MÜHÜR AÇIK" : "MÜHÜR KAPALI",
                              style: TextStyle(
                                color: camera.autoStampEnabled ? Colors.amber : Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ana Deklanşör Butonu
                      GestureDetector(
                        onTap: camera.isCapturing
                            ? null
                            : () => camera.triggerShutter(),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: camera.isRecording ? Colors.redAccent : Colors.amber,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (camera.isRecording ? Colors.redAccent : Colors.amber)
                                    .withOpacity(0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: camera.isRecording ? 30 : 60,
                              height: camera.isRecording ? 30 : 60,
                              decoration: BoxDecoration(
                                color: camera.isRecording ? Colors.redAccent : Colors.white,
                                borderRadius: BorderRadius.circular(camera.isRecording ? 8 : 30),
                              ),
                              child: camera.isCapturing
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Son Çekim / İndirilen Durumu
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 26),
                        onPressed: () => camera.refreshState(),
                        tooltip: "Durumu Yenile",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required CaptureMode mode,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => context.read<CameraProvider>().setCaptureMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
