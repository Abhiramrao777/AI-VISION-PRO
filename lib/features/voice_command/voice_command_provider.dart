import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice command types
enum VoiceCommand {
  startScanning,
  stopScanning,
  readText,
  describeSurroundings,
  emergency,
  unknown,
}

/// Provider for voice command recognition
class VoiceCommandProvider extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isEnabled = true;
  String? _error;
  String _lastHeard = '';
  VoiceCommand _lastCommand = VoiceCommand.unknown;
  
  // Callback for voice commands
  Function(VoiceCommand)? onVoiceCommand;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  bool get hasError => _error != null;
  String? get error => _error;
  String get lastHeard => _lastHeard;
  VoiceCommand get lastCommand => _lastCommand;

  /// Initialize speech recognition
  Future<void> initialize() async {
    try {
      _error = null;
      
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _error = 'Speech recognition error: $error';
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          } else if (status == 'listening') {
            _isListening = true;
            notifyListeners();
          }
        },
      );
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize speech recognition: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isEnabled || !_isInitialized) return;
    
    try {
      final available = await _speechToText.listen(
        onResult: (result) {
          _lastHeard = result.recognizedWords.toLowerCase();
          _parseVoiceCommand(_lastHeard);
          notifyListeners();
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 3),
      );
      
      if (!available) {
        _error = 'Speech recognition not available';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to start listening: $e';
      notifyListeners();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to stop listening: $e';
      notifyListeners();
    }
  }

  /// Parse voice command from text
  void _parseVoiceCommand(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('start') && 
        (lowerText.contains('scan') || lowerText.contains('detect'))) {
      _lastCommand = VoiceCommand.startScanning;
      _triggerCommand(VoiceCommand.startScanning);
    } else if (lowerText.contains('stop') || 
               lowerText.contains('pause') ||
               lowerText.contains('halt')) {
      _lastCommand = VoiceCommand.stopScanning;
      _triggerCommand(VoiceCommand.stopScanning);
    } else if (lowerText.contains('read') && 
               (lowerText.contains('text') || lowerText.contains('sign'))) {
      _lastCommand = VoiceCommand.readText;
      _triggerCommand(VoiceCommand.readText);
    } else if (lowerText.contains('what') && 
               (lowerText.contains('around') || lowerText.contains('see'))) {
      _lastCommand = VoiceCommand.describeSurroundings;
      _triggerCommand(VoiceCommand.describeSurroundings);
    } else if (lowerText.contains('emergency') || 
               lowerText.contains('help') ||
               lowerText.contains('alert')) {
      _lastCommand = VoiceCommand.emergency;
      _triggerCommand(VoiceCommand.emergency);
    }
  }

  /// Trigger voice command callback
  void _triggerCommand(VoiceCommand command) {
    if (onVoiceCommand != null) {
      onVoiceCommand!(command);
    }
  }

  /// Toggle voice commands
  void toggleVoiceCommands() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stopListening();
    }
    notifyListeners();
  }

  /// Check if microphone permission is needed
  Future<bool> checkMicrophonePermission() async {
    try {
      // Re-initialize to check/request permission
      final initialized = await _speechToText.initialize();
      return initialized;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear last heard text
  void clearLastHeard() {
    _lastHeard = '';
    _lastCommand = VoiceCommand.unknown;
    notifyListeners();
  }
}
