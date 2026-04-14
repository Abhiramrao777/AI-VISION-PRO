import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ai_vision_pro/features/ai/nvidia_ai_service.dart';
import 'dart:async';

class AppDetectedObject {
  final String label;
  final double confidence;
  final Rect? boundingBox;
  final DateTime detectedAt;
  final DistanceLevel distanceLevel;
  final String spatialLocation;

  AppDetectedObject({
    required this.label,
    required this.confidence,
    this.boundingBox,
    required this.detectedAt,
    required this.distanceLevel,
    this.spatialLocation = 'center',
  });

  String get distanceDescription {
    switch (distanceLevel) {
      case DistanceLevel.close: return 'close';
      case DistanceLevel.medium: return 'at medium distance';
      case DistanceLevel.far: return 'far away';
    }
  }
}

enum DistanceLevel { close, medium, far }
enum ObstaclePriority { critical, high, medium, low }

class DetectionProvider extends ChangeNotifier {
  // ── ML Kit Object Detector ──
  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true, 
      multipleObjects: true,
    ),
  );

  // ── ML Kit Image Labeler (400+ labels — the core of the concept) ──
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.60), // 60% threshold per methodology
  );

  final TextRecognizer _textRecognizer = TextRecognizer();
  
  bool _isProcessing = false;
  bool _isDetectionEnabled = true;
  bool _isOcrEnabled = false;
  String? _error;
  
  final Map<String, DateTime> _lastAnnouncedObjects = {};
  final Set<String> _recentlyAnnouncedObjects = {};
  
  static const Duration _processingInterval = Duration(milliseconds: 500);
  DateTime? _lastProcessingTime;
  
  List<AppDetectedObject> _currentDetections = [];
  List<AppDetectedObject> _ocrResults = [];

  /// Store last camera image dimensions for bounding box scaling
  int _lastImageWidth = 0;
  int _lastImageHeight = 0;
  
  Function(List<AppDetectedObject>)? onNewDetection;
  Function(String)? onSpeakText;

  final OnDeviceAIService _onDeviceAI = OnDeviceAIService();
  
  static const List<String> _priorityObjects = [
    'person', 'people', 'human',
    'vehicle', 'car', 'truck', 'bus', 'motorcycle', 'bicycle',
    'door', 'gate', 'entrance',
    'stairs', 'step', 'ladder',
    'chair', 'table', 'desk', 'computer', 'pc', 'monitor'
  ];

  bool get isProcessing => _isProcessing;
  bool get isDetectionEnabled => _isDetectionEnabled;
  bool get isOcrEnabled => _isOcrEnabled;
  bool get hasError => _error != null;
  String? get error => _error;
  List<AppDetectedObject> get currentDetections => _currentDetections;
  List<AppDetectedObject> get ocrResults => _ocrResults;
  int get lastImageWidth => _lastImageWidth;
  int get lastImageHeight => _lastImageHeight;

  Future<void> processImage(CameraImage image) async {
    if (!_isDetectionEnabled || _isProcessing) return;
    
    final now = DateTime.now();
    if (_lastProcessingTime != null) {
      final elapsed = now.difference(_lastProcessingTime!);
      if (elapsed < _processingInterval) return;
    }
    _lastProcessingTime = now;
    
    try {
      _isProcessing = true;

      // Store image dimensions for bounding box scaling on the UI side
      _lastImageWidth = image.width;
      _lastImageHeight = image.height;
      
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }
      
      final List<AppDetectedObject> newDetections = <AppDetectedObject>[];
      
      // ── 1. ML Kit Object Detection (provides bounding boxes + spatial info) ──
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);
      
      for (final DetectedObject obj in objects) {
        final spatialLoc = _getSpatialLocation(obj.boundingBox, image.width.toDouble());
        final distanceLevel = _estimateDistance(obj.boundingBox);
        
        String accurateLabel = 'object';
        double confidence = 0.45;

        if (obj.labels.isNotEmpty) {
          final sortedLabels = List.of(obj.labels)
            ..sort((a, b) => b.confidence.compareTo(a.confidence));
          accurateLabel = sortedLabels.first.text;
          confidence = sortedLabels.first.confidence;
        }

        // Accept detections at 60%+ confidence (per documented methodology)
        if (confidence >= 0.60) {
          newDetections.add(AppDetectedObject(
            label: accurateLabel,
            confidence: confidence,
            boundingBox: obj.boundingBox,
            detectedAt: DateTime.now(),
            distanceLevel: distanceLevel,
            spatialLocation: spatialLoc,
          ));
        } else if (confidence <= 0.0 && accurateLabel == 'object') {
          // Unlabeled but spatially detected — report as obstacle
          newDetections.add(AppDetectedObject(
            label: 'obstacle',
            confidence: 0.45,
            boundingBox: obj.boundingBox,
            detectedAt: DateTime.now(),
            distanceLevel: distanceLevel,
            spatialLocation: spatialLoc,
          ));
        }
      }

      // ── 2. ML Kit Image Labeling (provides 400+ rich labels) ──
      // Image Labeling has no bounding boxes, but provides much richer labels
      // like "laptop", "coffee cup", "book", "headphones" — the core feature.
      try {
        final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);
        
        // Build a set of already-detected labels from Object Detection to avoid duplicates
        final existingLabels = newDetections.map((d) => d.label.toLowerCase()).toSet();
        
        for (final ImageLabel label in labels) {
          if (label.confidence < 0.60) continue; // Confidence threshold per methodology
          
          // Skip if object detection already found this label
          if (existingLabels.contains(label.label.toLowerCase())) continue;
          
          newDetections.add(AppDetectedObject(
            label: label.label,
            confidence: label.confidence,
            boundingBox: null, // Image labeling doesn't provide bounding boxes
            detectedAt: DateTime.now(),
            distanceLevel: DistanceLevel.medium, // Default — no spatial info available
            spatialLocation: 'in the scene',
          ));
        }
      } catch (e) {
        debugPrint('Image labeling error: $e');
      }
      
      _currentDetections = newDetections;
      if (onNewDetection != null) onNewDetection!(newDetections); // fires vibration
      await _handleSmartAnnouncement(newDetections);
      
      if (_isOcrEnabled) {
        await _processOcr(inputImage);
      }
    } catch (e) {
      _error = 'Detection error: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String _getSpatialLocation(Rect boundingBox, double imageWidth) {
    final centerX = boundingBox.center.dx;
    final third = imageWidth / 3;
    if (centerX < third) return 'on your left';
    else if (centerX < 2 * third) return 'in front of you';
    else return 'on your right';
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final imageRotation = InputImageRotationValue.fromRawValue(0) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      debugPrint('Error converting image: $e');
    }
    return null;
  }

  Future<void> _processOcr(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      _ocrResults.clear();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            _ocrResults.add(AppDetectedObject(
              label: line.text.trim(),
              confidence: 1.0,
              boundingBox: line.boundingBox,
              detectedAt: DateTime.now(),
              distanceLevel: DistanceLevel.medium,
            ));
          }
        }
      }
      if (_ocrResults.isNotEmpty && onSpeakText != null) {
        final textToRead = _ocrResults.map((r) => r.label).join('. ');
        onSpeakText!('Text detected: $textToRead');
      }
    } catch (e) {
      debugPrint('OCR error: $e');
    }
  }

  DistanceLevel _estimateDistance(Rect? boundingBox) {
    if (boundingBox == null) return DistanceLevel.medium;
    final area = boundingBox.width * boundingBox.height;
    if (area > 100000) return DistanceLevel.close;
    else if (area > 30000) return DistanceLevel.medium;
    else return DistanceLevel.far;
  }

  Future<void> _handleSmartAnnouncement(List<AppDetectedObject> detections) async {
    if (onSpeakText == null || detections.isEmpty) return;
    
    final priorityDetections = <AppDetectedObject>[];
    final regularDetections = <AppDetectedObject>[];
    
    for (final detection in detections) {
      if (_isPriorityObject(detection.label)) priorityDetections.add(detection);
      else regularDetections.add(detection);
    }
    
    priorityDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
    regularDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    for (final detection in priorityDetections.take(2)) {
      if (_shouldAnnounce(detection.label)) {
        await _announceObject(detection);
        return;
      }
    }
    
    if (priorityDetections.isEmpty) {
      for (final detection in regularDetections.take(1)) {
        if (_shouldAnnounce(detection.label)) {
          await _announceObject(detection);
          return;
        }
      }
    }
  }

  bool _shouldAnnounce(String label) {
    final now = DateTime.now();
    if (_recentlyAnnouncedObjects.contains(label)) return false;
    final lastAnnounced = _lastAnnouncedObjects[label];
    if (lastAnnounced != null) {
      final elapsed = now.difference(lastAnnounced);
      final minInterval = _isPriorityObject(label) ? const Duration(seconds: 3) : const Duration(seconds: 5);
      if (elapsed < minInterval) return false;
    }
    return true;
  }

  /// Announce detected object with its label, position, and distance
  Future<void> _announceObject(AppDetectedObject detection) async {
    final now = DateTime.now();
    _lastAnnouncedObjects[detection.label] = now;
    _recentlyAnnouncedObjects.add(detection.label);
    
    Future.delayed(const Duration(seconds: 5), () {
      _recentlyAnnouncedObjects.remove(detection.label);
    });
    
    final message = '${detection.label} ${detection.spatialLocation}, ${detection.distanceDescription}';
    if (onSpeakText != null) onSpeakText!(message);
  }

  bool _isPriorityObject(String label) {
    final lowerLabel = label.toLowerCase();
    return _priorityObjects.any((priority) => lowerLabel.contains(priority));
  }

  ObstaclePriority getObstaclePriority(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('person') || lowerLabel.contains('vehicle') || lowerLabel.contains('car')) return ObstaclePriority.critical;
    if (lowerLabel.contains('door') || lowerLabel.contains('stairs')) return ObstaclePriority.high;
    if (lowerLabel.contains('chair') || lowerLabel.contains('table') || lowerLabel.contains('pc') || lowerLabel.contains('computer')) return ObstaclePriority.medium;
    return ObstaclePriority.low;
  }

  void toggleDetection() {
    _isDetectionEnabled = !_isDetectionEnabled;
    notifyListeners();
  }

  void toggleOcr() {
    _isOcrEnabled = !_isOcrEnabled;
    notifyListeners();
  }

  void clearRecentAnnouncements() {
    _recentlyAnnouncedObjects.clear();
    _lastAnnouncedObjects.clear();
  }

  /// Describe surroundings using on-device detections only (no cloud API)
  Future<void> describeSurroundings() async {
    clearRecentAnnouncements();

    if (_currentDetections.isEmpty) {
      if (onSpeakText != null) onSpeakText!('No objects detected currently');
      return;
    }

    final labels = _currentDetections.map((d) => d.label).toList();
    final description = _onDeviceAI.describeScene(labels);
    if (onSpeakText != null) onSpeakText!(description);
  }

  @override
  void dispose() {
    _objectDetector.close();
    _imageLabeler.close();
    _textRecognizer.close();
    super.dispose();
  }
}