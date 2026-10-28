import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/mjpeg_stream_service.dart';

class MjpegViewfinder extends StatefulWidget {
  final MjpegStreamService streamService;
  final BoxFit fit;

  const MjpegViewfinder({
    super.key,
    required this.streamService,
    this.fit = BoxFit.contain,
  });

  @override
  State<MjpegViewfinder> createState() => _MjpegViewfinderState();
}

class _MjpegViewfinderState extends State<MjpegViewfinder> {
  Uint8List? _currentFrame;
  StreamSubscription<Uint8List>? _subscription;
  int _fpsCounter = 0;
  int _fps = 0;
  DateTime _lastFpsTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  void _subscribeToStream() {
    _subscription = widget.streamService.frameStream.listen((frame) {
      _calculateFps();
      if (mounted) {
        setState(() {
          _currentFrame = frame;
        });
      }
    });
  }

  void _calculateFps() {
    _fpsCounter++;
    final now = DateTime.now();
    if (now.difference(_lastFpsTime).inMilliseconds >= 1000) {
      if (mounted) {
        setState(() {
          _fps = _fpsCounter;
          _fpsCounter = 0;
          _lastFpsTime = now;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrame == null) {
      return Container(
        color: const Color(0xFF0B0B0E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.amber,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "LG 360 Canlı Önizlemesi Bekleniyor...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Kamera Wi-Fi ağına (192.168.43.1) bağlı olduğunuzdan emin olun",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Canlı Kare Çizici (gaplessPlayback sayesinde titreme yapmaz)
        Image.memory(
          _currentFrame!,
          fit: widget.fit,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),

        // Grid (360 Ufuk Çizgisi Rehberi)
        Center(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.12),
          ),
        ),
        Center(
          child: Container(
            width: 1,
            color: Colors.white.withOpacity(0.12),
          ),
        ),

        // Canlı FPS ve Akış Bilgisi
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "$_fps FPS • CANLI",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
