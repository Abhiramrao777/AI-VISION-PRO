/// On-device scene description service.
///
/// All AI processing happens locally on the device — no cloud API calls,
/// no internet required. Scene descriptions are built from ML Kit detections.
class OnDeviceAIService {
  /// Build a natural-language scene description from the current detections.
  ///
  /// This replaces the previous cloud-based NVIDIA API call with a purely
  /// on-device summary assembled from ML Kit object-detection and image-
  /// labeling results, keeping all data private and latency minimal.
  String describeScene(List<String> detectedLabels) {
    if (detectedLabels.isEmpty) {
      return 'I cannot identify any objects right now. Try pointing the camera in a different direction.';
    }

    final buffer = StringBuffer('I can see ');
    final unique = detectedLabels.toSet().toList();

    if (unique.length == 1) {
      buffer.write('${unique.first}.');
    } else if (unique.length == 2) {
      buffer.write('${unique[0]} and ${unique[1]}.');
    } else {
      for (int i = 0; i < unique.length; i++) {
        if (i == unique.length - 1) {
          buffer.write('and ${unique[i]}.');
        } else {
          buffer.write('${unique[i]}, ');
        }
      }
    }

    return buffer.toString();
  }
}
