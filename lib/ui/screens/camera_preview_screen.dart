import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:ai_vision_pro/features/camera/camera_provider.dart';
import 'package:ai_vision_pro/features/detection/detection_provider.dart';
import 'package:ai_vision_pro/features/tts/tts_provider.dart';
import 'package:ai_vision_pro/features/voice_command/voice_command_provider.dart';
import 'package:ai_vision_pro/features/accessibility/accessibility_provider.dart';
import 'package:ai_vision_pro/features/emergency/emergency_provider.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  @override
  void initState() {
    super.initState();
    _setupDetectionCallback();
    _startVoiceCommandListener();
  }

  void _setupDetectionCallback() {
    final detectionProvider = context.read<DetectionProvider>();
    final ttsProvider = context.read<TTSProvider>();

    detectionProvider.onSpeakText = (text) async {
      if (context.read<AccessibilityProvider>().isVoiceGuidanceEnabled) {
        await ttsProvider.speak(text, interrupt: false);
      }
    };
  }

  void _startVoiceCommandListener() {
    final voiceCommandProvider = context.read<VoiceCommandProvider>();
    final detectionProvider = context.read<DetectionProvider>();

    voiceCommandProvider.onVoiceCommand = (command) async {
      switch (command) {
        case VoiceCommand.stopScanning:
          await _stopScanning();
          break;
        case VoiceCommand.readText:
          detectionProvider.toggleOcr();
          break;
        case VoiceCommand.describeSurroundings:
          await detectionProvider.describeSurroundings();
          break;
        case VoiceCommand.emergency:
          _triggerEmergency();
          break;
        default:
          break;
      }
    };
  }

  Future<void> _stopScanning() async {
    await context.read<CameraProvider>().stopStream();
    if (mounted) Navigator.pop(context);
  }

  void _triggerEmergency() {
    final cameraProvider = context.read<CameraProvider>();
    context.read<EmergencyProvider>().toggleEmergency(cameraProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();
    final detectionProvider = context.watch<DetectionProvider>();
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    final emergencyProvider = context.watch<EmergencyProvider>();

    if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(cameraProvider.controller!)),
          Positioned.fill(
            child: CustomPaint(
              painter: DetectionOverlayPainter(
                detections: detectionProvider.currentDetections,
                imageWidth: detectionProvider.lastImageWidth.toDouble(),
                imageHeight: detectionProvider.lastImageHeight.toDouble(),
              ),
            ),
          ),
          if (emergencyProvider.isEmergencyActive)
            Positioned.fill(
              child: Container(
                color: Colors.red.withAlpha(100),
              ),
            ),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child:
                  _buildTopGlassBar(accessibilityProvider, detectionProvider)),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomGlassControls(emergencyProvider)),
          if (detectionProvider.currentDetections.isNotEmpty)
            Positioned(
                top: 120,
                left: 20,
                right: 20,
                child: _buildGlassDetectionIndicator(detectionProvider)),
        ],
      ),
    );
  }

  Widget _buildTopGlassBar(AccessibilityProvider accessibilityProvider,
      DetectionProvider detectionProvider) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding:
              const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(76),
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(25))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: detectionProvider.isOcrEnabled
                      ? Colors.orangeAccent.withAlpha(204)
                      : Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.text_fields,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                        detectionProvider.isOcrEnabled
                            ? 'OCR ACTIVE'
                            : 'OCR OFF',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 32, color: Colors.white),
                onPressed: () => _stopScanning(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGlassControls(EmergencyProvider emergencyProvider) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.only(top: 24, bottom: 40),
          decoration: BoxDecoration(
            color: emergencyProvider.isEmergencyActive
                ? Colors.red.withAlpha(100)
                : Colors.black.withAlpha(102),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(50))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlIcon(Icons.text_fields, 'Read',
                  () => context.read<DetectionProvider>().toggleOcr()),
              _buildControlIcon(
                  Icons.visibility,
                  'Describe',
                  () =>
                      context.read<DetectionProvider>().describeSurroundings(),
                  isLarge: true),
              _buildControlIcon(
                  emergencyProvider.isEmergencyActive
                      ? Icons.stop_circle
                      : Icons.warning,
                  'Emergency',
                  _triggerEmergency,
                  color: emergencyProvider.isEmergencyActive
                      ? Colors.white
                      : Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlIcon(IconData icon, String label, VoidCallback onPressed,
      {bool isLarge = false, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isLarge ? 24 : 16),
            decoration: BoxDecoration(
              color: color == Colors.white
                  ? Colors.white.withAlpha(38)
                  : color.withAlpha(100),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color == Colors.white
                      ? Colors.white.withAlpha(76)
                      : color.withAlpha(200)),
            ),
            child: Icon(icon, size: isLarge ? 36 : 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGlassDetectionIndicator(DetectionProvider detectionProvider) {
    final topDetections = detectionProvider.currentDetections.take(5).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(127),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.blueAccent.withAlpha(127), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Detections',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(76),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${detectionProvider.currentDetections.length}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...topDetections.map((d) {
                final confPercent = (d.confidence * 100).toInt();
                final confColor = confPercent >= 80
                    ? Colors.greenAccent
                    : confPercent >= 60
                        ? Colors.yellowAccent
                        : Colors.orangeAccent;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: confColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('$confPercent%',
                          style: TextStyle(
                              color: confColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    context.read<CameraProvider>().stopStream();
    super.dispose();
  }
}

class DetectionOverlayPainter extends CustomPainter {
  final List<AppDetectedObject> detections;
  final double imageWidth;
  final double imageHeight;

  DetectionOverlayPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final boxPaint = Paint()
      ..color = Colors.blueAccent.withAlpha(153)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = Colors.blueAccent.withAlpha(25)
      ..style = PaintingStyle.fill;
    final labelBgPaint = Paint()
      ..color = Colors.blueAccent.withAlpha(178)
      ..style = PaintingStyle.fill;

    for (final detection in detections) {
      if (detection.boundingBox != null) {
        final rect = Rect.fromLTWH(
          detection.boundingBox!.left * scaleX,
          detection.boundingBox!.top * scaleY,
          detection.boundingBox!.width * scaleX,
          detection.boundingBox!.height * scaleY,
        );

        final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(rRect, fillPaint);
        canvas.drawRRect(rRect, boxPaint);

        final labelText =
            '${detection.label} ${(detection.confidence * 100).toInt()}%';
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top - 22, textPainter.width + 12, 20),
          const Radius.circular(6),
        );
        canvas.drawRRect(labelRect, labelBgPaint);
        textPainter.paint(canvas, Offset(rect.left + 6, rect.top - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) =>
      oldDelegate.detections != detections ||
      oldDelegate.imageWidth != imageWidth ||
      oldDelegate.imageHeight != imageHeight;
}
