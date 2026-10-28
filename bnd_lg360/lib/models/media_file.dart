class MediaFile {
  final String name;
  final String fileUrl;
  final int size; // bayt cinsinden
  final DateTime dateTime;
  final String? thumbnailUrl;
  final bool isVideo;
  final int? width;
  final int? height;
  final bool isLocal;
  final String? localPath;

  MediaFile({
    required this.name,
    required this.fileUrl,
    required this.size,
    required this.dateTime,
    this.thumbnailUrl,
    this.isVideo = false,
    this.width,
    this.height,
    this.isLocal = false,
    this.localPath,
  });

  factory MediaFile.fromOscJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? "unnamed.jpg";
    final isVid = name.toLowerCase().endsWith(".mp4") ||
        (json['fileType'] as String? ?? "").contains("video");

    DateTime dt = DateTime.now();
    if (json['dateTimeZone'] != null) {
      try {
        dt = DateTime.parse(json['dateTimeZone'] as String);
      } catch (_) {}
    }

    return MediaFile(
      name: name,
      fileUrl: json['fileUrl'] as String? ?? "",
      size: json['size'] as int? ?? 0,
      dateTime: dt,
      thumbnailUrl: json['thumbnail'] as String?,
      isVideo: isVid,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  String get formattedSize {
    if (size <= 0) return "0 KB";
    final double kb = size / 1024;
    final double mb = kb / 1024;
    if (mb >= 1) {
      return "${mb.toStringAsFixed(1)} MB";
    }
    return "${kb.toStringAsFixed(0)} KB";
  }

  String get formattedDate {
    final y = dateTime.year;
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return "$d.$m.$y $hh:$mm";
  }
}
