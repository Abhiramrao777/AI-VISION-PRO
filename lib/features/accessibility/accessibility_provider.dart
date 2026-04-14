import 'package:flutter/foundation.dart';

/// Provider for accessibility settings
class AccessibilityProvider extends ChangeNotifier {
  bool _isHighContrastMode = false;
  bool _isLargeTextMode = false;
  double _textScaleFactor = 1.0;
  bool _isVoiceGuidanceEnabled = true;
  bool _isHapticFeedbackEnabled = true;
  
  // Getters
  bool get isHighContrastMode => _isHighContrastMode;
  bool get isLargeTextMode => _isLargeTextMode;
  double get textScaleFactor => _textScaleFactor;
  bool get isVoiceGuidanceEnabled => _isVoiceGuidanceEnabled;
  bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;

  /// Toggle high contrast mode
  void toggleHighContrast() {
    _isHighContrastMode = !_isHighContrastMode;
    notifyListeners();
  }

  /// Toggle large text mode
  void toggleLargeText() {
    _isLargeTextMode = !_isLargeTextMode;
    _textScaleFactor = _isLargeTextMode ? 1.5 : 1.0;
    notifyListeners();
  }

  /// Set text scale factor
  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    notifyListeners();
  }

  /// Toggle voice guidance
  void toggleVoiceGuidance() {
    _isVoiceGuidanceEnabled = !_isVoiceGuidanceEnabled;
    notifyListeners();
  }

  /// Toggle haptic feedback
  void toggleHapticFeedback() {
    _isHapticFeedbackEnabled = !_isHapticFeedbackEnabled;
    notifyListeners();
  }

  /// Enable accessibility mode (all features on)
  void enableAccessibilityMode() {
    _isHighContrastMode = true;
    _isLargeTextMode = true;
    _textScaleFactor = 1.5;
    _isVoiceGuidanceEnabled = true;
    _isHapticFeedbackEnabled = true;
    notifyListeners();
  }

  /// Disable accessibility mode
  void disableAccessibilityMode() {
    _isHighContrastMode = false;
    _isLargeTextMode = false;
    _textScaleFactor = 1.0;
    notifyListeners();
  }

  /// Reset to default settings
  void resetToDefaults() {
    _isHighContrastMode = false;
    _isLargeTextMode = false;
    _textScaleFactor = 1.0;
    _isVoiceGuidanceEnabled = true;
    _isHapticFeedbackEnabled = true;
    notifyListeners();
  }
}
