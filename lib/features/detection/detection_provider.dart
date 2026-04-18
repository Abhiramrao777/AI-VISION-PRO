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
      case DistanceLevel.close:
        return 'very close';
      case DistanceLevel.medium:
        return 'at medium distance';
      case DistanceLevel.far:
        return 'far away';
    }
  }
}

enum DistanceLevel { close, medium, far }

enum ObstaclePriority { critical, high, medium, low }

class DetectionProvider extends ChangeNotifier {
  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.35),
  );

  final TextRecognizer _textRecognizer = TextRecognizer();

  bool _isProcessing = false;
  bool _isDetectionEnabled = true;
  bool _isOcrEnabled = false;
  String? _error;

  final Map<String, DateTime> _lastAnnouncedObjects = {};
  final Set<String> _recentlyAnnouncedObjects = {};

  static const Duration _processingInterval = Duration(milliseconds: 300);
  DateTime? _lastProcessingTime;

  List<AppDetectedObject> _currentDetections = [];
  List<AppDetectedObject> _ocrResults = [];

  int _lastImageWidth = 1;
  int _lastImageHeight = 1;

  Function(List<AppDetectedObject>)? onNewDetection;
  Function(String)? onSpeakText;

  final OnDeviceAIService _onDeviceAI = OnDeviceAIService();

  static const Map<String, String> _labelRefinements = {
    'electronic device': 'Electronic Device',
    'gadget': 'Device',
    'personal computer': 'Computer',
    'desktop computer': 'Desktop PC',
    'computer monitor': 'Monitor',
    'display': 'Screen',
    'screen': 'Screen',
    'computer keyboard': 'Keyboard',
    'peripheral': 'Computer Accessory',
    'netbook': 'Laptop',
    'tablet computer': 'Tablet',
    'tablet': 'Tablet',
    'mobile phone': 'Mobile Phone',
    'smartphone': 'Mobile Phone',
    'telephony': 'Phone',
    'telephone': 'Phone',
    'computer hardware': 'Hardware Component',
    'wire': 'Wire',
    'cable': 'Cable',
    'power cord': 'Power Cable',
    'usb cable': 'USB Cable',
    'charger': 'Charger',
    'laptop': 'Laptop',
    'mouse': 'Computer Mouse',
    'remote control': 'Remote Control',
    'headphones': 'Headphones',
    'speaker': 'Audio Speaker',
    'microphone': 'Microphone',
    'camera': 'Camera',
    'television': 'TV',
    'tv': 'TV',
    'furniture': 'Furniture',
    'table': 'Table',
    'desk': 'Desk',
    'chair': 'Chair',
    'office chair': 'Office Chair',
    'couch': 'Sofa',
    'sofa bed': 'Sofa',
    'bed': 'Bed',
    'shelf': 'Shelf',
    'bookcase': 'Bookshelf',
    'cupboard': 'Cupboard',
    'cabinet': 'Cabinet',
    'drawer': 'Drawer',
    'nightstand': 'Bedside Table',
    'door': 'Door',
    'window': 'Window',
    'stairs': 'Stairs',
    'wall': 'Wall',
    'floor': 'Floor',
    'ceiling': 'Ceiling',
    'lamp': 'Lamp',
    'light': 'Light',
    'curtain': 'Curtain',
    'pillow': 'Pillow',
    'blanket': 'Blanket',
    'carpet': 'Carpet',
    'rug': 'Rug',
    'mirror': 'Mirror',
    'vehicle': 'Vehicle',
    'car': 'Car',
    'automobile': 'Car',
    'truck': 'Truck',
    'bus': 'Bus',
    'motorcycle': 'Motorcycle',
    'bicycle': 'Bicycle',
    'wheel': 'Wheel',
    'tire': 'Tire',
    'train': 'Train',
    'airplane': 'Airplane',
    'boat': 'Boat',
    'person': 'Person',
    'face': 'Face',
    'human body': 'Person',
    'head': 'Person',
    'hand': 'Hand',
    'arm': 'Arm',
    'leg': 'Leg',
    'people': 'People',
    'man': 'Person',
    'woman': 'Person',
    'child': 'Child',
    'girl': 'Girl',
    'boy': 'Boy',
    'clothing': 'Clothing',
    'jacket': 'Jacket',
    'shirt': 'Shirt',
    'jeans': 'Jeans',
    'shoe': 'Shoe',
    'footwear': 'Shoe',
    'sandal': 'Sandal',
    'boot': 'Boot',
    'hat': 'Hat',
    'glasses': 'Glasses',
    'sunglasses': 'Sunglasses',
    'watch': 'Watch',
    'bag': 'Bag',
    'handbag': 'Handbag',
    'backpack': 'Backpack',
    'suitcase': 'Suitcase',
    'wallet': 'Wallet',
    'umbrella': 'Umbrella',
    'food': 'Food',
    'fruit': 'Fruit',
    'vegetable': 'Vegetable',
    'meal': 'Meal',
    'snack': 'Snack',
    'bread': 'Bread',
    'drink': 'Drink',
    'beverage': 'Beverage',
    'coffee': 'Coffee',
    'tea': 'Tea',
    'water bottle': 'Water Bottle',
    'bottle': 'Bottle',
    'cup': 'Cup',
    'mug': 'Mug',
    'glass': 'Glass',
    'plate': 'Plate',
    'bowl': 'Bowl',
    'fork': 'Fork',
    'knife': 'Knife',
    'spoon': 'Spoon',
    'kitchen appliance': 'Kitchen Appliance',
    'refrigerator': 'Refrigerator',
    'microwave oven': 'Microwave',
    'oven': 'Oven',
    'toaster': 'Toaster',
    'sink': 'Sink',
    'stove': 'Stove',
    'pan': 'Frying Pan',
    'plant': 'Plant',
    'potted plant': 'Potted Plant',
    'flower': 'Flower',
    'tree': 'Tree',
    'leaf': 'Leaf',
    'grass': 'Grass',
    'dog': 'Dog',
    'cat': 'Cat',
    'bird': 'Bird',
    'animal': 'Animal',
    'pet': 'Pet',
    'book': 'Book',
    'notebook': 'Notebook',
    'paper': 'Paper',
    'document': 'Document',
    'pen': 'Pen',
    'pencil': 'Pencil',
    'scissors': 'Scissors',
    'box': 'Box',
    'trash can': 'Dustbin',
    'waste container': 'Dustbin',
    'clock': 'Clock',
    'key': 'Key',
    'lock': 'Lock',
    'coin': 'Coin',
    'cash': 'Cash',
    'banknote': 'Currency Note',
    'toy': 'Toy',
    'teddy bear': 'Teddy Bear',
    'sign': 'Sign Board',
    'poster': 'Poster',
  };

  static const Set<String> _suppressedLabels = {
    'rectangle',
    'line',
    'parallel',
    'pattern',
    'symmetry',
    'circle',
    'triangle',
    'material property',
    'colorfulness',
    'tints and shades',
    'electric blue',
    'magenta',
    'event',
    'leisure',
    'fun',
    'happy',
    'cool',
    'comfort',
    'darkness',
    'midnight',
    'space',
    'number',
    'logo',
    'brand',
    'graphics',
    'graphic design',
    'visual arts',
    'illustration',
    'animation',
    'fictional character',
    'science',
    'technology',
    'engineering',
    'machine',
    'service',
    'automotive tire',
    'sky',
    'cloud',
    'horizon',
    'landscape',
    'font',
    'snapshot',
    'photography',
    'stock photography',
    'art',
  };

  static const List<String> _priorityObjects = [
    'person',
    'people',
    'face',
    'child',
    'vehicle',
    'car',
    'truck',
    'bus',
    'motorcycle',
    'bicycle',
    'door',
    'stairs',
    'chair',
    'table',
    'desk',
    'obstacle',
    'wire',
    'cable',
    'knife',
    'scissors',
    'pole',
    'wall'
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

  String _refineLabel(String rawLabel) {
    final lower = rawLabel.toLowerCase().trim();
    if (_suppressedLabels.contains(lower)) return '';
    if (_labelRefinements.containsKey(lower)) return _labelRefinements[lower]!;

    return rawLabel
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  Future<void> processImage(CameraImage image) async {
    if (!_isDetectionEnabled || _isProcessing) return;

    final now = DateTime.now();
    if (_lastProcessingTime != null &&
        now.difference(_lastProcessingTime!) < _processingInterval) return;
    _lastProcessingTime = now;

    try {
      _isProcessing = true;
      _lastImageWidth = image.width > 0 ? image.width : 1;
      _lastImageHeight = image.height > 0 ? image.height : 1;

      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return;

      final results = await Future.wait([
        _objectDetector.processImage(inputImage),
        _imageLabeler.processImage(inputImage),
      ]);

      final List<DetectedObject> objects = results[0] as List<DetectedObject>;
      final List<ImageLabel> imageLabels = results[1] as List<ImageLabel>;

      final List<AppDetectedObject> newDetections = [];
      final Set<String> addedLabels = {};

      for (final ImageLabel label in imageLabels) {
        if (label.confidence < 0.40) continue;
        final refined = _refineLabel(label.label);
        if (refined.isEmpty) continue;

        final lowerRefined = refined.toLowerCase();
        if (addedLabels.contains(lowerRefined)) continue;

        addedLabels.add(lowerRefined);
        newDetections.add(AppDetectedObject(
          label: refined,
          confidence: label.confidence,
          boundingBox: null,
          detectedAt: DateTime.now(),
          distanceLevel: DistanceLevel.medium,
          spatialLocation: 'in the scene',
        ));
      }

      for (final DetectedObject obj in objects) {
        final spatialLoc =
            _getSpatialLocation(obj.boundingBox, _lastImageWidth.toDouble());
        final distanceLevel = _estimateDistance(obj.boundingBox);

        if (obj.labels.isNotEmpty) {
          final bestLabel = (List.of(obj.labels)
                ..sort((a, b) => b.confidence.compareTo(a.confidence)))
              .first;
          if (bestLabel.confidence >= 0.40) {
            final refined = _refineLabel(bestLabel.text);
            if (refined.isEmpty) continue;
            final lowerRefined = refined.toLowerCase();

            final existingIdx = newDetections
                .indexWhere((d) => d.label.toLowerCase() == lowerRefined);
            if (existingIdx >= 0) {
              final existing = newDetections[existingIdx];
              newDetections[existingIdx] = AppDetectedObject(
                label: existing.label,
                confidence: existing.confidence > bestLabel.confidence
                    ? existing.confidence
                    : bestLabel.confidence,
                boundingBox: obj.boundingBox,
                detectedAt: DateTime.now(),
                distanceLevel: distanceLevel,
                spatialLocation: spatialLoc,
              );
            } else if (!addedLabels.contains(lowerRefined)) {
              addedLabels.add(lowerRefined);
              newDetections.add(AppDetectedObject(
                label: refined,
                confidence: bestLabel.confidence,
                boundingBox: obj.boundingBox,
                detectedAt: DateTime.now(),
                distanceLevel: distanceLevel,
                spatialLocation: spatialLoc,
              ));
            }
          }
        } else {
          if (!addedLabels.contains('obstacle')) {
            addedLabels.add('obstacle');
            newDetections.add(AppDetectedObject(
              label: 'Obstacle',
              confidence: 0.50,
              boundingBox: obj.boundingBox,
              detectedAt: DateTime.now(),
              distanceLevel: distanceLevel,
              spatialLocation: spatialLoc,
            ));
          }
        }
      }

      newDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
      _currentDetections = newDetections.length > 8
          ? newDetections.sublist(0, 8)
          : newDetections;

      if (onNewDetection != null) onNewDetection!(_currentDetections);
      await _handleSmartAnnouncement(_currentDetections);

      if (_isOcrEnabled) await _processOcr(inputImage);
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
    if (centerX < third)
      return 'on your left';
    else if (centerX < 2 * third)
      return 'in front of you';
    else
      return 'on your right';
  }

  DistanceLevel _estimateDistance(Rect? boundingBox) {
    if (boundingBox == null) return DistanceLevel.medium;
    final double imageArea = (_lastImageWidth * _lastImageHeight).toDouble();
    if (imageArea <= 0) return DistanceLevel.medium;

    final double boxArea = boundingBox.width * boundingBox.height;
    final double areaRatio = boxArea / imageArea;

    if (areaRatio > 0.35) return DistanceLevel.close;
    if (areaRatio > 0.10) return DistanceLevel.medium;
    return DistanceLevel.far;
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());
      final imageRotation = InputImageRotationValue.fromRawValue(0) ??
          InputImageRotation.rotation0deg;
      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting image: $e');
    }
    return null;
  }

  Future<void> _processOcr(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
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

  Future<void> _handleSmartAnnouncement(
      List<AppDetectedObject> detections) async {
    if (onSpeakText == null || detections.isEmpty) return;

    final priorityDetections = <AppDetectedObject>[];
    final regularDetections = <AppDetectedObject>[];

    for (final detection in detections) {
      if (_isPriorityObject(detection.label))
        priorityDetections.add(detection);
      else
        regularDetections.add(detection);
    }

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
      final minInterval = _isPriorityObject(label)
          ? const Duration(seconds: 3)
          : const Duration(seconds: 6);
      if (elapsed < minInterval) return false;
    }
    return true;
  }

  Future<void> _announceObject(AppDetectedObject detection) async {
    final now = DateTime.now();
    _lastAnnouncedObjects[detection.label] = now;
    _recentlyAnnouncedObjects.add(detection.label);
    Future.delayed(const Duration(seconds: 5),
        () => _recentlyAnnouncedObjects.remove(detection.label));

    final message =
        '${detection.label} ${detection.spatialLocation}, ${detection.distanceDescription}';
    if (onSpeakText != null) onSpeakText!(message);
  }

  bool _isPriorityObject(String label) {
    final lowerLabel = label.toLowerCase();
    return _priorityObjects.any((priority) => lowerLabel.contains(priority));
  }

  ObstaclePriority getObstaclePriority(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('person') ||
        lowerLabel.contains('vehicle') ||
        lowerLabel.contains('car') ||
        lowerLabel.contains('wall')) return ObstaclePriority.critical;
    if (lowerLabel.contains('door') ||
        lowerLabel.contains('stairs') ||
        lowerLabel.contains('wire') ||
        lowerLabel.contains('pole')) return ObstaclePriority.high;
    if (lowerLabel.contains('chair') ||
        lowerLabel.contains('table') ||
        lowerLabel.contains('desk')) return ObstaclePriority.medium;
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
