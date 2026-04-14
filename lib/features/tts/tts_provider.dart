import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Provider for Text-to-Speech functionality
class TTSProvider extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String? _error;
  
  // TTS settings
  double _speechRate = 0.5; // Slower rate for better comprehension
  double _pitch = 1.0;
  double _volume = 1.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  bool get hasError => _error != null;
  String? get error => _error;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  /// Initialize TTS
  Future<void> initialize() async {
    try {
      _error = null;
      
      // Set up TTS listeners
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        notifyListeners();
      });
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        notifyListeners();
      });
      
      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        notifyListeners();
      });
      
      _flutterTts.setErrorHandler((message) {
        _error = 'TTS Error: $message';
        _isSpeaking = false;
        notifyListeners();
      });
      
      // Configure TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize TTS: $e';
      notifyListeners();
    }
  }

  /// Speak text
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized || text.trim().isEmpty) return;
    
    try {
      // Stop current speech if interrupt is true
      if (interrupt && _isSpeaking) {
        await stop();
      }
      
      await _flutterTts.speak(text);
    } catch (e) {
      _error = 'Speak error: $e';
      notifyListeners();
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      _error = 'Stop error: $e';
      notifyListeners();
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      _error = 'Pause error: $e';
      notifyListeners();
    }
  }

  /// Resume speaking (Note: resume may not be supported on all versions of flutter_tts)
  Future<void> resume() async {
    // Current version of flutter_tts may not support resume directly.
    // In many cases, you just call speak() again.
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      notifyListeners();
    } catch (e) {
      _error = 'Set speech rate error: $e';
      notifyListeners();
    }
  }

  /// Set pitch (0.0 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.0, 2.0);
      await _flutterTts.setPitch(_pitch);
      notifyListeners();
    } catch (e) {
      _error = 'Set pitch error: $e';
      notifyListeners();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      _error = 'Set volume error: $e';
      notifyListeners();
    }
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
      notifyListeners();
    } catch (e) {
      _error = 'Set language error: $e';
      notifyListeners();
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      return await _flutterTts.getLanguages.then((langs) => langs.toList());
    } catch (e) {
      _error = 'Get languages error: $e';
      return [];
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
