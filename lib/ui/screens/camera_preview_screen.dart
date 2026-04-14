import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:ai_vision_pro/features/camera/camera_provider.dart';
import 'package:ai_vision_pro/features/detection/detection_provider.dart';
import 'package:ai_vision_pro/features/tts/tts_provider.dart';
import 'package:ai_vision_pro/features/vibration/vibration_provider.dart';
import 'package:ai_vision_pro/features/voice_command/voice_command_provider.dart';
import 'package:ai_vision_pro/features/accessibility/accessibility_provider.dart';

/// Camera preview screen with real-time detection overlay
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
    final vibrationProvider = context.read<VibrationProvider>();
    
    detectionProvider.onSpeakText = (text) async {
      if (context.read<AccessibilityProvider>().isVoiceGuidanceEnabled) {
        await ttsProvider.speak(text, interrupt: false);
        
        // Check for priority objects for vibration
        final priorityDetections = detectionProvider.currentDetections
            .where((d) => detectionProvider.getObstaclePriority(d.label) == ObstaclePriority.critical)
            .toList();
        
        if (priorityDetections.isNotEmpty && context.read<AccessibilityProvider>().isHapticFeedbackEnabled) {
          vibrationProvider.vibrateForObject(
            isPriority: true,
            spatialLocation: priorityDetections.first.spatialLocation,
          );
        } else if (detectionProvider.currentDetections.isNotEmpty && context.read<AccessibilityProvider>().isHapticFeedbackEnabled) {
          vibrationProvider.vibrateForObject(
            isPriority: false,
            spatialLocation: detectionProvider.currentDetections.first.spatialLocation,
          );
        }
      }
    };
  }

  void _startVoiceCommandListener() {
    final voiceCommandProvider = context.read<VoiceCommandProvider>();
    final ttsProvider = context.read<TTSProvider>();
    final detectionProvider = context.read<DetectionProvider>();
    
    voiceCommandProvider.onVoiceCommand = (command) async {
      switch (command) {
        case VoiceCommand.startScanning:
          ttsProvider.speak('Already scanning');
          break;
        case VoiceCommand.stopScanning:
          await _stopScanning();
          break;
        case VoiceCommand.readText:
          detectionProvider.toggleOcr();
          if (detectionProvider.isOcrEnabled) {
            ttsProvider.speak('Reading text mode enabled');
          } else {
            ttsProvider.speak('Reading text mode disabled');
          }
          break;
        case VoiceCommand.describeSurroundings:
          ttsProvider.speak('Describing surroundings');
          await detectionProvider.describeSurroundings();
          break;
        case VoiceCommand.emergency:
          _triggerEmergency();
          break;
        case VoiceCommand.unknown:
          break;
      }
    };
  }

  Future<void> _stopScanning() async {
    final cameraProvider = context.read<CameraProvider>();
    final ttsProvider = context.read<TTSProvider>();
    
    await cameraProvider.stopStream();
    ttsProvider.speak('Scanning stopped');
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _triggerEmergency() {
    final vibrationProvider = context.read<VibrationProvider>();
    final ttsProvider = context.read<TTSProvider>();
    
    vibrationProvider.vibrateForEmergency();
    ttsProvider.speak('Emergency alert activated');
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();
    final detectionProvider = context.watch<DetectionProvider>();
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(cameraProvider.controller!),
          ),
          
          // Detection overlay
          Positioned.fill(
            child: CustomPaint(
              painter: DetectionOverlayPainter(
                detections: detectionProvider.currentDetections,
              ),
            ),
          ),
          
          // Top bar with status
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(accessibilityProvider, detectionProvider),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
          
          // Current detection indicator
          if (detectionProvider.currentDetections.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: _buildDetectionIndicator(detectionProvider),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AccessibilityProvider accessibilityProvider, DetectionProvider detectionProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // OCR status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: detectionProvider.isOcrEnabled ? Colors.orange : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.text_fields,
                  size: 20 * accessibilityProvider.textScaleFactor,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  detectionProvider.isOcrEnabled ? 'OCR ON' : 'OCR OFF',
                  style: TextStyle(
                    fontSize: 14 * accessibilityProvider.textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Stop button
          Semantics(
            label: 'Stop scanning. Double tap to stop.',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.stop, size: 36, color: Colors.red),
              onPressed: () => _stopScanning(),
              padding: const EdgeInsets.all(12),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle OCR
          _buildControlButton(
            icon: Icons.text_fields,
            label: 'Read Text',
            onPressed: () {
              context.read<DetectionProvider>().toggleOcr();
            },
          ),
          
          // Describe surroundings
          _buildControlButton(
            icon: Icons.visibility,
            label: 'What\'s Around?',
            onPressed: () {
              context.read<DetectionProvider>().describeSurroundings();
            },
          ),
          
          // Flash toggle
          _buildControlButton(
            icon: Icons.flash_on,
            label: 'Flash',
            onPressed: () {
              context.read<CameraProvider>().toggleFlash();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Semantics(
      label: '$label. Double tap to activate.',
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * accessibilityProvider.textScaleFactor,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionIndicator(DetectionProvider detectionProvider) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    if (detectionProvider.currentDetections.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final topDetections = detectionProvider.currentDetections.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          ...topDetections.map((detection) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${detection.label} (${(detection.confidence * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 14 * accessibilityProvider.textScaleFactor,
                color: Colors.white,
              ),
            ),
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<CameraProvider>().stopStream();
    super.dispose();
  }
}

/// Custom painter to draw bounding boxes around detected objects
class DetectionOverlayPainter extends CustomPainter {
  final List<AppDetectedObject> detections;
  
  DetectionOverlayPainter({required this.detections});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    for (final detection in detections) {
      if (detection.boundingBox != null) {
        // Convert bounding box to screen coordinates
        final rect = Rect.fromLTWH(
          detection.boundingBox!.left * size.width,
          detection.boundingBox!.top * size.height,
          detection.boundingBox!.width * size.width,
          detection.boundingBox!.height * size.height,
        );
        
        canvas.drawRect(rect, paint);
        
        // Draw label
        final textPainter = TextPainter(
          text: TextSpan(
            text: detection.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
