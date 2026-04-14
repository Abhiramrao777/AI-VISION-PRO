# AI VISION PRO

An AI-powered assistive application designed to help blind and visually impaired users navigate their environment using real-time object detection, text recognition, and audio feedback.

## Features

### Core Features
- **Real-time Object Detection**: Uses Google ML Kit Image Labeling to detect objects in the camera feed
- **Text Recognition (OCR)**: Read signs, labels, and text aloud
- **Text-to-Speech**: Announces detected objects with distance estimation
- **Haptic Feedback**: Vibrates when objects are detected (stronger for priority objects)
- **Voice Commands**: Control the app hands-free

### Smart Features
- **Smart Object Announcer**: Avoids repetition by tracking recently announced objects
- **Distance Awareness**: Estimates if objects are close, medium, or far based on bounding box size
- **Obstacle Priority Mode**: Prioritizes critical obstacles like people and vehicles
- **Emergency Alert Button**: Long-press to activate emergency alert with strong vibration

### Accessibility Features
- High contrast mode
- Large text support
- Voice-guided navigation
- Screen reader compatible (Semantics labels)
- Large touch targets

## Voice Commands

Say these commands to control the app:
- "Start scanning" - Begin object detection
- "Stop" - Stop scanning
- "Read text" - Enable OCR mode
- "What is around me?" - Describe surroundings
- "Emergency" / "Help" - Activate emergency alert

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── services/
│   │   └── permission_service.dart    # Permission handling
│   └── utils/
├── features/
│   ├── camera/
│   │   └── camera_provider.dart       # Camera management
│   ├── detection/
│   │   └── detection_provider.dart    # ML inference pipeline
│   ├── tts/
│   │   └── tts_provider.dart          # Text-to-speech
│   ├── vibration/
│   │   └── vibration_provider.dart    # Haptic feedback
│   ├── voice_command/
│   │   └── voice_command_provider.dart # Voice recognition
│   └── accessibility/
│       └── accessibility_provider.dart # Accessibility settings
└── ui/
    ├── screens/
    │   ├── home_screen.dart           # Main screen
    │   ├── camera_preview_screen.dart  # Camera view with overlay
    │   └── settings_screen.dart        # Settings page
    └── widgets/

android/
├── app/
│   ├── src/main/
│   │   ├── AndroidManifest.xml        # Permissions & config
│   │   ├── kotlin/.../MainActivity.kt
│   │   └── res/                       # Resources
│   ├── build.gradle                   # Android build config
│   └── proguard-rules.pro
└── build.gradle
```

## Requirements

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android minSdkVersion 24
- Android device with camera

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ai_vision_pro
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Configuration

### Android Permissions

The app requires the following permissions (automatically requested at runtime):
- CAMERA: For capturing video frames
- RECORD_AUDIO: For voice commands
- VIBRATE: For haptic feedback

### Build Configuration

Edit `android/app/build.gradle` to modify:
- `minSdkVersion`: Minimum Android version (default: 24)
- `targetSdkVersion`: Target Android version (default: 34)
- `applicationId`: Your app's unique identifier

## Performance Optimization

The app implements several optimizations:
- **Frame Throttling**: Processes 1 frame every 300ms to prevent overload
- **Confidence Threshold**: Only reports detections with ≥60% confidence
- **Duplicate Suppression**: Avoids repeating the same object within 3-5 seconds
- **Priority Processing**: Critical objects (people, vehicles) are announced first

## Troubleshooting

### Camera not working
- Ensure camera permission is granted
- Check that the device has a working camera
- Try restarting the app

### No object detection
- Ensure good lighting conditions
- Point camera at objects clearly
- Wait a moment for ML Kit to initialize models

### TTS not speaking
- Check device volume settings
- Ensure TTS engine is installed on device
- Try changing speech rate in settings

### Voice commands not working
- Grant microphone permission
- Speak clearly in a quiet environment
- Check microphone is not muted

## License

This project is provided as-is for educational and assistive purposes.

## Support

For issues and feature requests, please open an issue on the project repository.
