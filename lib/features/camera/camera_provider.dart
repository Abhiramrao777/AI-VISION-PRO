import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// Provider for camera functionality
class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isStreaming = false;
  String? _error;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;
  
  // Callback for image processing
  Function(CameraImage)? onImageAvailable;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;
  bool get hasError => _error != null;
  String? get error => _error;
  List<CameraDescription>? get cameras => _availableCameras;
  int get selectedCameraIndex => _selectedCameraIndex;

  /// Initialize camera
  Future<void> initializeCamera() async {
    try {
      _error = null;
      notifyListeners();

      // Explicitly call the top-level function from the camera package
      // to avoid any shadowing with getters
      _availableCameras = await availableCameras();
      
      if (_availableCameras == null || _availableCameras!.isEmpty) {
        _error = 'No cameras available on this device';
        notifyListeners();
        return;
      }

      // Select back camera by default (index 0 is usually back camera)
      _selectedCameraIndex = 0;
      for (int i = 0; i < _availableCameras!.length; i++) {
        if (_availableCameras![i].lensDirection == CameraLensDirection.back) {
          _selectedCameraIndex = i;
          break;
        }
      }

      await _initializeCameraController(_selectedCameraIndex);
    } catch (e) {
      _error = 'Failed to initialize camera: $e';
      notifyListeners();
    }
  }

  /// Initialize camera controller with specific camera
  Future<void> _initializeCameraController(int cameraIndex) async {
    try {
      // Dispose existing controller
      await disposeController();

      if (_availableCameras == null || _availableCameras!.isEmpty) return;
      final camera = _availableCameras![cameraIndex];
      
      // Use lower resolution for better performance
      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // 720p - good balance between quality and performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Required for ML Kit
      );

      await _controller!.initialize();
      
      if (!_controller!.value.isInitialized) {
        _error = 'Camera failed to initialize';
        notifyListeners();
        return;
      }

      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Camera initialization error: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Start camera stream
  Future<void> startStream() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.startImageStream((CameraImage image) {
          if (_isStreaming) {
            onImageAvailable?.call(image);
          }
        });
        _isStreaming = true;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to start stream: $e';
        notifyListeners();
      }
    }
  }

  /// Stop camera stream
  Future<void> stopStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
        _isStreaming = false;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to stop stream: $e';
        notifyListeners();
      }
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_availableCameras == null || _availableCameras!.length <= 1) {
      return;
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras!.length;
    await _initializeCameraController(_selectedCameraIndex);
  }

  /// Toggle flash
  Future<void> toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final currentMode = _controller!.value.flashMode;
        FlashMode newMode;
        
        switch (currentMode) {
          case FlashMode.off:
            newMode = FlashMode.always;
            break;
          case FlashMode.always:
            newMode = FlashMode.auto;
            break;
          case FlashMode.auto:
            newMode = FlashMode.torch;
            break;
          case FlashMode.torch:
            newMode = FlashMode.off;
            break;
        }
        
        await _controller!.setFlashMode(newMode);
        notifyListeners();
      } catch (e) {
        _error = 'Failed to toggle flash: $e';
        notifyListeners();
      }
    }
  }

  /// Dispose camera controller
  Future<void> disposeController() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      }
      _controller = null;
      _isInitialized = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
