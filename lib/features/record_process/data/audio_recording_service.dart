import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

class AudioRecordingService {
  AudioRecordingService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  StreamSubscription<Uint8List>? _recordSub;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return true;
    }
  }

  /// Starts recording audio to file / memory blob.
  Future<bool> startRecordingToFile({String? path}) async {
    try {
      final permitted = await hasPermission();
      if (!permitted) return false;

      const config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: kIsWeb ? 48000 : 44100,
        bitRate: 128000,
      );

      await _recorder.start(config, path: path ?? '');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stops recording and returns the raw audio bytes directly.
  Future<Uint8List?> stopAndGetBytes() async {
    try {
      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        if (path != null && path.isNotEmpty) {
          final xfile = XFile(path);
          final bytes = await xfile.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Starts recording and returns a stream of PCM audio chunks (for voice agent).
  Future<Stream<Uint8List>?> startStream() async {
    try {
      final permitted = await hasPermission();
      if (!permitted) return null;

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _recorder.startStream(config);
      return stream;
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() async {
    try {
      await _recordSub?.cancel();
      _recordSub = null;
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
  }

  void dispose() {
    _recorder.dispose();
  }
}
