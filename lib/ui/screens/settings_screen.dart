import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_vision_pro/features/tts/tts_provider.dart';
import 'package:ai_vision_pro/features/vibration/vibration_provider.dart';
import 'package:ai_vision_pro/features/accessibility/accessibility_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Accessibility'),
          SwitchListTile(
            title: const Text('High Contrast Mode'),
            subtitle: const Text('Increase contrast for better visibility'),
            value: accessibilityProvider.isHighContrastMode,
            onChanged: (_) => accessibilityProvider.toggleHighContrast(),
          ),
          SwitchListTile(
            title: const Text('Large Text'),
            subtitle: const Text('Increase text size'),
            value: accessibilityProvider.isLargeTextMode,
            onChanged: (_) => accessibilityProvider.toggleLargeText(),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Slider(
              value: accessibilityProvider.textScaleFactor,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${accessibilityProvider.textScaleFactor.toStringAsFixed(1)}x',
              onChanged: (value) => accessibilityProvider.setTextScaleFactor(value),
            ),
          ),
          SwitchListTile(
            title: const Text('Voice Guidance'),
            subtitle: const Text('Announce detected objects'),
            value: accessibilityProvider.isVoiceGuidanceEnabled,
            onChanged: (_) => accessibilityProvider.toggleVoiceGuidance(),
          ),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on detection'),
            value: accessibilityProvider.isHapticFeedbackEnabled,
            onChanged: (_) => accessibilityProvider.toggleHapticFeedback(),
          ),
          const Divider(),
          _buildTtsSettings(context),
          const Divider(),
          _buildVibrationSettings(context),
          const Divider(),
          _buildSectionHeader('Actions'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset to Defaults'),
            onTap: () {
              accessibilityProvider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About AI VISION PRO'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildTtsSettings(BuildContext context) {
    final ttsProvider = context.watch<TTSProvider>();
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Text-to-Speech'),
        ListTile(
          title: const Text('Speech Rate'),
          subtitle: Slider(
            value: ttsProvider.speechRate,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: ttsProvider.speechRate.toStringAsFixed(1),
            onChanged: (value) => ttsProvider.setSpeechRate(value),
          ),
        ),
        ListTile(
          title: const Text('Pitch'),
          subtitle: Slider(
            value: ttsProvider.pitch,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: ttsProvider.pitch.toStringAsFixed(1),
            onChanged: (value) => ttsProvider.setPitch(value),
          ),
        ),
        ListTile(
          title: const Text('Volume'),
          subtitle: Slider(
            value: ttsProvider.volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: ttsProvider.volume.toStringAsFixed(1),
            onChanged: (value) => ttsProvider.setVolume(value),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.volume_up),
          title: const Text('Test Speech'),
          subtitle: Text(
            'Rate: ${ttsProvider.speechRate.toStringAsFixed(1)}, Pitch: ${ttsProvider.pitch.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 12 * accessibilityProvider.textScaleFactor),
          ),
          onTap: () => ttsProvider.speak('This is a test of the text to speech system.'),
        ),
      ],
    );
  }

  Widget _buildVibrationSettings(BuildContext context) {
    final vibrationProvider = context.watch<VibrationProvider>();
    final accessibilityProvider = context.watch<AccessibilityProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Vibration'),
        ListTile(
          leading: const Icon(Icons.vibration),
          title: Text(
            vibrationProvider.hasVibrator ? 'Vibrator Available' : 'No Vibrator',
            style: TextStyle(fontSize: 14 * accessibilityProvider.textScaleFactor),
          ),
          subtitle: Text(
            vibrationProvider.isVibrationEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(fontSize: 12 * accessibilityProvider.textScaleFactor),
          ),
          trailing: Switch(
            value: vibrationProvider.isVibrationEnabled,
            onChanged: (_) => vibrationProvider.toggleVibration(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.touch_app),
          title: const Text('Test Vibration'),
          onTap: () => vibrationProvider.vibrateForButtonPress(),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AI VISION PRO'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 16),
            Text('AI VISION PRO is an AI-powered assistive application designed to help blind and visually impaired users navigate their environment.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Real-time object detection'),
            Text('• Text recognition (OCR)'),
            Text('• Voice commands'),
            Text('• Text-to-speech announcements'),
            Text('• Haptic feedback'),
            Text('• Emergency alert button'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }
}