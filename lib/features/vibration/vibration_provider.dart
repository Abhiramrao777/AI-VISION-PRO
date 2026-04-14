import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Provider for haptic feedback
class VibrationProvider extends ChangeNotifier {
  bool _isVibrationEnabled = true;
  bool _hasVibrator = false;
  bool _hasCustomVibrations = false;
  bool _hasAmplitudeControl = false;
  String? _error;

  // Getters
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get hasVibrator => _hasVibrator;
  bool get hasError => _error != null;
  String? get error => _error;

  /// Initialize vibration service
  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
      if (_hasVibrator) {
        _hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();
        _hasAmplitudeControl = await Vibration.hasAmplitudeControl();
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize vibration: $e';
      _hasVibrator = false;
      notifyListeners();
    }
  }

  /// Vibrate with pattern for object detection including spatial awareness
  Future<void> vibrateForObject({bool isPriority = false, String spatialLocation = 'center', double? area}) async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    
    try {
      if (area != null) {
        // Distance-based vibration mapping
        if (area > 100000) {
          // Extremely close: Continuous pulse
          await Vibration.cancel();
          if (_hasCustomVibrations && _hasAmplitudeControl) {
            await Vibration.vibrate(pattern: [0, 500, 50, 500], intensities: [0, 255, 0, 255]);
          } else {
            await Vibration.vibrate(duration: 1000); // Standard fallback
          }
          Future.delayed(const Duration(milliseconds: 1000), () => Vibration.cancel());
        } else if (area > 30000) {
          // Medium distance: Steady double pulse
          if (_hasCustomVibrations) {
            await Vibration.vibrate(pattern: [0, 150, 100, 150]);
          } else {
            await Vibration.vibrate(duration: 300);
          }
        } else {
          // Far: Light single tap
          await Vibration.vibrate(duration: 50);
        }
        return;
      }

      // Fallback to priority/location based logic if area is not provided
      if (isPriority) {
        if (spatialLocation.contains('left') && _hasCustomVibrations) {
          await Vibration.vibrate(pattern: [0, 100, 50, 100]);
        } else if (spatialLocation.contains('right') && _hasCustomVibrations) {
          await Vibration.vibrate(pattern: [0, 50, 50, 200]);
        } else {
          await Vibration.vibrate(duration: 200);
        }
      } else {
        await Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  /// Vibrate for a clear path (positive feedback)
  Future<void> vibrateForClearPath() async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    try {
      if (_hasCustomVibrations) {
        await Vibration.vibrate(pattern: [0, 50, 50, 50]);
      } else {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Clear path vibration error: $e');
    }
  }

  /// Vibrate for obstacle warning (critical)
  Future<void> vibrateForWarning() async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    try {
      if (_hasCustomVibrations) {
        await Vibration.vibrate(pattern: [0, 200, 100, 200, 200, 200]);
      } else {
        await Vibration.vibrate(duration: 800);
      }
    } catch (e) {
      debugPrint('Warning vibration error: $e');
    }
  }

  /// Vibrate for button press feedback
  Future<void> vibrateForButtonPress() async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    try {
      await Vibration.vibrate(duration: 30);
    } catch (e) {
      debugPrint('Button vibration error: $e');
    }
  }

  /// Vibrate for emergency alert
  Future<void> vibrateForEmergency() async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    try {
      if (_hasCustomVibrations) {
        await Vibration.vibrate(pattern: [0, 500, 200, 500]);
      } else {
        await Vibration.vibrate(duration: 2000);
      }
    } catch (e) {
      debugPrint('Emergency vibration error: $e');
    }
  }

  /// Stop all vibration
  Future<void> stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Stop vibration error: $e');
    }
  }

  void toggleVibration() {
    _isVibrationEnabled = !_isVibrationEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    stopVibration();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}