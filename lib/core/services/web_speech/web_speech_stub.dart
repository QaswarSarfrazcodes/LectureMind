import 'dart:typed_data';

class WebSpeechBridge {
  static bool get isSupported => false;

  static bool start({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    void Function(String error)? onError,
    void Function()? onEnd,
  }) =>
      false;

  static String stop() => '';

  static String getSpeechTranscript() => '';

  static Future<bool> startNativeAudio() async => false;

  static Future<Uint8List?> stopNativeAudio() async => null;

  static bool downloadImage({
    required String base64Data,
    required String filename,
    String mimeType = 'image/png',
  }) =>
      false;
}
