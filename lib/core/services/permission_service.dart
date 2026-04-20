import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static Future<void> initialize() async {
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestAllPermissions() async {
    return (await [
      Permission.camera,
      Permission.microphone,
    ].request()).values.every((s) => s.isGranted);
  }

  static Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }

  String getPermissionMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied. Please grant permission to continue.';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable in app settings.';
      case PermissionStatus.restricted:
        return 'Permission restricted by device policy.';
      case PermissionStatus.limited:
        return 'Permission limited.';
      case PermissionStatus.provisional:
        return 'Permission provisional.';
    }
  }
}
