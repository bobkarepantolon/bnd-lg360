import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../models/media_file.dart';
import '../providers/camera_provider.dart';

class SdGalleryTab extends StatelessWidget {
  const SdGalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();
    final mediaList = camera.mediaList;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        title: const Text(
          "Kamera SD Kartı",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
            onPressed: () => camera.fetchMediaList(),
            tooltip: "Listeyi Yenile",
          ),
        ],
      ),
      body: camera.isLoadingMedia
          ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.amber,
                size: 44.0,
              ),
            )
          : mediaList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 56, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 14),
                      Text(
                        camera.connectionStatus == ConnectionStatus.connected
                            ? "SD kartta henüz fotoğraf veya video bulunmuyor."
                            : "Kameraya bağlı değilsiniz.",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => camera.fetchMediaList(),
                        child: const Text("Yenile"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.amber,
                  backgroundColor: const Color(0xFF16161C),
                  onRefresh: () => camera.fetchMediaList(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: mediaList.length,
                    itemBuilder: (context, index) {
                      final item = mediaList[index];
                      return _buildMediaCard(context, camera, item);
                    },
                  ),
                ),
    );
  }

  Widget _buildMediaCard(BuildContext context, CameraProvider camera, MediaFile media) {
    final progress = camera.downloadProgress[media.fileUrl];
    final status = camera.processingStatus[media.fileUrl];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Medya Önizleme / İkon Alanı
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFF0F0F14),
                  child: media.thumbnailUrl != null
                      ? Image.network(
                          media.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(media),
                        )
                      : _buildPlaceholder(media),
                ),

                // Video veya 360 Rozeti
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          media.isVideo ? Icons.videocam_rounded : Icons.panorama_photosphere_rounded,
                          size: 12,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          media.isVideo ? "MP4" : "360° JPG",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // İlerleme ve Durum Katmanı
                if (status != null)
                  Container(
                    color: Colors.black.withOpacity(0.85),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (progress != null) ...[
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: progress > 0 ? progress : null,
                                strokeWidth: 3,
                                color: Colors.amber,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ] else ...[
                            const SpinKitThreeBounce(color: Colors.amber, size: 20),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.amber, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Alt Bilgi ve İndir Butonu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF1B1B22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      media.formattedSize,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    Text(
                      media.formattedDate,
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // İndir & Mühürle Butonu
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: status != null
                              ? null
                              : () => camera.downloadAndProcess(media),
                          child: const Text(
                            "İNDİR & MÜHÜRLE",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Sil Butonu
                    InkWell(
                      onTap: () => _confirmDelete(context, camera, media),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(MediaFile media) {
    return Center(
      child: Icon(
        media.isVideo ? Icons.play_circle_outline_rounded : Icons.panorama_horizontal_rounded,
        size: 38,
        color: Colors.white.withOpacity(0.2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CameraProvider camera, MediaFile media) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text("Dosyayı Sil?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          "${media.name} dosyasını SD karttan kalıcı olarak silmek istediğinize emin misiniz?",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              camera.deleteMedia(media);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
