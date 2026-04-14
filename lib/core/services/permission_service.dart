import 'package:permission_handler/permission_handler.dart';

/// Service to handle all permission requests for the app
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static Future<void> initialize() async {
    // Permissions are requested on-demand
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request microphone permission for voice commands
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request all required permissions at once
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  /// Open app settings if permission is denied
  static Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }

  /// Get user-friendly message for permission status
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
