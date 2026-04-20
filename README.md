# AI VISION PRO

An advanced AI-powered assistive application designed to help blind and visually impaired users navigate their environment using real-time object detection, intelligent text recognition, and conversational audio feedback.

## Features

### Core Features
- **Real-time Object Detection:** Uses Google ML Kit Image Labeling to detect objects in the camera feed.
- **Dynamic Object Tracking & Counters:** Identifies multiple instances of the same object, groups them, and draws dynamic highlighting rectangles with live counters (e.g., "Chair (3) 85%").
- **Smart Text Recognition (OCR):** Reads signs, labels, and text aloud using a smart buffering system that groups text over intervals to understand full paragraphs and contexts.
- **Manual & Auto Focus:** Automatically adjusts focus, or allows the user to manually focus and expose by tapping anywhere on the screen.
- **Text-to-Speech (TTS):** Announces detected objects with distance estimation using a conversational, human-like interaction style.
- **Haptic Feedback:** Vibrates when objects are detected, dynamically adjusting pattern and intensity based on object proximity and priority.
- **Voice Commands:** Control the app entirely hands-free.

### Smart AI Features
- **AI Contextual Correction:** Fixes common ML misclassifications by analyzing the scene context (e.g., correctly identifying a "Laptop" instead of a "Television" when a keyboard is present, or "Computer Keyboard" instead of "Musical Instrument").
- **Context-Aware OCR:** Analyzes recognized text locally (without external APIs) to intelligently announce contexts like "This looks like a notice board..." or "This appears to be a menu...".
- **Smart Object Announcer:** Avoids spamming the user by tracking recently announced objects and gracefully pacing the audio cues.
- **Distance Awareness:** Estimates if objects are close, medium, or far based on real-time bounding box scaling and screen area ratios.
- **Obstacle Priority Mode:** Prioritizes critical obstacles like people, vehicles, and walls for immediate announcement.
- **Stable Emergency Alert:** Long-press or use voice commands to activate a guarded emergency SOS mode with flashing torchlights and strong haptic alerts.

## Voice Commands

Say these commands to control the app hands-free:
- **"Start scanning"** - Begin object detection
- **"Stop" / "Pause"** - Stop scanning and close the camera
- **"Read text"** - Enable OCR mode for reading signs and documents
- **"What is around me?"** - Provide a conversational description of your surroundings
- **"Emergency" / "Help"** - Activate emergency SOS alert

## Project Structure

```text
lib/
├── main.dart                  # App entry point
├── core/
│   ├── services/
│   │   └── permission_service.dart    # Permission handling
│   └── utils/
├── features/
│   ├── camera/
│   │   └── camera_provider.dart       # Camera management & Tap-to-Focus
│   ├── detection/
│   │   └── detection_provider.dart    # ML inference, AI context & OCR Buffering
│   ├── tts/
│   │   └── tts_provider.dart          # Conversational Text-to-speech
│   ├── vibration/
│   │   └── vibration_provider.dart    # Custom Haptic feedback
│   ├── voice_command/
│   │   └── voice_command_provider.dart# Voice recognition
│   └── accessibility/
│       └── accessibility_provider.dart# Accessibility settings
└── ui/
    ├── screens/
    │   ├── home_screen.dart           # Main screen
    │   ├── camera_preview_screen.dart # Camera view with bounding boxes & counters
    │   └── settings_screen.dart       # Settings page
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
- Flutter SDK >= 3.2.3 < 4.0.0
- Dart SDK >= 3.0.0
- Android minSdkVersion 24
- Android targetSdkVersion 34
- Android device with camera

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ai_vision_pro
```

2. Clean and Install dependencies:
```bash
flutter clean
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Configuration

### Android Permissions
The app requires the following permissions (automatically requested at runtime):
- **CAMERA:** For capturing video frames and tap-to-focus.
- **RECORD_AUDIO:** For voice commands and speech-to-text.
- **VIBRATE:** For custom haptic feedback and emergency alerts.

### Build Configuration
Edit `android/app/build.gradle` to modify:
- `minSdkVersion`: Minimum Android version (default: 24)
- `targetSdkVersion`: Target Android version (default: 34)
- `applicationId`: Your app's unique identifier

## Performance Optimization
The app implements several heavy optimizations to run smoothly on edge devices:
- **Smart OCR Buffering:** Groups text over 3-second intervals to form complete paragraphs before speaking, heavily reducing TTS interruptions.
- **Contextual Label Mapping:** Uses local Map and Set heuristics to instantly refine AI labels without hitting an external API.
- **Frame Throttling:** Processes 1 frame every 300ms to prevent CPU overload and thermal throttling.
- **Dynamic State Rendering:** Bounding boxes and labels are drawn using highly optimized CustomPainter canvases.
- **Duplicate Suppression:** Tracks objects by timestamp and semantic label to avoid repeating the same object within 4-8 seconds.

## Troubleshooting

### Camera not working / Blank Screen
- Ensure camera permission is granted in Android settings.
- Check that the device has a working rear-facing camera.
- Tap the screen to force a manual focus refresh.

### Incorrect AI Predictions (e.g., TV instead of Laptop)
- The app uses contextual AI. Try to ensure the entire workspace (like the keyboard and screen together) is in the frame to allow the AI to correct itself.
- Ensure good lighting conditions.

### OCR Not Reading Sentences Properly
- Hold the camera steady for at least 3 seconds. The app uses a smart buffer to group words into full sentences before speaking.

### Voice commands not working
- Grant microphone permission.
- Speak clearly in a quiet environment.

## License
This project is provided as-is for educational and assistive purposes.

## Support
For issues and feature requests, please open an issue on the project repository.