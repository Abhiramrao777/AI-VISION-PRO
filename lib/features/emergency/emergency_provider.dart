import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:camera/camera.dart';
import 'package:ai_vision_pro/features/camera/camera_provider.dart';

/// Provider for a genuine, functional Emergency SOS system.
class EmergencyProvider extends ChangeNotifier {
  bool _isEmergencyActive = false;
  Timer? _sosTimer;
  final FlutterTts _tts = FlutterTts();

  bool get isEmergencyActive => _isEmergencyActive;

  Future<void> toggleEmergency(CameraProvider cameraProvider) async {
    if (_isEmergencyActive) {
      _stopEmergency(cameraProvider);
    } else {
      _startEmergency(cameraProvider);
    }
  }

  void _startEmergency(CameraProvider cameraProvider) async {
    _isEmergencyActive = true;
    notifyListeners();

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.5);

    int cycle = 0;

    _sosTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (cameraProvider.controller?.value.isInitialized ?? false) {
        try {
          await cameraProvider.controller!
              .setFlashMode(cycle % 2 == 0 ? FlashMode.torch : FlashMode.off);
        } catch (e) {
          debugPrint('Flash error during SOS: $e');
        }
      }

      // Null-aware warning fixed here.
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 400);
      }

      if (cycle % 4 == 0) {
        await _tts.speak("Emergency! I need help immediately!");
      }

      cycle++;
    });
  }

  void _stopEmergency(CameraProvider cameraProvider) {
    _isEmergencyActive = false;
    _sosTimer?.cancel();
    _sosTimer = null;

    Vibration.cancel();
    _tts.stop();

    if (cameraProvider.controller?.value.isInitialized ?? false) {
      try {
        cameraProvider.controller!.setFlashMode(FlashMode.off);
      } catch (e) {
        debugPrint('Flash error stopping SOS: $e');
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _tts.stop();
    Vibration.cancel();
    super.dispose();
  }
}
