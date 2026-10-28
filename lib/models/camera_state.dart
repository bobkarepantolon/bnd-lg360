class CameraState {
  final double batteryLevel; // 0.0 - 1.0 (örn. 0.85 = %85)
  final bool isCharging;
  final int totalStorageBytes;
  final int remainingStorageBytes;
  final int remainingPictures;
  final int remainingVideoMinutes;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final String firmwareVersion;
  final bool isConnected;

  const CameraState({
    this.batteryLevel = 1.0,
    this.isCharging = false,
    this.totalStorageBytes = 0,
    this.remainingStorageBytes = 0,
    this.remainingPictures = 0,
    this.remainingVideoMinutes = 0,
    this.manufacturer = "LG Electronics",
    this.model = "LGR105",
    this.serialNumber = "",
    this.firmwareVersion = "1.0",
    this.isConnected = false,
  });

  factory CameraState.fromOscResponses({
    required Map<String, dynamic> infoJson,
    required Map<String, dynamic> stateJson,
  }) {
    final state = stateJson['state'] as Map<String, dynamic>? ?? {};
    final battery = state['batteryLevel'] != null
        ? (state['batteryLevel'] as num).toDouble()
        : (state['_batteryState'] != null
            ? (state['_batteryState'] as num).toDouble()
            : 1.0);

    final isCharging = state['_batteryCharging'] as bool? ?? false;
    final totalSpace = state['_totalSpace'] as int? ?? (32 * 1024 * 1024 * 1024);
    final remainingSpace = state['_remainingSpace'] as int? ?? 0;
    final remainingPics = state['_remainingPictures'] as int? ?? 0;
    final remainingVid = state['_remainingVideoMinutes'] as int? ?? 0;

    return CameraState(
      batteryLevel: battery > 1.0 ? battery / 100.0 : battery,
      isCharging: isCharging,
      totalStorageBytes: totalSpace,
      remainingStorageBytes: remainingSpace,
      remainingPictures: remainingPics,
      remainingVideoMinutes: remainingVid,
      manufacturer: infoJson['manufacturer'] as String? ?? "LG Electronics",
      model: infoJson['model'] as String? ?? "LGR105",
      serialNumber: infoJson['serialNumber'] as String? ?? "",
      firmwareVersion: infoJson['firmwareVersion'] as String? ?? "1.0",
      isConnected: true,
    );
  }

  String get batteryPercentageString => "${(batteryLevel * 100).toInt()}%";

  String get storageRemainingFormatted {
    if (remainingStorageBytes <= 0) return "Bilinmiyor";
    final double mb = remainingStorageBytes / (1024 * 1024);
    if (mb >= 1024) {
      return "${(mb / 1024).toStringAsFixed(1)} GB";
    }
    return "${mb.toStringAsFixed(0)} MB";
  }
}
