import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_vision_pro/features/camera/camera_provider.dart';
import 'package:ai_vision_pro/features/detection/detection_provider.dart';
import 'package:ai_vision_pro/features/tts/tts_provider.dart';
import 'package:ai_vision_pro/features/vibration/vibration_provider.dart';
import 'package:ai_vision_pro/features/voice_command/voice_command_provider.dart';
import 'package:ai_vision_pro/features/accessibility/accessibility_provider.dart';
import 'package:ai_vision_pro/core/services/permission_service.dart';
import 'package:ai_vision_pro/ui/screens/camera_preview_screen.dart';
import 'package:ai_vision_pro/ui/screens/settings_screen.dart';

/// Main home screen with accessibility-first design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasCameraPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    _hasCameraPermission = await PermissionService().hasCameraPermission();
    await PermissionService().hasMicrophonePermission();
    
    setState(() => _isLoading = false);
  }

  Future<void> _requestPermissions() async {
    final cameraGranted = await PermissionService().requestCameraPermission();
    await PermissionService().requestMicrophonePermission();
    
    setState(() {
      _hasCameraPermission = cameraGranted;
    });
    
    // Process mic permission result if needed elsewhere or just let it be
    if (cameraGranted) {
      _initializeServices();
    }
  }

  Future<void> _initializeServices() async {
    final ttsProvider = context.read<TTSProvider>();
    final vibrationProvider = context.read<VibrationProvider>();
    final voiceCommandProvider = context.read<VoiceCommandProvider>();
    
    await ttsProvider.initialize();
    await vibrationProvider.initialize();
    await voiceCommandProvider.initialize();
    
    // Announce app is ready
    if (context.read<AccessibilityProvider>().isVoiceGuidanceEnabled) {
      ttsProvider.speak('AI Vision Pro ready. Tap start to begin scanning.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'AI Vision Pro',
          child: const Text('AI VISION PRO'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasCameraPermission
              ? _buildPermissionRequired()
              : _buildMainContent(accessibilityProvider),
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Camera permission required. Tap button to grant permission.',
              child: const Icon(
                Icons.no_photography,
                size: 80,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera permission is required for this app to work.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Grant Camera Permission'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AccessibilityProvider accessibilityProvider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message with glassmorphism
            Semantics(
              label: 'Welcome to AI Vision Pro. This app helps you detect objects using your camera.',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withValues(alpha: 0.3),
                      Colors.purple.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.blue, Colors.lightBlueAccent, Colors.white],
                      ).createShader(bounds),
                      child: Text(
                        'AI VISION PRO',
                        style: TextStyle(
                          fontSize: 32 * accessibilityProvider.textScaleFactor,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI-powered Visual Companion',
                      style: TextStyle(
                        fontSize: 16 * accessibilityProvider.textScaleFactor,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Main action buttons
            _buildLargeButton(
              icon: Icons.play_arrow,
              label: 'Start Scanning',
              semanticsLabel: 'Start scanning for objects. Double tap to begin.',
              onPressed: () => _startScanning(),
              color: Colors.green,
            ),
            
            const SizedBox(height: 16),
            
            _buildLargeButton(
              icon: Icons.text_fields,
              label: 'Read Text',
              semanticsLabel: 'Read text from camera. Double tap to enable OCR mode.',
              onPressed: () => _toggleOcr(),
              color: Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            _buildLargeButton(
              icon: Icons.mic,
              label: 'Voice Commands',
              semanticsLabel: 'Enable voice commands. Double tap to start listening.',
              onPressed: () => _startVoiceCommands(),
              color: Colors.purple,
            ),
            
            const SizedBox(height: 16),
            
            // Emergency button
            _buildEmergencyButton(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton({
    required IconData icon,
    required String label,
    required String semanticsLabel,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 36),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 20 * accessibilityProvider.textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Semantics(
      label: 'Emergency alert button. Long press to activate emergency alert.',
      button: true,
      child: GestureDetector(
        onLongPress: _triggerEmergency,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 36, color: Colors.white),
              const SizedBox(width: 16),
              Text(
                'EMERGENCY ALERT',
                style: TextStyle(
                  fontSize: 22 * accessibilityProvider.textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startScanning() async {
    final vibrationProvider = context.read<VibrationProvider>();
    vibrationProvider.vibrateForButtonPress();
    
    final cameraProvider = context.read<CameraProvider>();
    final detectionProvider = context.read<DetectionProvider>();
    final ttsProvider = context.read<TTSProvider>();
    
    // Initialize camera if needed
    if (!cameraProvider.isInitialized) {
      await cameraProvider.initializeCamera();
    }
    
    // Set up detection callback
    detectionProvider.onSpeakText = (text) {
      ttsProvider.speak(text, interrupt: false);
    };
    
    // Connect camera stream to detection
    cameraProvider.onImageAvailable = (image) {
      detectionProvider.processImage(image);
    };
    
    // Start camera stream
    await cameraProvider.startStream();
    
    // Navigate to camera preview
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraPreviewScreen()),
      );
    }
  }

  Future<void> _toggleOcr() async {
    final vibrationProvider = context.read<VibrationProvider>();
    vibrationProvider.vibrateForButtonPress();
    
    final detectionProvider = context.read<DetectionProvider>();
    final ttsProvider = context.read<TTSProvider>();
    
    detectionProvider.toggleOcr();
    
    if (detectionProvider.isOcrEnabled) {
      ttsProvider.speak('Text reading enabled. Point camera at text.');
    } else {
      ttsProvider.speak('Text reading disabled.');
    }
  }

  Future<void> _startVoiceCommands() async {
    final vibrationProvider = context.read<VibrationProvider>();
    vibrationProvider.vibrateForButtonPress();
    
    final voiceCommandProvider = context.read<VoiceCommandProvider>();
    final ttsProvider = context.read<TTSProvider>();
    
    if (!voiceCommandProvider.isInitialized) {
      await voiceCommandProvider.initialize();
    }
    
    await voiceCommandProvider.startListening();
    
    ttsProvider.speak('Listening for commands. Say: start scanning, stop, read text, or what is around me.');
  }

  Future<void> _triggerEmergency() async {
    final vibrationProvider = context.read<VibrationProvider>();
    final ttsProvider = context.read<TTSProvider>();
    
    vibrationProvider.vibrateForEmergency();
    ttsProvider.speak('Emergency alert activated. Help is on the way.');
    
    // Show emergency dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('EMERGENCY ALERT'),
          content: const Text(
            'Emergency alert has been activated. Vibrating and announcing location.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                vibrationProvider.stopVibration();
                ttsProvider.stop();
                Navigator.pop(context);
              },
              child: const Text('DEACTIVATE'),
            ),
          ],
        ),
      );
    }
  }
}
