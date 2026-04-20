import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:ai_vision_pro/features/detection/detection_provider.dart';

class VibrationProvider extends ChangeNotifier {
  bool _isVibrationEnabled = true;
  bool _hasVibrator = false;
  bool _hasCustomVibrations = false;
  String? _error;

  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get hasVibrator => _hasVibrator;
  bool get hasError => _error != null;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() == true;
      if (_hasVibrator) {
        _hasCustomVibrations =
            await Vibration.hasCustomVibrationsSupport() == true;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize vibration: $e';
      _hasVibrator = false;
      notifyListeners();
    }
  }

  Future<void> vibrateForObject(
      {bool isPriority = false,
      String spatialLocation = 'center',
      DistanceLevel distanceLevel = DistanceLevel.medium}) async {
    if (!_isVibrationEnabled || !_hasVibrator) return;

    try {
      await Vibration.cancel();

      if (_hasCustomVibrations) {
        if (distanceLevel == DistanceLevel.close) {
          await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 150]);
        } else if (distanceLevel == DistanceLevel.medium) {
          await Vibration.vibrate(pattern: [0, 250, 100, 250]);
        } else {
          await Vibration.vibrate(duration: 80);
        }
      } else {
        if (distanceLevel == DistanceLevel.close) {
          await Vibration.vibrate(duration: 500);
        } else if (distanceLevel == DistanceLevel.medium) {
          await Vibration.vibrate(duration: 200);
        } else {
          await Vibration.vibrate(duration: 50);
        }
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

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

  Future<void> vibrateForWarning() async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    try {
      if (_hasCustomVibrations) {
        await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
      } else {
        await Vibration.vibrate(duration: 800);
      }
    } catch (e) {
      debugPrint('Warning vibration error: $e');
    }
  }

  Future<void> vibrateForButtonPress() async {
    if (!_isVibrationEnabled || !_hasVibrator) return;
    try {
      await Vibration.vibrate(duration: 40);
    } catch (e) {
      debugPrint('Button vibration error: $e');
    }
  }

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
