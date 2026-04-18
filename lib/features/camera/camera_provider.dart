import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isStreaming = false;
  String? _error;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;

  Function(CameraImage)? onImageAvailable;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;
  bool get hasError => _error != null;
  String? get error => _error;
  List<CameraDescription>? get cameras => _availableCameras;
  int get selectedCameraIndex => _selectedCameraIndex;

  Future<void> initializeCamera() async {
    try {
      _error = null;
      notifyListeners();

      _availableCameras = await availableCameras();

      if (_availableCameras == null || _availableCameras!.isEmpty) {
        _error = 'No cameras available on this device';
        notifyListeners();
        return;
      }

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

  Future<void> _initializeCameraController(int cameraIndex) async {
    try {
      await disposeController();

      if (_availableCameras == null || _availableCameras!.isEmpty) return;
      final camera = _availableCameras![cameraIndex];

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
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

  Future<void> switchCamera() async {
    if (_availableCameras == null || _availableCameras!.length <= 1) return;
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras!.length;
    await _initializeCameraController(_selectedCameraIndex);
  }

  Future<void> toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final currentMode = _controller!.value.flashMode;
        FlashMode newMode;

        switch (currentMode) {
          case FlashMode.off:
            newMode =
                FlashMode.torch; // Use torch for solid light instead of always
            break;
          case FlashMode.torch:
            newMode = FlashMode.auto;
            break;
          case FlashMode.auto:
            newMode = FlashMode.off;
            break;
          default:
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
