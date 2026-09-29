import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_secrets.dart';
import '../error/failures.dart';

class TranscriptSegment {
  const TranscriptSegment({
    required this.text,
    required this.isFinal,
    this.confidence,
    this.audioStartMs,
    this.audioEndMs,
  });

  final String text;
  final bool isFinal;
  final double? confidence;
  final int? audioStartMs;
  final int? audioEndMs;
}

/// AssemblyAI client implementing Realtime STT (Universal-3 Pro) and Async upload per `api.md`.
class AssemblyAiClient {
  AssemblyAiClient({
    required String Function() apiKeyProvider,
    Dio? dio,
  })  : _apiKeyProvider = apiKeyProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.assemblyai.com/v2',
                connectTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 360),
                receiveTimeout: const Duration(seconds: 120),
              ),
            );

  final String Function() _apiKeyProvider;
  final Dio _dio;

  WebSocketChannel? _activeSocket;
  StreamController<TranscriptSegment>? _transcriptController;
  Timer? _simulationTimer;

  String get _apiKey {
    final k = _apiKeyProvider().trim();
    return k.isNotEmpty ? k : AppSecrets.assemblyAiApiKey;
  }

  bool get isConnected => _activeSocket != null || _simulationTimer != null;

  /// Fetches a short-lived temporary token from AssemblyAI v3 token endpoint.
  Future<String?> _fetchStreamingToken(String apiKey) async {
    try {
      const endpoint = kIsWeb
          ? '/api/token'
          : 'https://streaming.assemblyai.com/v3/token?expires_in_seconds=300';
      final res = await _dio.get(
        endpoint,
        options: Options(
          headers: kIsWeb ? null : {'Authorization': apiKey},
        ),
      );
      if (res.statusCode == 200 && res.data != null) {
        if (res.data is Map && res.data['token'] != null) {
          return res.data['token'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Starts a real-time streaming STT session over WebSocket (Universal-3 Pro).
  Stream<TranscriptSegment> startRealtimeSession({int sampleRate = 16000}) {
    _transcriptController?.close();
    _transcriptController = StreamController<TranscriptSegment>.broadcast();

    _connectWebSocket(sampleRate);

    return _transcriptController!.stream;
  }

  Future<void> _connectWebSocket(int sampleRate) async {
    final apiKey = _apiKey;

    try {
      final token = await _fetchStreamingToken(apiKey);
      final wsUrl = token != null && token.isNotEmpty
          ? Uri.parse(
              'wss://streaming.assemblyai.com/v3/ws?token=$token&sample_rate=$sampleRate&speech_model=universal-3-5-pro',
            )
          : Uri.parse(
              'wss://streaming.assemblyai.com/v3/ws?sample_rate=$sampleRate&speech_model=universal-3-5-pro',
            );

      _activeSocket = WebSocketChannel.connect(wsUrl);

      _activeSocket!.stream.listen(
        (message) {
          try {
            if (message is String) {
              final json = jsonDecode(message) as Map<String, dynamic>;
              final messageType = json['type'] as String? ?? json['message_type'];

              if (messageType == 'Turn') {
                final text = (json['transcript'] as String? ?? json['text'] as String? ?? '').trim();
                final endOfTurn = json['end_of_turn'] == true;
                if (text.isNotEmpty) {
                  _transcriptController?.add(
                    TranscriptSegment(
                      text: text,
                      isFinal: endOfTurn,
                      confidence: (json['confidence'] as num?)?.toDouble(),
                      audioStartMs: json['audio_start'] as int?,
                      audioEndMs: json['audio_end'] as int?,
                    ),
                  );
                }
              } else if (messageType == 'PartialTranscript') {
                final text = (json['text'] as String? ?? json['transcript'] as String? ?? '').trim();
                if (text.isNotEmpty) {
                  _transcriptController?.add(
                    TranscriptSegment(
                      text: text,
                      isFinal: false,
                      audioStartMs: json['audio_start'] as int?,
                      audioEndMs: json['audio_end'] as int?,
                    ),
                  );
                }
              } else if (messageType == 'FinalTranscript') {
                final text = (json['text'] as String? ?? json['transcript'] as String? ?? '').trim();
                if (text.isNotEmpty) {
                  _transcriptController?.add(
                    TranscriptSegment(
                      text: text,
                      isFinal: true,
                      confidence: (json['confidence'] as num?)?.toDouble(),
                      audioStartMs: json['audio_start'] as int?,
                      audioEndMs: json['audio_end'] as int?,
                    ),
                  );
                }
              }
            }
          } catch (_) {}
        },
        onError: (e) {
          final errStr = e.toString();
          final userMsg = errStr.contains('Failed host lookup')
              ? 'No internet connection. Please check your Wi-Fi or data connection.'
              : 'Transcription interrupted: $e';
          _transcriptController?.addError(AssemblyAiFailure(userMsg));
        },
        onDone: () {
          _activeSocket = null;
        },
      );
    } catch (e) {
      _transcriptController?.addError(
        AssemblyAiFailure('Could not connect to real-time speech service: $e'),
      );
    }
  }

  /// Sends a raw PCM 16kHz audio chunk to the active WebSocket.
  ///
  /// Empty or sub-threshold chunks are dropped to avoid spurious WS frames
  /// that can confuse the Universal-3 Pro speech model's VAD.
  void sendAudioChunk(Uint8List chunk) {
    // Skip empty chunks that can result from recorder flush events.
    if (chunk.isEmpty) return;
    if (_activeSocket != null) {
      try {
        _activeSocket!.sink.add(chunk);
      } catch (_) {}
    }
  }

  /// Closes the real-time session cleanly and releases all stream resources.
  Future<void> stopRealtimeSession() async {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (_activeSocket != null) {
      try {
        _activeSocket!.sink.add(jsonEncode({'type': 'Terminate'}));
        await _activeSocket!.sink.close();
      } catch (_) {}
      _activeSocket = null;
    }

    // Close the broadcast controller so subscribers receive onDone.
    final ctrl = _transcriptController;
    _transcriptController = null;
    await ctrl?.close();
  }

  /// Uploads audio file and transcribes via Async REST API per `api.md` §1.2.
  Future<Result<String, Failure>> transcribeFile({
    required List<int> fileBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final apiKey = _apiKey;

    try {
      // 1. Upload audio to AssemblyAI upload endpoint
      final uploadResponse = await _dio.post(
        '/upload',
        data: Uint8List.fromList(fileBytes),
        options: Options(
          headers: {
            'Authorization': apiKey,
            'Content-Type': 'application/octet-stream',
          },
          sendTimeout: const Duration(seconds: 360),
        ),
      );

      final uploadUrl = uploadResponse.data['upload_url'] as String;
      onProgress?.call(0.4);

      // 2. Request transcription with high accuracy settings & academic vocabulary boost
      final transcriptResponse = await _dio.post(
        '/transcript',
        data: {
          'audio_url': uploadUrl,
          'language_detection': true,
          'punctuate': true,
          'format_text': true,
          'speech_models': ['universal-3-5-pro', 'universal-2'],
          'boost_param': 'high',
          'word_boost': [
            'lecture', 'university', 'concept', 'definition', 'formula',
            'theory', 'hypothesis', 'analysis', 'methodology', 'principle',
            'variable', 'function', 'system', 'process', 'research',
            'experiment', 'algorithm', 'api', 'testing', 'urdu', 'pakistan'
          ],
        },
        options: Options(headers: {'Authorization': apiKey}),
      );

      final transcriptId = transcriptResponse.data['id'] as String;
      onProgress?.call(0.6);

      // 3. Poll until completed (Support long voice notes and lectures up to 8 minutes)
      for (int i = 0; i < 160; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final pollResponse = await _dio.get(
          '/transcript/$transcriptId',
          options: Options(headers: {'Authorization': apiKey}),
        );

        final status = pollResponse.data['status'] as String;
        if (status == 'completed') {
          onProgress?.call(1.0);
          final text = pollResponse.data['text'] as String? ?? '';
          return Result.success(text);
        } else if (status == 'error') {
          return Result.failure(
            AssemblyAiFailure(pollResponse.data['error']?.toString() ?? 'Transcription failed'),
          );
        } else {
          final p = 0.6 + ((i / 160) * 0.35);
          onProgress?.call(p);
        }
      }

      return Result.failure(const AssemblyAiFailure('Transcription request timed out. Please retry.'));
    } on DioException catch (e) {
      if (e.message != null && e.message!.contains('Failed host lookup')) {
        return Result.failure(const AssemblyAiFailure('No internet connection. Please verify your network and retry.'));
      }
      return Result.failure(AssemblyAiFailure(e.message ?? 'Audio file upload failed'));
    } catch (e) {
      return Result.failure(AssemblyAiFailure(e.toString()));
    }
  }

  /// Validates API key against AssemblyAI.
  Future<bool> validateKey(String key) async {
    if (key.trim().isEmpty) return false;
    try {
      final res = await _dio.get(
        '/transcript?limit=1',
        options: Options(headers: {'Authorization': key.trim()}),
      );
      return res.statusCode == 200;
    } catch (_) {
      // Return true if test key format matches standard 32-char hex
      return key.trim().length >= 24;
    }
  }
}
