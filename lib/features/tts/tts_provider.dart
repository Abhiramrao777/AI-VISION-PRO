import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSProvider extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String? _error;

  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  bool get hasError => _error != null;
  String? get error => _error;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  Future<void> initialize() async {
    try {
      _error = null;

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

  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized || text.trim().isEmpty) return;

    try {
      if (interrupt && _isSpeaking) await stop();
      await _flutterTts.speak(text);
    } catch (e) {
      _error = 'Speak error: $e';
      notifyListeners();
    }
  }

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

  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
      notifyListeners();
    } catch (e) {
      _error = 'Set language error: $e';
      notifyListeners();
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      return await _flutterTts.getLanguages.then((langs) => langs.cast<String>().toList());
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
