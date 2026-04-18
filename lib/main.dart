import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_vision_pro/core/services/permission_service.dart';
import 'package:ai_vision_pro/features/camera/camera_provider.dart';
import 'package:ai_vision_pro/features/detection/detection_provider.dart';
import 'package:ai_vision_pro/features/tts/tts_provider.dart';
import 'package:ai_vision_pro/features/vibration/vibration_provider.dart';
import 'package:ai_vision_pro/features/voice_command/voice_command_provider.dart';
import 'package:ai_vision_pro/features/accessibility/accessibility_provider.dart';
import 'package:ai_vision_pro/features/emergency/emergency_provider.dart';
import 'package:ai_vision_pro/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionService.initialize();
  runApp(const AIVisionProApp());
}

class AIVisionProApp extends StatelessWidget {
  const AIVisionProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
        ChangeNotifierProvider(create: (_) => TTSProvider()),
        ChangeNotifierProvider(create: (_) => VibrationProvider()),
        ChangeNotifierProvider(create: (_) => VoiceCommandProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        title: 'AI VISION PRO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 32,
          ),
        ),
        highContrastTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.yellow,
          scaffoldBackgroundColor: Colors.black,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white, fontSize: 20),
            bodyMedium: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
