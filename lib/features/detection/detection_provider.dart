import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ai_vision_pro/features/ai/on_device_ai_service.dart';

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
        return 'right next to you';
      case DistanceLevel.medium:
        return 'a few steps away';
      case DistanceLevel.far:
        return 'in the distance';
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

  final List<String> _ocrTextBuffer = [];
  Timer? _ocrAnalysisTimer;
  bool _isDeepScanning = false;

  static const int _evidenceWindowSize = 5;
  static const int _evidenceMinVotes = 3;
  final Map<String, List<String>> _evidenceBuffer = {};
  List<String> _lastOcrTokens = [];

  static const Set<String> _suppressedLabels = {
    'rectangle',
    'line',
    'parallel',
    'pattern',
    'symmetry',
    'circle',
    'triangle',
    'square',
    'polygon',
    'ellipse',
    'oval',
    'hexagon',
    'octagon',
    'rhombus',
    'trapezoid',
    'curve',
    'arc',
    'angle',
    'diagonal',
    'shape',
    'line art',
    'snapshot',
    'photography',
    'An Object',
    'black and white',
    'grayscale',
    'close-up',
    'macro photography',
    'still life',
    'stock photography',
    'bokeh',
    'depth of field',
    'focus',
    'blur',
    'perspective',
    'view',
    'angle view',
    'wide angle',
    'fisheye',
    'panorama',
    'vignette',
    'exposure',
    'overexposed',
    'underexposed',
    'noise',
    'grain',
    'shutter speed',
    'aperture',
    'iso',
    'white balance',
    'raw image',
    'jpeg',
    'png',
    'tiff',
    'bitmap',
    'pixel',
    'resolution',
    'dpi',
    'color',
    'red',
    'blue',
    'green',
    'yellow',
    'black',
    'white',
    'gray',
    'grey',
    'brown',
    'purple',
    'orange',
    'pink',
    'cyan',
    'magenta',
    'electric blue',
    'turquoise',
    'violet',
    'indigo',
    'maroon',
    'olive',
    'navy',
    'teal',
    'coral',
    'salmon',
    'beige',
    'ivory',
    'khaki',
    'cream',
    'silver',
    'gold',
    'bronze',
    'copper',
    'platinum',
    'lightness',
    'contrast',
    'brightness',
    'saturation',
    'hue',
    'gradient',
    'shadow',
    'reflection',
    'refraction',
    'transparency',
    'opacity',
    'luminance',
    'radiance',
    'glow',
    'shine',
    'gloss',
    'matte',
    'sheen',
    'tints and shades',
    'colorfulness',
    'material property',
    'art',
    'visual arts',
    'illustration',
    'animation',
    'fictional character',
    'graphic design',
    'drawing',
    'sketch',
    'design',
    'abstract representation',
    'logo',
    'brand',
    'graphics',
    'font',
    'typography',
    'lettering',
    'calligraphy',
    'handwriting',
    'doodle',
    'painting',
    'watercolor',
    'oil painting',
    'acrylic',
    'sculpture',
    'carving',
    'engraving',
    'texture',
    'surface',
    'wood',
    'metal',
    'plastic',
    'glass',
    'fabric',
    'textile',
    'leather',
    'rubber',
    'foam',
    'concrete',
    'stone',
    'brick',
    'tile',
    'ceramic',
    'porcelain',
    'marble',
    'granite',
    'steel',
    'iron',
    'aluminum',
    'copper material',
    'carbon fiber',
    'fiber',
    'indoor',
    'outdoor',
    'room',
    'architecture',
    'building',
    'city',
    'street',
    'road',
    'light',
    'scene',
    'nature',
    'environment',
    'universe',
    'space',
    'sky',
    'cloud',
    'horizon',
    'landscape',
    'cityscape',
    'streetscape',
    'roofscape',
    'seascape',
    'nightscape',
    'backdrop',
    'background',
    'foreground',
    'setting',
    'location',
    'place',
    'mathematics',
    'geometry',
    'algebra',
    'calculus',
    'physics',
    'chemistry',
    'biology',
    'medicine',
    'health',
    'fitness',
    'science',
    'technology',
    'engineering',
    'machine',
    'service',
    'astronomy',
    'economics',
    'business',
    'finance',
    'industry',
    'agriculture',
    'politics',
    'history',
    'geography',
    'literature',
    'philosophy',
    'psychology',
    'event',
    'leisure',
    'fun',
    'happy',
    'cool',
    'comfort',
    'darkness',
    'midnight',
    'number',
    'entertainment',
    'music',
    'play',
    'game',
    'sports',
    'hobby',
    'lifestyle',
    'fashion',
    'style',
    'trend',
    'vintage',
    'retro',
    'modern',
    'classic',
    'contemporary',
    'antique',
    'rustic',
    'minimalist',
    'aesthetic',
    'vibe',
    'mood',
    'atmosphere',
    'automotive tire',
    'portrait',
    'selfie',
    'monochrome photography',
    'black & white',
    'grayscale image',
    'photographic film',
    'film photography',
    'analogue photography',
    'digital photography',
    'photo',
    'photograph',
    'image',
    'picture',
    'frame',
    'filter',
    'effect',
    'edit',
    'crop',
    'resize',
    'rotate',
    'flip'
  };

  static const Map<String, String> _labelRefinements = {
    'electronic device': 'Electronic Device',
    'gadget': 'Electronic Device',
    'electronics': 'Electronics',
    'consumer electronics': 'Electronics',
    'personal computer': 'Computer',
    'desktop computer': 'Desktop PC',
    'computer': 'Computer',
    'pc': 'Desktop PC',
    'computer monitor': 'Monitor',
    'monitor': 'Monitor',
    'display': 'Monitor',
    'screen': 'Screen',
    'lcd': 'LCD Screen',
    'led display': 'LED Screen',
    'oled display': 'OLED Screen',
    'flat panel display': 'Flat Panel Screen',
    'computer keyboard': 'Keyboard',
    'keyboard': 'Keyboard',
    'mechanical keyboard': 'Mechanical Keyboard',
    'peripheral': 'Computer Accessory',
    'computer hardware': 'Hardware Component',
    'computer accessory': 'Computer Accessory',
    'netbook': 'Laptop',
    'laptop': 'Laptop',
    'laptop computer': 'Laptop',
    'notebook computer': 'Laptop',
    'macbook': 'Laptop',
    'chromebook': 'Laptop',
    'ultrabook': 'Laptop',
    'tablet computer': 'Tablet',
    'tablet': 'Tablet',
    'ipad': 'Tablet',
    'e-reader': 'E-Reader',
    'ebook reader': 'E-Reader',
    'kindle': 'E-Reader',
    'mobile phone': 'Mobile Phone',
    'smartphone': 'Mobile Phone',
    'iphone': 'Mobile Phone',
    'android phone': 'Mobile Phone',
    'cell phone': 'Mobile Phone',
    'feature phone': 'Mobile Phone',
    'telephony': 'Phone',
    'telephone': 'Phone',
    'landline phone': 'Landline Phone',
    'telephone handset': 'Phone Handset',
    'cordless phone': 'Cordless Phone',
    'office phone': 'Office Phone',
    'mouse': 'Computer Mouse',
    'computer mouse': 'Computer Mouse',
    'optical mouse': 'Computer Mouse',
    'wireless mouse': 'Wireless Mouse',
    'trackpad': 'Trackpad',
    'trackball': 'Trackball',
    'stylus': 'Stylus Pen',
    'graphics tablet': 'Drawing Tablet',
    'drawing tablet': 'Drawing Tablet',
    'remote control': 'Remote Control',
    'tv remote': 'Remote Control',
    'game controller': 'Game Controller',
    'gamepad': 'Game Controller',
    'joystick': 'Joystick',
    'headphones': 'Headphones',
    'earphones': 'Earphones',
    'earbuds': 'Earbuds',
    'headset': 'Headset',
    'speaker': 'Audio Speaker',
    'loudspeaker': 'Audio Speaker',
    'soundbar': 'Soundbar',
    'subwoofer': 'Subwoofer',
    'audio speaker': 'Audio Speaker',
    'bluetooth speaker': 'Bluetooth Speaker',
    'smart speaker': 'Smart Speaker',
    'microphone': 'Microphone',
    'mic': 'Microphone',
    'condenser microphone': 'Condenser Microphone',
    'webcam': 'Webcam',
    'camera': 'Camera',
    'digital camera': 'Digital Camera',
    'dslr': 'DSLR Camera',
    'mirrorless camera': 'Mirrorless Camera',
    'action camera': 'Action Camera',
    'security camera': 'Security Camera',
    'cctv': 'CCTV Camera',
    'drone': 'Drone',
    'projector': 'Projector',
    'television': 'Television',
    'tv': 'Television',
    'smart tv': 'Smart TV',
    'flatscreen tv': 'Flat Screen TV',
    'oled tv': 'OLED TV',
    'router': 'Wi-Fi Router',
    'wifi router': 'Wi-Fi Router',
    'modem': 'Modem',
    'network switch': 'Network Switch',
    'ethernet cable': 'Ethernet Cable',
    'power strip': 'Power Strip',
    'extension cord': 'Extension Cord',
    'surge protector': 'Surge Protector',
    'ups': 'UPS Battery',
    'battery': 'Battery',
    'power bank': 'Power Bank',
    'portable charger': 'Power Bank',
    'charger': 'Charger',
    'adapter': 'Adapter',
    'plug': 'Power Plug',
    'power cord': 'Power Cable',
    'wire': 'Wire',
    'cable': 'Cable',
    'usb cable': 'USB Cable',
    'hdmi cable': 'HDMI Cable',
    'aux cable': 'Aux Cable',
    'hard drive': 'Hard Drive',
    'ssd': 'SSD Drive',
    'hdd': 'Hard Drive',
    'flash drive': 'USB Flash Drive',
    'usb drive': 'USB Flash Drive',
    'memory card': 'Memory Card',
    'sd card': 'SD Card',
    'ram': 'RAM Module',
    'cpu': 'CPU Processor',
    'processor': 'CPU Processor',
    'gpu': 'Graphics Card',
    'graphics card': 'Graphics Card',
    'motherboard': 'Motherboard',
    'printer': 'Printer',
    'laser printer': 'Laser Printer',
    'inkjet printer': 'Inkjet Printer',
    '3d printer': '3D Printer',
    'scanner': 'Document Scanner',
    'document scanner': 'Document Scanner',
    'shredder': 'Paper Shredder',
    'fax machine': 'Fax Machine',
    'photocopier': 'Photocopier',
    'calculator': 'Calculator',
    'scientific calculator': 'Scientific Calculator',
    'smartwatch': 'Smartwatch',
    'smart watch': 'Smartwatch',
    'fitness tracker': 'Fitness Tracker',
    'smart glasses': 'Smart Glasses',
    'vr headset': 'VR Headset',
    'virtual reality headset': 'VR Headset',
    'ar glasses': 'AR Glasses',
    'gaming console': 'Gaming Console',
    'game console': 'Gaming Console',
    'playstation': 'Gaming Console',
    'xbox': 'Gaming Console',
    'nintendo switch': 'Gaming Console',
    'handheld game console': 'Handheld Game Console',
    'musical instrument': 'Laptop',
    'piano': 'Piano',
    'musical keyboard': 'Electronic Keyboard',
    'furniture': 'Furniture',
    'table': 'Table',
    'dining table': 'Dining Table',
    'coffee table': 'Coffee Table',
    'side table': 'Side Table',
    'end table': 'Side Table',
    'console table': 'Console Table',
    'folding table': 'Folding Table',
    'desk': 'Desk',
    'office desk': 'Office Desk',
    'standing desk': 'Standing Desk',
    'writing desk': 'Writing Desk',
    'chair': 'Chair',
    'office chair': 'Office Chair',
    'armchair': 'Armchair',
    'recliner': 'Recliner Chair',
    'rocking chair': 'Rocking Chair',
    'stool': 'Stool',
    'bar stool': 'Bar Stool',
    'folding chair': 'Folding Chair',
    'wheelchair': 'Wheelchair',
    'highchair': 'High Chair',
    'couch': 'Sofa',
    'sofa': 'Sofa',
    'sofa bed': 'Sofa Bed',
    'loveseat': 'Loveseat',
    'sectional sofa': 'Sectional Sofa',
    'futon': 'Futon',
    'bed': 'Bed',
    'bunk bed': 'Bunk Bed',
    'single bed': 'Single Bed',
    'double bed': 'Double Bed',
    'queen bed': 'Queen Bed',
    'king bed': 'King Bed',
    'crib': 'Baby Crib',
    'baby crib': 'Baby Crib',
    'mattress': 'Mattress',
    'headboard': 'Headboard',
    'shelf': 'Shelf',
    'bookcase': 'Bookshelf',
    'bookshelf': 'Bookshelf',
    'bookrack': 'Bookshelf',
    'cupboard': 'Cupboard',
    'cabinet': 'Cabinet',
    'filing cabinet': 'Filing Cabinet',
    'drawer': 'Drawer',
    'dresser': 'Dresser',
    'chest of drawers': 'Chest of Drawers',
    'wardrobe': 'Wardrobe',
    'closet': 'Closet',
    'nightstand': 'Bedside Table',
    'bedside table': 'Bedside Table',
    'tv stand': 'TV Stand',
    'entertainment unit': 'Entertainment Unit',
    'shoe rack': 'Shoe Rack',
    'coat rack': 'Coat Rack',
    'hat rack': 'Hat Rack',
    'door': 'Door',
    'front door': 'Front Door',
    'sliding door': 'Sliding Door',
    'glass door': 'Glass Door',
    'revolving door': 'Revolving Door',
    'window': 'Window',
    'bay window': 'Bay Window',
    'skylight': 'Skylight',
    'stairs': 'Stairs',
    'staircase': 'Staircase',
    'stairway': 'Staircase',
    'step': 'Steps',
    'steps': 'Steps',
    'escalator': 'Escalator',
    'elevator': 'Elevator',
    'lift': 'Elevator',
    'ramp': 'Ramp',
    'handrail': 'Handrail',
    'banister': 'Banister',
    'ladder': 'Ladder',
    'lamp': 'Lamp',
    'floor lamp': 'Floor Lamp',
    'table lamp': 'Table Lamp',
    'desk lamp': 'Desk Lamp',
    'ceiling lamp': 'Ceiling Light',
    'ceiling light': 'Ceiling Light',
    'chandelier': 'Chandelier',
    'pendant light': 'Pendant Light',
    'wall light': 'Wall Light',
    'sconce': 'Wall Sconce',
    'night light': 'Night Light',
    'led strip': 'LED Strip Light',
    'curtain': 'Curtain',
    'drape': 'Drape',
    'blinds': 'Window Blinds',
    'window blind': 'Window Blinds',
    'shutter': 'Window Shutter',
    'pillow': 'Pillow',
    'cushion': 'Cushion',
    'throw pillow': 'Throw Pillow',
    'blanket': 'Blanket',
    'comforter': 'Comforter',
    'duvet': 'Duvet',
    'bed sheet': 'Bed Sheet',
    'bedding': 'Bedding',
    'carpet': 'Carpet',
    'rug': 'Rug',
    'area rug': 'Area Rug',
    'doormat': 'Doormat',
    'bath mat': 'Bath Mat',
    'mirror': 'Mirror',
    'wall mirror': 'Wall Mirror',
    'full length mirror': 'Full Length Mirror',
    'picture frame': 'Picture Frame',
    'photo frame': 'Photo Frame',
    'painting frame': 'Picture Frame',
    'wall art': 'Wall Art',
    'wall clock': 'Wall Clock',
    'clock': 'Clock',
    'alarm clock': 'Alarm Clock',
    'mantel clock': 'Mantel Clock',
    'grandfather clock': 'Grandfather Clock',
    'fireplace': 'Fireplace',
    'heater': 'Space Heater',
    'space heater': 'Space Heater',
    'radiator': 'Radiator',
    'fan': 'Electric Fan',
    'ceiling fan': 'Ceiling Fan',
    'pedestal fan': 'Pedestal Fan',
    'air conditioner': 'Air Conditioner',
    'ac unit': 'Air Conditioner',
    'air purifier': 'Air Purifier',
    'humidifier': 'Humidifier',
    'dehumidifier': 'Dehumidifier',
    'vase': 'Vase',
    'flower vase': 'Flower Vase',
    'candle': 'Candle',
    'candleholder': 'Candleholder',
    'picture': 'Framed Picture',
    'painting': 'Painting',
    'tapestry': 'Tapestry',
    'sculpture': 'Sculpture',
    'figurine': 'Figurine',
    'decorative object': 'Decorative Item',
    'ornament': 'Ornament',
    'aquarium': 'Fish Tank',
    'fish tank': 'Fish Tank',
    'terrarium': 'Terrarium',
    'safe': 'Safe Box',
    'storage box': 'Storage Box',
    'bin': 'Storage Bin',
    'laundry basket': 'Laundry Basket',
    'hamper': 'Laundry Hamper',
    'clothes basket': 'Laundry Basket',
    'ironing board': 'Ironing Board',
    'iron': 'Clothes Iron',
    'clothes iron': 'Clothes Iron',
    'clothes hanger': 'Clothes Hanger',
    'hanger': 'Clothes Hanger',
    'kitchen appliance': 'Kitchen Appliance',
    'refrigerator': 'Refrigerator',
    'fridge': 'Refrigerator',
    'freezer': 'Freezer',
    'microwave oven': 'Microwave',
    'microwave': 'Microwave',
    'oven': 'Oven',
    'convection oven': 'Convection Oven',
    'toaster oven': 'Toaster Oven',
    'toaster': 'Toaster',
    'air fryer': 'Air Fryer',
    'stove': 'Stove',
    'gas stove': 'Gas Stove',
    'electric stove': 'Electric Stove',
    'cooktop': 'Cooktop',
    'induction cooktop': 'Induction Cooktop',
    'range': 'Kitchen Range',
    'range hood': 'Range Hood',
    'exhaust hood': 'Range Hood',
    'dishwasher': 'Dishwasher',
    'sink': 'Sink',
    'kitchen sink': 'Kitchen Sink',
    'bathroom sink': 'Bathroom Sink',
    'faucet': 'Faucet',
    'tap': 'Water Tap',
    'washing machine': 'Washing Machine',
    'dryer': 'Clothes Dryer',
    'washer dryer': 'Washer Dryer',
    'blender': 'Blender',
    'food processor': 'Food Processor',
    'mixer': 'Stand Mixer',
    'stand mixer': 'Stand Mixer',
    'hand mixer': 'Hand Mixer',
    'juicer': 'Juicer',
    'coffee maker': 'Coffee Maker',
    'coffee machine': 'Coffee Machine',
    'espresso machine': 'Espresso Machine',
    'kettle': 'Electric Kettle',
    'electric kettle': 'Electric Kettle',
    'rice cooker': 'Rice Cooker',
    'pressure cooker': 'Pressure Cooker',
    'slow cooker': 'Slow Cooker',
    'instant pot': 'Instant Pot',
    'sandwich maker': 'Sandwich Maker',
    'waffle maker': 'Waffle Maker',
    'grill': 'Grill',
    'barbecue grill': 'BBQ Grill',
    'bbq': 'BBQ Grill',
    'bread maker': 'Bread Maker',
    'food scale': 'Kitchen Scale',
    'kitchen scale': 'Kitchen Scale',
    'pan': 'Frying Pan',
    'frying pan': 'Frying Pan',
    'skillet': 'Skillet',
    'wok': 'Wok',
    'saucepan': 'Saucepan',
    'pot': 'Cooking Pot',
    'cooking pot': 'Cooking Pot',
    'stock pot': 'Stock Pot',
    'baking tray': 'Baking Tray',
    'baking sheet': 'Baking Sheet',
    'casserole dish': 'Casserole Dish',
    'colander': 'Colander',
    'strainer': 'Strainer',
    'cutting board': 'Cutting Board',
    'chopping board': 'Chopping Board',
    'rolling pin': 'Rolling Pin',
    'whisk': 'Whisk',
    'spatula': 'Spatula',
    'ladle': 'Ladle',
    'tongs': 'Kitchen Tongs',
    'grater': 'Grater',
    'peeler': 'Vegetable Peeler',
    'can opener': 'Can Opener',
    'bottle opener': 'Bottle Opener',
    'corkscrew': 'Corkscrew',
    'fork': 'Fork',
    'knife': 'Knife',
    'kitchen knife': 'Kitchen Knife',
    'bread knife': 'Bread Knife',
    'chef knife': 'Chef Knife',
    'butter knife': 'Butter Knife',
    'spoon': 'Spoon',
    'teaspoon': 'Teaspoon',
    'tablespoon': 'Tablespoon',
    'dessert spoon': 'Dessert Spoon',
    'soup spoon': 'Soup Spoon',
    'chopsticks': 'Chopsticks',
    'plate': 'Plate',
    'dinner plate': 'Dinner Plate',
    'side plate': 'Side Plate',
    'bowl': 'Bowl',
    'cereal bowl': 'Cereal Bowl',
    'soup bowl': 'Soup Bowl',
    'salad bowl': 'Salad Bowl',
    'cup': 'Cup',
    'mug': 'Mug',
    'coffee mug': 'Coffee Mug',
    'tea cup': 'Tea Cup',
    'glass': 'Drinking Glass',
    'drinking glass': 'Drinking Glass',
    'wine glass': 'Wine Glass',
    'beer glass': 'Beer Glass',
    'tumbler': 'Tumbler',
    'shot glass': 'Shot Glass',
    'jar': 'Jar',
    'mason jar': 'Mason Jar',
    'container': 'Container',
    'lunch box': 'Lunch Box',
    'tiffin box': 'Tiffin Box',
    'tupperware': 'Storage Container',
    'bottle': 'Bottle',
    'water bottle': 'Water Bottle',
    'juice bottle': 'Juice Bottle',
    'wine bottle': 'Wine Bottle',
    'beer bottle': 'Beer Bottle',
    'thermos': 'Thermos Flask',
    'flask': 'Flask',
    'jug': 'Jug',
    'pitcher': 'Pitcher',
    'tray': 'Tray',
    'serving tray': 'Serving Tray',
    'napkin': 'Napkin',
    'paper towel': 'Paper Towel',
    'kitchen towel': 'Kitchen Towel',
    'dish cloth': 'Dish Cloth',
    'sponge': 'Sponge',
    'dish brush': 'Dish Brush',
    'soap dispenser': 'Soap Dispenser',
    'dish soap': 'Dish Soap',
    'trash can': 'Dustbin',
    'rubbish bin': 'Dustbin',
    'waste bin': 'Dustbin',
    'recycle bin': 'Recycling Bin',
    'dustbin': 'Dustbin',
    'waste container': 'Dustbin',
    'garbage bin': 'Dustbin',
    'food': 'Food',
    'meal': 'Meal',
    'dish': 'Dish',
    'cuisine': 'Cuisine',
    'snack': 'Snack',
    'fast food': 'Fast Food',
    'junk food': 'Junk Food',
    'fruit': 'Fruit',
    'apple': 'Apple',
    'banana': 'Banana',
    'orange': 'Orange',
    'mango': 'Mango',
    'grapes': 'Grapes',
    'strawberry': 'Strawberry',
    'watermelon': 'Watermelon',
    'pineapple': 'Pineapple',
    'coconut': 'Coconut',
    'lemon': 'Lemon',
    'lime': 'Lime',
    'cherry': 'Cherry',
    'peach': 'Peach',
    'pear': 'Pear',
    'kiwi': 'Kiwi Fruit',
    'papaya': 'Papaya',
    'guava': 'Guava',
    'pomegranate': 'Pomegranate',
    'avocado': 'Avocado',
    'vegetable': 'Vegetable',
    'carrot': 'Carrot',
    'potato': 'Potato',
    'tomato': 'Tomato',
    'onion': 'Onion',
    'garlic': 'Garlic',
    'ginger': 'Ginger',
    'broccoli': 'Broccoli',
    'cabbage': 'Cabbage',
    'spinach': 'Spinach',
    'lettuce': 'Lettuce',
    'cucumber': 'Cucumber',
    'bell pepper': 'Bell Pepper',
    'chili': 'Chili Pepper',
    'corn': 'Corn',
    'mushroom': 'Mushroom',
    'peas': 'Peas',
    'beans': 'Beans',
    'bread': 'Bread',
    'toast': 'Toast',
    'bun': 'Bun',
    'roll': 'Bread Roll',
    'bagel': 'Bagel',
    'croissant': 'Croissant',
    'sandwich': 'Sandwich',
    'burger': 'Burger',
    'hot dog': 'Hot Dog',
    'pizza': 'Pizza',
    'pasta': 'Pasta',
    'noodle': 'Noodles',
    'rice': 'Rice',
    'soup': 'Soup',
    'salad': 'Salad',
    'steak': 'Steak',
    'chicken': 'Chicken',
    'fish food': 'Fish',
    'egg': 'Egg',
    'cheese': 'Cheese',
    'butter': 'Butter',
    'milk': 'Milk',
    'yogurt': 'Yogurt',
    'ice cream': 'Ice Cream',
    'cake': 'Cake',
    'cookie': 'Cookie',
    'biscuit': 'Biscuit',
    'chocolate': 'Chocolate',
    'candy': 'Candy',
    'sweet': 'Sweets',
    'dessert': 'Dessert',
    'drink': 'Drink',
    'beverage': 'Beverage',
    'coffee': 'Coffee',
    'tea': 'Tea',
    'juice': 'Juice',
    'soda': 'Soda',
    'water': 'Water',
    'alcohol': 'Alcoholic Drink',
    'wine': 'Wine',
    'beer': 'Beer',
    'cocktail': 'Cocktail',
    'clothing': 'Clothing',
    'apparel': 'Clothing',
    'clothes': 'Clothes',
    'outerwear': 'Outerwear',
    'jacket': 'Jacket',
    'coat': 'Coat',
    'overcoat': 'Overcoat',
    'raincoat': 'Raincoat',
    'windbreaker': 'Windbreaker',
    'blazer': 'Blazer',
    'suit jacket': 'Suit Jacket',
    'hoodie': 'Hoodie',
    'sweater': 'Sweater',
    'sweatshirt': 'Sweatshirt',
    'cardigan': 'Cardigan',
    'vest': 'Vest',
    'shirt': 'Shirt',
    'dress shirt': 'Dress Shirt',
    't-shirt': 'T-Shirt',
    'polo shirt': 'Polo Shirt',
    'blouse': 'Blouse',
    'top': 'Top',
    'tank top': 'Tank Top',
    'jeans': 'Jeans',
    'trousers': 'Trousers',
    'pants': 'Pants',
    'shorts': 'Shorts',
    'skirt': 'Skirt',
    'dress': 'Dress',
    'gown': 'Gown',
    'suit': 'Suit',
    'tuxedo': 'Tuxedo',
    'uniform': 'Uniform',
    'sportswear': 'Sportswear',
    'activewear': 'Activewear',
    'leggings': 'Leggings',
    'yoga pants': 'Yoga Pants',
    'tracksuit': 'Tracksuit',
    'pajamas': 'Pajamas',
    'underwear': 'Underwear',
    'sock': 'Socks',
    'socks': 'Socks',
    'shoe': 'Shoe',
    'footwear': 'Shoe',
    'sneaker': 'Sneaker',
    'sneakers': 'Sneakers',
    'running shoes': 'Running Shoes',
    'sports shoes': 'Sports Shoes',
    'formal shoes': 'Formal Shoes',
    'oxford shoes': 'Oxford Shoes',
    'loafers': 'Loafers',
    'sandal': 'Sandal',
    'flip flops': 'Flip Flops',
    'slippers': 'Slippers',
    'boot': 'Boot',
    'boots': 'Boots',
    'ankle boots': 'Ankle Boots',
    'high heels': 'High Heels',
    'stiletto': 'Stiletto Heels',
    'hat': 'Hat',
    'cap': 'Cap',
    'baseball cap': 'Baseball Cap',
    'beanie': 'Beanie',
    'fedora': 'Fedora Hat',
    'sun hat': 'Sun Hat',
    'helmet': 'Helmet',
    'cycling helmet': 'Cycling Helmet',
    'hard hat': 'Hard Hat',
    'glasses': 'Glasses',
    'eyeglasses': 'Eyeglasses',
    'reading glasses': 'Reading Glasses',
    'sunglasses': 'Sunglasses',
    'goggles': 'Goggles',
    'watch': 'Watch',
    'wristwatch': 'Wristwatch',
    'necklace': 'Necklace',
    'bracelet': 'Bracelet',
    'ring': 'Ring',
    'earring': 'Earring',
    'earrings': 'Earrings',
    'brooch': 'Brooch',
    'tie': 'Necktie',
    'necktie': 'Necktie',
    'bow tie': 'Bow Tie',
    'scarf': 'Scarf',
    'muffler': 'Muffler',
    'shawl': 'Shawl',
    'glove': 'Glove',
    'gloves': 'Gloves',
    'mittens': 'Mittens',
    'belt': 'Belt',
    'suspenders': 'Suspenders',
    'bag': 'Bag',
    'handbag': 'Handbag',
    'purse': 'Purse',
    'clutch': 'Clutch Bag',
    'tote bag': 'Tote Bag',
    'shoulder bag': 'Shoulder Bag',
    'crossbody bag': 'Crossbody Bag',
    'backpack': 'Backpack',
    'school bag': 'School Bag',
    'rucksack': 'Rucksack',
    'suitcase': 'Suitcase',
    'luggage': 'Luggage',
    'travel bag': 'Travel Bag',
    'duffel bag': 'Duffel Bag',
    'gym bag': 'Gym Bag',
    'briefcase': 'Briefcase',
    'laptop bag': 'Laptop Bag',
    'messenger bag': 'Messenger Bag',
    'diaper bag': 'Diaper Bag',
    'fanny pack': 'Waist Bag',
    'shopping bag': 'Shopping Bag',
    'grocery bag': 'Grocery Bag',
    'wallet': 'Wallet',
    'billfold': 'Wallet',
    'card holder': 'Card Holder',
    'coin purse': 'Coin Purse',
    'umbrella': 'Umbrella',
    'parasol': 'Parasol',
    'person': 'Person',
    'human': 'Person',
    'human being': 'Person',
    'human body': 'Person',
    'face': 'Person',
    'head': 'Person',
    'people': 'People',
    'crowd': 'Crowd of People',
    'group': 'Group of People',
    'man': 'Person',
    'woman': 'Person',
    'male': 'Person',
    'female': 'Person',
    'adult': 'Adult',
    'elderly': 'Elderly Person',
    'senior': 'Senior Person',
    'teenager': 'Teenager',
    'child': 'Child',
    'kid': 'Child',
    'toddler': 'Toddler',
    'baby': 'Baby',
    'infant': 'Infant',
    'girl': 'Girl',
    'boy': 'Boy',
    'hand': 'Hand',
    'arm': 'Arm',
    'leg': 'Leg',
    'foot': 'Foot',
    'finger': 'Finger',
    'vehicle': 'Vehicle',
    'car': 'Car',
    'automobile': 'Car',
    'sedan': 'Sedan Car',
    'suv': 'SUV',
    'hatchback': 'Hatchback Car',
    'convertible': 'Convertible Car',
    'sports car': 'Sports Car',
    'coupe': 'Coupe Car',
    'pickup truck': 'Pickup Truck',
    'truck': 'Truck',
    'lorry': 'Lorry',
    'van': 'Van',
    'minivan': 'Minivan',
    'bus': 'Bus',
    'school bus': 'School Bus',
    'double decker bus': 'Double Decker Bus',
    'minibus': 'Minibus',
    'motorcycle': 'Motorcycle',
    'motorbike': 'Motorcycle',
    'scooter': 'Scooter',
    'moped': 'Moped',
    'bicycle': 'Bicycle',
    'bike': 'Bicycle',
    'mountain bike': 'Mountain Bike',
    'road bike': 'Road Bike',
    'electric bike': 'Electric Bike',
    'e-bike': 'Electric Bike',
    'tricycle': 'Tricycle',
    'wheel': 'Wheel',
    'tire': 'Tyre',
    'tyre': 'Tyre',
    'train': 'Train',
    'metro': 'Metro Train',
    'subway': 'Subway Train',
    'tram': 'Tram',
    'airplane': 'Airplane',
    'aircraft': 'Aircraft',
    'helicopter': 'Helicopter',
    'boat': 'Boat',
    'ship': 'Ship',
    'ferry': 'Ferry',
    'yacht': 'Yacht',
    'ambulance': 'Ambulance',
    'fire truck': 'Fire Truck',
    'police car': 'Police Car',
    'taxi': 'Taxi',
    'auto rickshaw': 'Auto Rickshaw',
    'rickshaw': 'Rickshaw',
    'tractor': 'Tractor',
    'forklift': 'Forklift',
    'crane vehicle': 'Crane',
    'electric vehicle': 'Electric Vehicle',
    'ev': 'Electric Vehicle',
    'golf cart': 'Golf Cart',
    'atv': 'ATV',
    'sign': 'Sign Board',
    'road sign': 'Road Sign',
    'traffic sign': 'Traffic Sign',
    'street sign': 'Street Sign',
    'stop sign': 'Stop Sign',
    'traffic light': 'Traffic Light',
    'traffic signal': 'Traffic Signal',
    'traffic cone': 'Traffic Cone',
    'road barrier': 'Road Barrier',
    'barricade': 'Barricade',
    'bollard': 'Bollard',
    'speed bump': 'Speed Bump',
    'manhole': 'Manhole Cover',
    'manhole cover': 'Manhole Cover',
    'fire hydrant': 'Fire Hydrant',
    'post': 'Post',
    'pole': 'Pole',
    'lamp post': 'Lamp Post',
    'electricity pole': 'Electricity Pole',
    'telephone pole': 'Telephone Pole',
    'street light': 'Street Light',
    'bus stop': 'Bus Stop',
    'bench': 'Bench',
    'park bench': 'Park Bench',
    'trash bin': 'Waste Bin',
    'letterbox': 'Letter Box',
    'postbox': 'Post Box',
    'mailbox': 'Mailbox',
    'parking meter': 'Parking Meter',
    'atm': 'ATM Machine',
    'cash machine': 'ATM Machine',
    'vending machine': 'Vending Machine',
    'kiosk': 'Kiosk',
    'ticket machine': 'Ticket Machine',
    'newspaper stand': 'Newspaper Stand',
    'fountain': 'Fountain',
    'statue': 'Statue',
    'monument': 'Monument',
    'gate': 'Gate',
    'fence': 'Fence',
    'railing': 'Railing',
    'guardrail': 'Guardrail',
    'bridge': 'Bridge',
    'footbridge': 'Footbridge',
    'pedestrian crossing': 'Pedestrian Crossing',
    'crosswalk': 'Crosswalk',
    'pavement': 'Pavement',
    'sidewalk': 'Sidewalk',
    'curb': 'Kerb',
    'gutter': 'Gutter',
    'pothole': 'Pothole',
    'plant': 'Plant',
    'indoor plant': 'Indoor Plant',
    'potted plant': 'Potted Plant',
    'houseplant': 'Houseplant',
    'flower': 'Flower',
    'rose': 'Rose',
    'sunflower': 'Sunflower',
    'tulip': 'Tulip',
    'lily': 'Lily',
    'orchid': 'Orchid',
    'daisy': 'Daisy',
    'tree': 'Tree',
    'palm tree': 'Palm Tree',
    'oak tree': 'Oak Tree',
    'pine tree': 'Pine Tree',
    'bush': 'Bush',
    'shrub': 'Shrub',
    'hedge': 'Hedge',
    'leaf': 'Leaf',
    'leaves': 'Leaves',
    'branch': 'Branch',
    'grass': 'Grass',
    'lawn': 'Lawn',
    'moss': 'Moss',
    'fern': 'Fern',
    'cactus': 'Cactus',
    'bamboo': 'Bamboo',
    'animal': 'Animal',
    'pet': 'Pet',
    'dog': 'Dog',
    'puppy': 'Puppy',
    'cat': 'Cat',
    'kitten': 'Kitten',
    'bird': 'Bird',
    'parrot': 'Parrot',
    'pigeon': 'Pigeon',
    'crow': 'Crow',
    'sparrow': 'Sparrow',
    'rabbit': 'Rabbit',
    'hamster': 'Hamster',
    'guinea pig': 'Guinea Pig',
    'fish': 'Fish',
    'turtle': 'Turtle',
    'snake': 'Snake',
    'lizard': 'Lizard',
    'cow': 'Cow',
    'goat': 'Goat',
    'sheep': 'Sheep',
    'horse': 'Horse',
    'donkey': 'Donkey',
    'pig': 'Pig',
    'chicken animal': 'Chicken',
    'duck': 'Duck',
    'elephant': 'Elephant',
    'monkey': 'Monkey',
    'lion': 'Lion',
    'tiger': 'Tiger',
    'deer': 'Deer',
    'bear': 'Bear',
    'wolf': 'Wolf',
    'fox': 'Fox',
    'squirrel': 'Squirrel',
    'rat': 'Rat',
    'mouse animal': 'Mouse',
    'butterfly': 'Butterfly',
    'insect': 'Insect',
    'bee': 'Bee',
    'ant': 'Ant',
    'spider': 'Spider',
    'book': 'Book',
    'textbook': 'Textbook',
    'novel': 'Novel',
    'dictionary': 'Dictionary',
    'notebook': 'Notebook',
    'notepad': 'Notepad',
    'journal': 'Journal',
    'diary': 'Diary',
    'planner': 'Planner',
    'paper': 'Paper Document',
    'document': 'Paper Document',
    'printed paper': 'Printed Paper',
    'a4 paper': 'A4 Paper',
    'letterhead': 'Letterhead',
    'envelope': 'Envelope',
    'letter': 'Letter',
    'invoice': 'Invoice',
    'receipt': 'Receipt',
    'form': 'Form',
    'page': 'Paper Document',
    'newspaper': 'Newspaper',
    'magazine': 'Magazine',
    'brochure': 'Brochure',
    'flyer': 'Flyer',
    'leaflet': 'Leaflet',
    'poster': 'Poster',
    'banner': 'Banner',
    'card': 'Card',
    'business card': 'Business Card',
    'greeting card': 'Greeting Card',
    'postcard': 'Postcard',
    'sticky note': 'Sticky Note',
    'post-it note': 'Sticky Note',
    'index card': 'Index Card',
    'binder': 'Binder',
    'folder': 'File Folder',
    'file folder': 'File Folder',
    'clipboard': 'Clipboard',
    'pen': 'Pen',
    'ballpoint pen': 'Ballpoint Pen',
    'fountain pen': 'Fountain Pen',
    'gel pen': 'Gel Pen',
    'marker': 'Marker Pen',
    'highlighter': 'Highlighter Pen',
    'pencil': 'Pencil',
    'mechanical pencil': 'Mechanical Pencil',
    'colored pencil': 'Colored Pencil',
    'eraser': 'Eraser',
    'rubber': 'Eraser',
    'ruler': 'Ruler',
    'scale ruler': 'Scale Ruler',
    'compass': 'Drawing Compass',
    'protractor': 'Protractor',
    'scissors': 'Scissors',
    'stapler': 'Stapler',
    'staples': 'Staples',
    'paper clip': 'Paper Clip',
    'binder clip': 'Binder Clip',
    'rubber band': 'Rubber Band',
    'tape': 'Adhesive Tape',
    'scotch tape': 'Scotch Tape',
    'duct tape': 'Duct Tape',
    'glue': 'Glue',
    'glue stick': 'Glue Stick',
    'correction fluid': 'Correction Fluid',
    'white out': 'Correction Fluid',
    'sharpener': 'Pencil Sharpener',
    'punch': 'Hole Punch',
    'hole punch': 'Hole Punch',
    'whiteboard': 'Whiteboard',
    'blackboard': 'Blackboard',
    'chalkboard': 'Chalkboard',
    'chalk': 'Chalk',
    'dry erase marker': 'Whiteboard Marker',
    'stamp': 'Stamp',
    'ink pad': 'Ink Pad',
    'toothbrush': 'Toothbrush',
    'electric toothbrush': 'Electric Toothbrush',
    'toothpaste': 'Toothpaste',
    'mouthwash': 'Mouthwash',
    'floss': 'Dental Floss',
    'razor': 'Razor',
    'shaving cream': 'Shaving Cream',
    'comb': 'Comb',
    'hairbrush': 'Hairbrush',
    'hair dryer': 'Hair Dryer',
    'blow dryer': 'Hair Dryer',
    'hair straightener': 'Hair Straightener',
    'flat iron': 'Hair Straightener',
    'curling iron': 'Curling Iron',
    'shampoo': 'Shampoo Bottle',
    'conditioner': 'Conditioner Bottle',
    'body wash': 'Body Wash Bottle',
    'soap': 'Soap',
    'bar of soap': 'Bar Soap',
    'hand sanitizer': 'Hand Sanitizer',
    'lotion': 'Lotion',
    'moisturizer': 'Moisturizer',
    'sunscreen': 'Sunscreen',
    'perfume': 'Perfume Bottle',
    'cologne': 'Cologne Bottle',
    'deodorant': 'Deodorant',
    'lipstick': 'Lipstick',
    'makeup': 'Makeup',
    'foundation': 'Foundation',
    'mascara': 'Mascara',
    'eyeliner': 'Eyeliner',
    'eyeshadow': 'Eyeshadow',
    'nail polish': 'Nail Polish',
    'compact mirror': 'Compact Mirror',
    'towel': 'Towel',
    'bath towel': 'Bath Towel',
    'hand towel': 'Hand Towel',
    'toilet': 'Toilet',
    'toilet seat': 'Toilet Seat',
    'toilet paper': 'Toilet Paper',
    'tissue': 'Tissue',
    'tissue box': 'Tissue Box',
    'bathtub': 'Bathtub',
    'shower': 'Shower',
    'shower head': 'Shower head',
    'shower curtain': 'Shower Curtain',
    'scale': 'Bathroom Scale',
    'weighing scale': 'Weighing Scale',
    'medicine cabinet': 'Medicine Cabinet',
    'first aid kit': 'First Aid Kit',
    'bandage': 'Bandage',
    'medicine': 'Medicine',
    'pill': 'Pill',
    'tablet pill': 'Pill Tablet',
    'syringe': 'Syringe',
    'thermometer': 'Thermometer',
    'blood pressure monitor': 'Blood Pressure Monitor',
    'stethoscope': 'Stethoscope',
    'hearing aid': 'Hearing Aid',
    'crutch': 'Crutch',
    'cane': 'Walking Cane',
    'walking stick': 'Walking Stick',
    'sports equipment': 'Sports Equipment',
    'football': 'Football',
    'soccer ball': 'Football',
    'basketball': 'Basketball',
    'tennis ball': 'Tennis Ball',
    'cricket ball': 'Cricket Ball',
    'baseball': 'Baseball',
    'volleyball': 'Volleyball',
    'rugby ball': 'Rugby Ball',
    'golf ball': 'Golf Ball',
    'ping pong ball': 'Table Tennis Ball',
    'badminton shuttlecock': 'Shuttlecock',
    'tennis racket': 'Tennis Racket',
    'badminton racket': 'Badminton Racket',
    'cricket bat': 'Cricket Bat',
    'baseball bat': 'Baseball Bat',
    'hockey stick': 'Hockey Stick',
    'golf club': 'Golf Club',
    'skateboard': 'Skateboard',
    'surfboard': 'Surfboard',
    'snowboard': 'Snowboard',
    'ski': 'Ski',
    'skis': 'Skis',
    'treadmill': 'Treadmill',
    'exercise bike': 'Exercise Bike',
    'dumbbell': 'Dumbbell',
    'barbell': 'Barbell',
    'kettlebell': 'Kettlebell',
    'weight plate': 'Weight Plate',
    'resistance band': 'Resistance Band',
    'yoga mat': 'Yoga Mat',
    'exercise mat': 'Exercise Mat',
    'jump rope': 'Jump Rope',
    'punching bag': 'Punching Bag',
    'boxing gloves': 'Boxing Gloves',
    'swimming goggles': 'Swimming Goggles',
    'swimming cap': 'Swimming Cap',
    'life jacket': 'Life Jacket',
    'tent': 'Tent',
    'sleeping bag': 'Sleeping Bag',
    'hiking boot': 'Hiking Boot',
    'backpack hiking': 'Hiking Backpack',
    'fishing rod': 'Fishing Rod',
    'bicycle pump': 'Bicycle Pump',
    'water bottle sports': 'Sports Water Bottle',
    'tool': 'Tool',
    'hammer': 'Hammer',
    'screwdriver': 'Screwdriver',
    'wrench': 'Wrench',
    'spanner': 'Spanner',
    'pliers': 'Pliers',
    'saw': 'Saw',
    'hacksaw': 'Hacksaw',
    'drill': 'Power Drill',
    'power drill': 'Power Drill',
    'tape measure': 'Tape Measure',
    'measuring tape': 'Measuring Tape',
    'level': 'Spirit Level',
    'spirit level': 'Spirit Level',
    'chisel': 'Chisel',
    'file tool': 'Metal File',
    'sandpaper': 'Sandpaper',
    'paintbrush': 'Paintbrush',
    'paint roller': 'Paint Roller',
    'paint can': 'Paint Can',
    'toolbox': 'Toolbox',
    'tool chest': 'Tool Chest',
    'workbench': 'Workbench',
    'vice': 'Vice / Clamp',
    'clamp': 'Clamp',
    'nail': 'Nail',
    'screw': 'Screw',
    'bolt': 'Bolt',
    'nut': 'Nut',
    'washer': 'Washer',
    'glue gun': 'Glue Gun',
    'soldering iron': 'Soldering Iron',
    'multimeter': 'Multimeter',
    'voltage tester': 'Voltage Tester',
    'wire stripper': 'Wire Stripper',
    'utility knife': 'Utility Knife',
    'box cutter': 'Box Cutter',
    'wrench adjustable': 'Adjustable Wrench',
    'pipe wrench': 'Pipe Wrench',
    'ladder tool': 'Ladder',
    'broom': 'Broom',
    'mop': 'Mop',
    'dustpan': 'Dustpan',
    'vacuum cleaner': 'Vacuum Cleaner',
    'robotic vacuum': 'Robot Vacuum',
    'garden hose': 'Garden Hose',
    'watering can': 'Watering Can',
    'rake': 'Garden Rake',
    'shovel': 'Shovel',
    'spade': 'Spade',
    'hoe': 'Hoe',
    'trowel': 'Garden Trowel',
    'lawnmower': 'Lawnmower',
    'wheelbarrow': 'Wheelbarrow',
    'fire extinguisher': 'Fire Extinguisher',
    'safety cone': 'Safety Cone',
    'safety vest': 'Safety Vest',
    'goggles safety': 'Safety Goggles',
    'gloves work': 'Work Gloves',
    'coin': 'Coin',
    'coins': 'Coins',
    'cash': 'Cash',
    'banknote': 'Currency Note',
    'currency': 'Currency',
    'money': 'Money',
    'credit card': 'Credit Card',
    'debit card': 'Debit Card',
    'bank card': 'Bank Card',
    'cheque': 'Cheque',
    'check': 'Cheque',
    'gold': 'Gold',
    'jewelry': 'Jewellery',
    'jewellery': 'Jewellery',
    'diamond': 'Diamond',
    'gem': 'Gemstone',
    'gemstone': 'Gemstone',
    'key': 'Key',
    'key chain': 'Key Chain',
    'keychain': 'Key Chain',
    'lock': 'Lock',
    'padlock': 'Padlock',
    'deadbolt': 'Deadbolt Lock',
    'door lock': 'Door Lock',
    'cctv camera': 'CCTV Camera',
    'alarm': 'Alarm System',
    'smoke detector': 'Smoke Detector',
    'carbon monoxide detector': 'CO Detector',
    'motion sensor': 'Motion Sensor',
    'doorbell': 'Doorbell',
    'video doorbell': 'Video Doorbell',
    'intercom': 'Intercom',
    'toy': 'Toy',
    'toys': 'Toys',
    'teddy bear': 'Teddy Bear',
    'stuffed animal': 'Stuffed Animal',
    'doll': 'Doll',
    'action figure': 'Action Figure',
    'building blocks': 'Building Blocks',
    'lego': 'LEGO Blocks',
    'lego blocks': 'LEGO Blocks',
    'puzzle': 'Puzzle',
    'board game': 'Board Game',
    'chess set': 'Chess Set',
    'checkers': 'Checkers Board',
    'card game': 'Card Game',
    'playing cards': 'Playing Cards',
    'toy car': 'Toy Car',
    'remote control car': 'RC Car',
    'rc car': 'RC Car',
    'kite': 'Kite',
    'balloon': 'Balloon',
    'bubble wand': 'Bubble Wand',
    'frisbee': 'Frisbee',
    'hula hoop': 'Hula Hoop',
    'baby bottle': 'Baby Bottle',
    'pacifier': 'Pacifier',
    'stroller': 'Baby Stroller',
    'pram': 'Baby Pram',
    'high chair': 'High Chair',
    'baby walker': 'Baby Walker',
    'play mat': 'Play Mat',
    'swing': 'Swing',
    'slide': 'Slide',
    'guitar': 'Guitar',
    'acoustic guitar': 'Acoustic Guitar',
    'electric guitar': 'Electric Guitar',
    'bass guitar': 'Bass Guitar',
    'ukulele': 'Ukulele',
    'violin': 'Violin',
    'cello': 'Cello',
    'harp': 'Harp',
    'trumpet': 'Trumpet',
    'trombone': 'Trombone',
    'saxophone': 'Saxophone',
    'flute': 'Flute',
    'clarinet': 'Clarinet',
    'drum': 'Drum',
    'drum kit': 'Drum Kit',
    'drum set': 'Drum Set',
    'bongo drums': 'Bongo Drums',
    'tabla': 'Tabla',
    'sitar': 'Sitar',
    'harmonium': 'Harmonium',
    'accordion': 'Accordion',
    'xylophone': 'Xylophone',
    'record player': 'Record Player',
    'vinyl record': 'Vinyl Record',
    'music stand': 'Music Stand',
    'sheet music': 'Sheet Music',
    'hospital bed': 'Hospital Bed',
    'wheelchair medical': 'Wheelchair',
    'stretcher': 'Stretcher',
    'iv drip': 'IV Drip',
    'oxygen tank': 'Oxygen Tank',
    'nebulizer': 'Nebulizer',
    'pulse oximeter': 'Pulse Oximeter',
    'ecg machine': 'ECG Machine',
    'defibrillator': 'Defibrillator',
    'x-ray': 'X-Ray Image',
    'mri machine': 'MRI Machine',
    'ultrasound machine': 'Ultrasound Machine',
    'surgical mask': 'Surgical Mask',
    'face mask': 'Face Mask',
    'n95 mask': 'N95 Mask',
    'gloves medical': 'Medical Gloves',
    'surgical gloves': 'Surgical Gloves',
    'latex gloves': 'Latex Gloves',
    'eye drops': 'Eye Drops',
    'nasal spray': 'Nasal Spray',
    'inhaler': 'Inhaler',
    'box': 'Box',
    'cardboard box': 'Cardboard Box',
    'crate': 'Crate',
    'basket': 'Basket',
    'wire basket': 'Wire Basket',
    'bucket': 'Bucket',
    'pail': 'Bucket',
    'barrel': 'Barrel',
    'drum container': 'Drum Container',
    'canister': 'Canister',
    'dispenser': 'Dispenser',
    'bag paper': 'Paper Bag',
    'paper bag': 'Paper Bag',
    'plastic bag': 'Plastic Bag',
    'wrapper': 'Wrapper',
    'packaging': 'Packaging',
    'pallet': 'Pallet',
    'trolley': 'Trolley',
    'cart': 'Cart',
    'shopping cart': 'Shopping Cart',
    'luggage cart': 'Luggage Cart',
    'dolly': 'Hand Dolly',
    'candle holder': 'Candleholder',
    'incense': 'Incense Stick',
    'ashtray': 'Ashtray',
    'lighter': 'Lighter',
    'matchbox': 'Matchbox',
    'torch': 'Torch',
    'flashlight': 'Flashlight',
    'magnifying glass': 'Magnifying Glass',
    'binoculars': 'Binoculars',
    'telescope': 'Telescope',
    'microscope': 'Microscope',
    'globe': 'Globe',
    'trophy': 'Trophy',
    'medal': 'Medal',
    'certificate': 'Certificate',
    'diploma': 'Diploma',
    'flag': 'Flag',
    'map': 'Map',
    'compass tool': 'Compass',
    'lock combination': 'Combination Lock',
    'chain': 'Chain',
    'hook': 'Hook',
    'hinge': 'Hinge',
    'pulley': 'Pulley',
    'spring': 'Spring'
  };

  static const List<String> _priorityObjects = [
    'person',
    'people',
    'face',
    'child',
    'baby',
    'vehicle',
    'car',
    'truck',
    'bus',
    'motorcycle',
    'bicycle',
    'ambulance',
    'door',
    'stairs',
    'staircase',
    'escalator',
    'chair',
    'table',
    'desk',
    'obstacle',
    'wire',
    'cable',
    'knife',
    'scissors',
    'pole',
    'wall',
    'ramp',
    'pothole',
    'traffic cone',
    'bollard',
    'barrier',
    'fire extinguisher',
    'dog',
    'cat'
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

    for (final entry in _labelRefinements.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        if (entry.key.length >= 4) return entry.value;
      }
    }

    return rawLabel
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String? _geometricClassify(
      Rect box, double frameW, double frameH, List<String> ocrTokens) {
    if (frameW <= 0 || frameH <= 0) return null;
    final double ar = box.height / box.width.clamp(1.0, double.infinity);
    final double relArea = (box.width * box.height) / (frameW * frameH);
    final bool hasText = ocrTokens.isNotEmpty;

    final bool hasDateTokens = ocrTokens.any((t) => _isDateToken(t));
    if (hasDateTokens && relArea > 0.08 && ar > 0.8) return 'Calendar';

    if (ar > 1.15 && relArea > 0.07 && relArea < 0.95 && hasText) {
      if (ocrTokens.any((t) => t.length > 5 && !_isDateToken(t)))
        return 'Paper Document';
    }

    if (relArea > 0.20 && ar < 1.1 && hasText) {
      if (ocrTokens
          .any((t) => t.startsWith('•') || t.contains('₹') || t.contains('\$')))
        return 'Poster / Advertisement';
      return 'Notice Board';
    }

    if (ar < 0.75 && relArea > 0.25 && !hasText) return 'Screen / Monitor';

    if (ar > 1.2 && relArea > 0.05 && relArea < 0.50 && hasText) {
      if (ocrTokens.any((t) => RegExp(r'^\d{1,4}\$').hasMatch(t)))
        return 'Book';
    }
    return null;
  }

  bool _isDateToken(String t) {
    const months = {
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
      'jan',
      'feb',
      'mar',
      'apr',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec'
    };
    const days = {
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
      'mon',
      'tue',
      'wed',
      'thu',
      'fri',
      'sat',
      'sun'
    };
    final lower = t.toLowerCase();
    return months.contains(lower) ||
        days.contains(lower) ||
        RegExp(r'^20\d{2}\$').hasMatch(t);
  }

  String? _ocrDisambiguate(String currentLabel, List<String> tokens) {
    if (tokens.isEmpty) return null;
    final all = tokens.join(' ').toLowerCase();
    if (tokens.where((t) => _isDateToken(t)).length >= 2) return 'Calendar';
    if (all.contains('notice') ||
        all.contains('timetable') ||
        all.contains('schedule')) return 'Notice Board';
    if (all.contains('sale') || all.contains('price') || all.contains('₹'))
      return 'Poster / Advertisement';
    if (all.contains('dear') || all.contains('subject:'))
      return 'Letter / Document';
    if (all.contains('menu') || all.contains('beverage')) return 'Menu Card';
    if (all.contains('chapter') || all.contains('index')) return 'Book';
    return null;
  }

  String? _evidenceVote(String bucket, String candidateLabel) {
    final history = _evidenceBuffer.putIfAbsent(bucket, () => []);
    history.add(candidateLabel);
    if (history.length > _evidenceWindowSize) history.removeAt(0);
    final Map<String, int> votes = {};
    for (final lbl in history) votes[lbl] = (votes[lbl] ?? 0) + 1;
    String? winner;
    int maxVotes = 0;
    votes.forEach((l, v) {
      if (v > maxVotes) {
        maxVotes = v;
        winner = l;
      }
    });
    return (maxVotes >= _evidenceMinVotes) ? winner : null;
  }

  double _getConfidenceThreshold(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('person') ||
        lower.contains('vehicle') ||
        lower.contains('stairs') ||
        lower.contains('obstacle')) return 0.35;
    if (lower.contains('paper') ||
        lower.contains('calendar') ||
        lower.contains('book')) return 0.50;
    return 0.40;
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

      _processOcrTokensOnly(inputImage);

      if (_isOcrEnabled) {
        await _processOcr(inputImage);
      } else {
        final results = await Future.wait([
          _objectDetector.processImage(inputImage),
          _imageLabeler.processImage(inputImage),
        ]);
        _handleVisionResults(
            results[0] as List<DetectedObject>, results[1] as List<ImageLabel>);
      }
    } catch (e) {
      _error = 'Detection error: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _processOcrTokensOnly(InputImage inputImage) {
    _textRecognizer.processImage(inputImage).then((result) {
      final List<String> tokens = [];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            tokens.addAll(line.text.trim().split(RegExp(r'\s+')));
          }
        }
      }
      if (tokens.isNotEmpty) _lastOcrTokens = tokens;
    }).catchError((_) {});
  }

  void _handleVisionResults(
      List<DetectedObject> objects, List<ImageLabel> imageLabels) {
    List<AppDetectedObject> newDetections = [];
    final Set<String> addedLabels = {};

    final List<MapEntry<String, double>> sceneCandidates = [];
    for (final label in imageLabels) {
      final refined = _refineLabel(label.label);
      if (refined.isEmpty) continue;
      if (label.confidence < _getConfidenceThreshold(refined)) continue;
      sceneCandidates.add(MapEntry(refined, label.confidence));
    }

    // ── LAYER 1 object candidates ───────────────────────────────────────────
    for (final obj in objects) {
      final spatialLoc =
          _getSpatialLocation(obj.boundingBox, _lastImageWidth.toDouble());
      final distanceLevel = _estimateDistance(obj.boundingBox);

      String candidateLabel = 'Obstacle';
      double confidence = 0.50;

      if (obj.labels.isNotEmpty) {
        final best = (List.of(obj.labels)
              ..sort((a, b) => b.confidence.compareTo(a.confidence)))
            .first;
        final refined = _refineLabel(best.text);
        if (refined.isNotEmpty &&
            best.confidence >= _getConfidenceThreshold(refined)) {
          candidateLabel = refined;
          confidence = best.confidence;
        }
      }

      String finalLabel = _geometricClassify(
            obj.boundingBox,
            _lastImageWidth.toDouble(),
            _lastImageHeight.toDouble(),
            _lastOcrTokens,
          ) ??
          _ocrDisambiguate(candidateLabel, _lastOcrTokens) ??
          candidateLabel;

      final voted = _evidenceVote(spatialLoc, finalLabel);
      if (voted != null) finalLabel = voted;

      final lowerFinal = finalLabel.toLowerCase();

      if (lowerFinal == 'laptop' && addedLabels.contains('computer mouse'))
        continue;
      if ((lowerFinal == 'monitor' || lowerFinal == 'television') &&
          (addedLabels.contains('laptop'))) continue;

      if (!addedLabels.contains(lowerFinal)) {
        addedLabels.add(lowerFinal);
        newDetections.add(AppDetectedObject(
          label: finalLabel,
          confidence: confidence,
          boundingBox: obj.boundingBox,
          detectedAt: DateTime.now(),
          distanceLevel: distanceLevel,
          spatialLocation: spatialLoc,
        ));
      }
    }

    for (final entry in sceneCandidates) {
      final lower = entry.key.toLowerCase();
      if (addedLabels.contains(lower)) continue;
      final voted = _evidenceVote('scene_$lower', entry.key);
      if (voted == null) continue;

      addedLabels.add(lower);
      newDetections.add(AppDetectedObject(
        label: entry.key,
        confidence: entry.value,
        boundingBox: null,
        detectedAt: DateTime.now(),
        distanceLevel: DistanceLevel.medium,
        spatialLocation: 'in the scene',
      ));
    }

    bool hasScreen = newDetections
        .any((d) => ['Monitor', 'Screen', 'Television'].contains(d.label));
    bool hasKeyboard = newDetections.any(
        (d) => d.label.contains('Keyboard') || d.label.contains('Computer'));
    if (hasScreen && hasKeyboard) {
      newDetections.removeWhere((d) => [
            'Monitor',
            'Screen',
            'Television',
            'Keyboard',
            'Computer Keyboard'
          ].contains(d.label));
      newDetections.add(AppDetectedObject(
        label: 'Laptop Workspace',
        confidence: 0.9,
        boundingBox: objects.isNotEmpty ? objects.first.boundingBox : null,
        detectedAt: DateTime.now(),
        distanceLevel: DistanceLevel.medium,
        spatialLocation: 'in front of you',
      ));
    }

    newDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
    _currentDetections =
        newDetections.length > 8 ? newDetections.sublist(0, 8) : newDetections;

    if (onNewDetection != null) onNewDetection!(_currentDetections);
    _handleSmartAnnouncement(_currentDetections);
  }

  String _getSpatialLocation(Rect boundingBox, double imageWidth) {
    final centerX = boundingBox.center.dx;
    final third = imageWidth / 3;
    if (centerX < third)
      return 'on your left';
    else if (centerX < 2 * third)
      return 'directly in front of you';
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

      String newlyDetectedText = "";
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().length > 2) {
            newlyDetectedText += "${line.text} ";
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

      if (newlyDetectedText.trim().isNotEmpty) {
        final text = newlyDetectedText.trim();
        if (!_ocrTextBuffer
            .any((stored) => stored.contains(text) || text.contains(stored))) {
          _ocrTextBuffer.add(text);
        }

        final lower = text.toLowerCase();
        if (lower.contains('notice') ||
            lower.contains('appointment') ||
            lower.contains('schedule')) {
          if (!_isDeepScanning) {
            _isDeepScanning = true;
            onSpeakText?.call(
                "I've detected a Notice Board. I am performing a deep scan of the contents. Please keep the camera steady.");
          }
        }

        _ocrAnalysisTimer?.cancel();
        final duration = _isDeepScanning
            ? const Duration(seconds: 10)
            : const Duration(seconds: 4);
        _ocrAnalysisTimer = Timer(duration, () {
          _analyzeAndSpeakOcr();
        });
      }
    } catch (e) {
      debugPrint('OCR error: $e');
    }
  }

  void _analyzeAndSpeakOcr() {
    if (onSpeakText == null || _ocrTextBuffer.isEmpty) return;

    final String fullText = _ocrTextBuffer.join('. ');
    final String lowerText = fullText.toLowerCase();

    String header = "I've analyzed the text. ";

    if (_isDeepScanning) {
      header =
          "I've finished the deep scan of this notice board. Here is a summary of what I found: ";
    } else if (lowerText.contains('menu') ||
        lowerText.contains('₹') ||
        lowerText.contains('\$')) {
      header = "I see a menu or pricing list. The items mentioned are: ";
    } else if (lowerText.contains('warning') || lowerText.contains('caution')) {
      header = "Important warning detected! The sign says: ";
    } else if (fullText.length > 100) {
      header =
          "I'm reading a document or large block of text. It starts with: ";
    }

    final cleanText = fullText
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    onSpeakText!("$header $cleanText");

    // Reset state
    _ocrTextBuffer.clear();
    _isDeepScanning = false;
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
          ? const Duration(seconds: 4)
          : const Duration(seconds: 8);
      if (elapsed < minInterval) return false;
    }
    return true;
  }

  Future<void> _announceObject(AppDetectedObject detection) async {
    final now = DateTime.now();
    _lastAnnouncedObjects[detection.label] = now;
    _recentlyAnnouncedObjects.add(detection.label);

    Future.delayed(const Duration(seconds: 6),
        () => _recentlyAnnouncedObjects.remove(detection.label));

    String alertPrefix =
        _isPriorityObject(detection.label) ? "Watch out, " : "I see a ";
    final message =
        '$alertPrefix${detection.label} ${detection.spatialLocation}. It is ${detection.distanceDescription}.';

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
    if (_isOcrEnabled) _ocrTextBuffer.clear();
    notifyListeners();
  }

  void clearRecentAnnouncements() {
    _recentlyAnnouncedObjects.clear();
    _lastAnnouncedObjects.clear();
  }

  Future<void> describeSurroundings() async {
    clearRecentAnnouncements();
    if (_currentDetections.isEmpty) {
      if (onSpeakText != null)
        onSpeakText!(
            'I cannot see anything clear right now. Try shifting the camera.');
      return;
    }
    final labels = _currentDetections.map((d) => d.label).toList();
    final description = _onDeviceAI.describeScene(labels);
    if (onSpeakText != null) onSpeakText!(description);
  }

  @override
  void dispose() {
    _ocrAnalysisTimer?.cancel();
    _objectDetector.close();
    _imageLabeler.close();
    _textRecognizer.close();
    super.dispose();
  }
}
