class OnDeviceAIService {
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
