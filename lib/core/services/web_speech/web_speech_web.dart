import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('startSpeechRecognition')
external bool _jsStartSpeech(
  JSString language,
  JSFunction onResult,
  JSFunction onError,
  JSFunction onEnd,
);

@JS('stopSpeechRecognition')
external JSString _jsStopSpeech();

@JS('getSpeechTranscript')
external JSString _jsGetSpeechTranscript();

@JS('startNativeAudioRecording')
external JSPromise<JSBoolean> _jsStartNativeAudio();

@JS('stopNativeAudioRecording')
external JSPromise<JSString> _jsStopNativeAudio();

@JS('downloadImageBlob')
external bool _jsDownloadImageBlob(
  JSString base64Data,
  JSString filename,
  JSString mimeType,
);

class WebSpeechBridge {
  static bool get isSupported => true;

  static bool start({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    void Function(String error)? onError,
    void Function()? onEnd,
  }) {
    try {
      final onResultFn = ((JSString text, JSBoolean isFinal) {
        onResult(text.toDart, isFinal.toDart);
      }).toJS;

      final onErrorFn = ((JSString err) {
        onError?.call(err.toDart);
      }).toJS;

      final onEndFn = (() {
        onEnd?.call();
      }).toJS;

      return _jsStartSpeech(
        language.toJS,
        onResultFn,
        onErrorFn,
        onEndFn,
      );
    } catch (_) {
      return false;
    }
  }

  static String stop() {
    try {
      final res = _jsStopSpeech();
      return res.toDart;
    } catch (_) {
      return '';
    }
  }

  static String getSpeechTranscript() {
    try {
      final res = _jsGetSpeechTranscript();
      return res.toDart;
    } catch (_) {
      return '';
    }
  }

  static Future<bool> startNativeAudio() async {
    try {
      final promise = _jsStartNativeAudio();
      final res = await promise.toDart;
      return res.toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> stopNativeAudio() async {
    try {
      final promise = _jsStopNativeAudio();
      final res = await promise.toDart;
      final b64 = res.toDart;
      if (b64.isNotEmpty) {
        return base64Decode(b64);
      }
    } catch (_) {}
    return null;
  }

  static bool downloadImage({
    required String base64Data,
    required String filename,
    String mimeType = 'image/png',
  }) {
    try {
      return _jsDownloadImageBlob(base64Data.toJS, filename.toJS, mimeType.toJS);
    } catch (_) {
      return false;
    }
  }
}
