import 'package:flutter/foundation.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _isHighContrastMode = false;
  bool _isLargeTextMode = false;
  double _textScaleFactor = 1.0;
  bool _isVoiceGuidanceEnabled = true;
  bool _isHapticFeedbackEnabled = true;
  
  bool get isHighContrastMode => _isHighContrastMode;
  bool get isLargeTextMode => _isLargeTextMode;
  double get textScaleFactor => _textScaleFactor;
  bool get isVoiceGuidanceEnabled => _isVoiceGuidanceEnabled;
  bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;

  void toggleHighContrast() {
    _isHighContrastMode = !_isHighContrastMode;
    notifyListeners();
  }

  void toggleLargeText() {
    _isLargeTextMode = !_isLargeTextMode;
    _textScaleFactor = _isLargeTextMode ? 1.5 : 1.0;
    notifyListeners();
  }

  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    notifyListeners();
  }

  void toggleVoiceGuidance() {
    _isVoiceGuidanceEnabled = !_isVoiceGuidanceEnabled;
    notifyListeners();
  }

  void toggleHapticFeedback() {
    _isHapticFeedbackEnabled = !_isHapticFeedbackEnabled;
    notifyListeners();
  }

  void enableAccessibilityMode() {
    _isHighContrastMode = true;
    _isLargeTextMode = true;
    _textScaleFactor = 1.5;
    _isVoiceGuidanceEnabled = true;
    _isHapticFeedbackEnabled = true;
    notifyListeners();
  }

  void disableAccessibilityMode() {
    _isHighContrastMode = false;
    _isLargeTextMode = false;
    _textScaleFactor = 1.0;
    notifyListeners();
  }

  void resetToDefaults() {
    _isHighContrastMode = false;
    _isLargeTextMode = false;
    _textScaleFactor = 1.0;
    _isVoiceGuidanceEnabled = true;
    _isHapticFeedbackEnabled = true;
    notifyListeners();
  }
}
