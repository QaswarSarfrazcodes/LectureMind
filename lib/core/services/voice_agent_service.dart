import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import '../network/assembly_ai_client.dart';
import '../network/groq_client.dart';
import '../network/gemini_client.dart';
import '../../features/record_process/data/audio_recording_service.dart';
import '../../shared_models/language.dart';
import '../utils/prompt_builder.dart';
import 'web_speech/web_speech.dart';

enum VoiceAgentStatus {
  idle,
  listening,
  thinking,
  speaking,
  error,
}

class VoiceAgentTurn {
  const VoiceAgentTurn({
    required this.userSpeech,
    required this.aiSpeech,
    required this.timestamp,
  });

  final String userSpeech;
  final String aiSpeech;
  final DateTime timestamp;
}

/// Orchestrator for LectureMind Voice Agent.
///
/// Key fixes vs. previous version:
/// 1. TTS now uses *sentence-chunked sequential playback* — each sentence is
///    spoken via a Completer chain so the completion handler only advances after
///    the OS engine actually finishes that chunk. This fixes the 2–3 word
///    cut-off bug caused by the TTS buffer overflowing on a single large blob.
/// 2. A `_speakingCancelled` guard prevents the status from flipping to
///    listening mid-utterance when the user has already barged in.
/// 3. Silence timer raised from 1400 ms → 2200 ms to stop premature turn-taking
///    during natural speech pauses.
/// 4. Speech rate tuned to 0.58 (up from 0.50) for natural cadence.
class VoiceAgentService {
  VoiceAgentService({
    required AssemblyAiClient assemblyAi,
    required GroqClient groq,
    required GeminiClient gemini,
    AudioRecordingService? audio,
  })  : _assemblyAi = assemblyAi,
        _groq = groq,
        _gemini = gemini,
        _audio = audio ?? AudioRecordingService() {
    _initTts();
  }

  final AssemblyAiClient _assemblyAi;
  final GroqClient _groq;
  final GeminiClient _gemini;
  final AudioRecordingService _audio;
  final FlutterTts _tts = FlutterTts();

  VoiceAgentStatus _status = VoiceAgentStatus.idle;
  VoiceAgentStatus get status => _status;

  String _currentTranscript = '';
  String get currentTranscript => _currentTranscript;

  String _lastAiReply = '';
  String get lastAiReply => _lastAiReply;

  final List<VoiceAgentTurn> _history = [];
  List<VoiceAgentTurn> get history => List.unmodifiable(_history);

  StreamSubscription<TranscriptSegment>? _transcriptSub;
  StreamSubscription<Uint8List>? _audioSub;
  Timer? _silenceTimer;

  // Guards barge-in so status flip doesn't race with sentence chunks.
  bool _speakingCancelled = false;
  // Tracks whether TTS has been fully initialised.
  bool _ttsReady = false;

  String? _lectureContext;
  String? get lectureContext => _lectureContext;
  void setLectureContext(String? context) {
    _lectureContext = context;
  }

  void Function(VoiceAgentStatus status)? onStatusChanged;
  void Function(String partial)? onUserTranscript;
  void Function(String aiText)? onAiSpeaking;
  void Function(String error)? onError;

  // ── TTS initialisation ───────────────────────────────────────────────────────

  Future<void> _initTts() async {
    try {
      await _tts.setPitch(1.15);        // Slightly higher pitch → feminine voice
      await _tts.setSpeechRate(0.72);   // 1.25× speed (0.58 × 1.25 ≈ 0.72)
      await _tts.setVolume(1.0);
      // Request a female voice on platforms that support it.
      if (!kIsWeb) {
        final voices = await _tts.getVoices as List?;
        if (voices != null) {
          // Prefer en-US female voices — Samantha (iOS), en-us-x-sfg (Android)
          final femaleVoice = voices.cast<Map>().firstWhere(
            (v) =>
              (v['name']?.toString().toLowerCase().contains('female') == true ||
               v['name']?.toString().toLowerCase().contains('samantha') == true ||
               v['name']?.toString().toLowerCase().contains('google uk english female') == true ||
               v['name']?.toString().toLowerCase().contains('en-us-x-sfg') == true),
            orElse: () => <String, String>{},
          );
          if (femaleVoice.isNotEmpty && femaleVoice['name'] != null) {
            await _tts.setVoice({'name': femaleVoice['name'], 'locale': femaleVoice['locale'] ?? 'en-US'});
          }
        }
      }
      _ttsReady = true;
    } catch (_) {
      _ttsReady = true; // Still mark ready so we don't block the session
    }
  }

  // ── Status helper ────────────────────────────────────────────────────────────

  void _setStatus(VoiceAgentStatus s) {
    _status = s;
    onStatusChanged?.call(s);
  }

  // ── Session management ───────────────────────────────────────────────────────

  /// Starts the continuous hands-free voice agent session with microphone stream.
  Future<void> startSession({Language language = Language.english}) async {
    await stopSession();
    _setStatus(VoiceAgentStatus.listening);
    _currentTranscript = '';
    _lastAiReply = '';
    _speakingCancelled = false;

    try {
      // 1. On Web, initiate zero-latency browser speech recognition if supported
      if (kIsWeb && WebSpeechBridge.isSupported) {
        WebSpeechBridge.start(
          language: language == Language.urdu ? 'ur' : 'en',
          onResult: (text, isFinal) {
            if (_status == VoiceAgentStatus.speaking && text.trim().isNotEmpty) {
              _speakingCancelled = true;
              _tts.stop();
              _setStatus(VoiceAgentStatus.listening);
            }
            _currentTranscript = text;
            onUserTranscript?.call(text);

            if (isFinal && text.trim().isNotEmpty) {
              _silenceTimer?.cancel();
              _handleUserSpoke(text.trim(), language);
            } else if (text.trim().isNotEmpty) {
              _silenceTimer?.cancel();
              _silenceTimer = Timer(const Duration(milliseconds: 1800), () {
                if (_currentTranscript.trim().isNotEmpty &&
                    _status == VoiceAgentStatus.listening) {
                  _handleUserSpoke(_currentTranscript.trim(), language);
                }
              });
            }
          },
          onError: (_) {},
          onEnd: () {
            if (_status == VoiceAgentStatus.listening && kIsWeb) {
              // Re-arm if session still active
              WebSpeechBridge.start(
                language: language == Language.urdu ? 'ur' : 'en',
                onResult: (text, isFinal) {
                  _currentTranscript = text;
                  onUserTranscript?.call(text);
                  if (isFinal && text.trim().isNotEmpty) {
                    _handleUserSpoke(text.trim(), language);
                  }
                },
              );
            }
          },
        );
      }

      // 2. Verify microphone permissions for native hardware stream.
      final permitted = await _audio.hasPermission();
      if (!permitted && !kIsWeb) {
        onError?.call('Microphone permission required for voice conversation.');
        _setStatus(VoiceAgentStatus.error);
        return;
      }

      // 3. Connect AssemblyAI WebSocket real-time transcription.
      _transcriptSub = _assemblyAi.startRealtimeSession().listen(
        (segment) {
          // Barge-in: if AI is speaking and the user starts talking, interrupt.
          if (_status == VoiceAgentStatus.speaking &&
              segment.text.trim().isNotEmpty) {
            _speakingCancelled = true;
            _tts.stop();
            _setStatus(VoiceAgentStatus.listening);
          }

          _currentTranscript = segment.text;
          onUserTranscript?.call(_currentTranscript);

          if (segment.isFinal && segment.text.trim().isNotEmpty) {
            _handleUserSpoke(segment.text.trim(), language);
          } else if (segment.text.trim().isNotEmpty) {
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(milliseconds: 2200), () {
              if (_currentTranscript.trim().isNotEmpty &&
                  _status == VoiceAgentStatus.listening) {
                _handleUserSpoke(_currentTranscript.trim(), language);
              }
            });
          }
        },
        onError: (err) {
          // If web speech bridge is active, silent failover
          if (!kIsWeb) {
            onError?.call('Voice Stream: $err');
          }
        },
      );

      // 4. Open hardware microphone stream and feed PCM 16kHz to AssemblyAI.
      final audioStream = await _audio.startStream();
      if (audioStream != null) {
        _audioSub = audioStream.listen(
          (chunk) => _assemblyAi.sendAudioChunk(chunk),
          onError: (_) {},
        );
      }
    } catch (e) {
      if (!kIsWeb) {
        onError?.call('Could not start voice session: $e');
        _setStatus(VoiceAgentStatus.error);
      }
    }
  }

  /// Triggers a voice query explicitly (e.g. from prompt chips or tap-to-speak).
  Future<void> triggerUserSpokenQuery(
    String query, {
    Language language = Language.english,
  }) async {
    if (query.trim().isEmpty) return;
    if (_status == VoiceAgentStatus.speaking) {
      _speakingCancelled = true;
      await _tts.stop();
    }
    onUserTranscript?.call(query.trim());
    await _handleUserSpoke(query.trim(), language);
  }

  // ── Core conversation loop ───────────────────────────────────────────────────

  Future<void> _handleUserSpoke(String spokenText, Language language) async {
    _silenceTimer?.cancel();
    if (spokenText.trim().isEmpty) return;

    _setStatus(VoiceAgentStatus.thinking);
    final userQuery = spokenText.trim();
    _currentTranscript = '';

    // Detect language from content or explicit parameter.
    final isUrdu = language == Language.urdu ||
        RegExp(r'[\u0600-\u06FF]').hasMatch(userQuery);

    final lectureSnippet = (_lectureContext != null && _lectureContext!.isNotEmpty)
        ? '\n\nACTIVE LECTURE MATERIAL TO TEST OR EXPLAIN:\n$_lectureContext\nAct as a Socratic oral examiner and tutor. Test the student or answer questions on this lecture.'
        : '';

    final systemPrompt =
        'You are LectureMind Realtime Voice Agent, an intelligent bilingual '
        'voice companion powered by AssemblyAI, Groq, and Google Gemini. '
        'Keep answers concise, conversational, and direct (2 to 4 sentences) '
        'because your output is being spoken aloud. '
        'Use natural, warm conversational phrasing in ${isUrdu ? "Urdu" : "English"}. '
        'Do not output markdown asterisks, bullet signs, or any formatting.'
        '$lectureSnippet';

    String aiText = '';

    final historyTurns = <Map<String, String>>[];
    for (final turn in _history) {
      if (turn.userSpeech.isNotEmpty) {
        historyTurns.add({'role': 'user', 'content': turn.userSpeech});
      }
      if (turn.aiSpeech.isNotEmpty) {
        historyTurns.add({'role': 'assistant', 'content': turn.aiSpeech});
      }
    }
    final safeHistory = historyTurns.length > 8
        ? historyTurns.sublist(historyTurns.length - 8)
        : historyTurns;

    // 1. Try Groq first (ultra-fast low-latency inference with multi-turn memory).
    final groqRes = await _groq.postChatCompletion(
      systemPrompt: systemPrompt,
      userContent: userQuery,
      history: safeHistory,
      maxTokens: 300,
      taskType: AiTaskType.voiceAgent,
      language: language,
    );

    if (groqRes.isSuccess &&
        groqRes.data != null &&
        groqRes.data!.trim().isNotEmpty) {
      aiText = groqRes.data!.trim();
    } else {
      // 2. Resilient fallback to Gemini multi-model engine with multi-turn memory.
      final geminiRes = await _gemini.generateContent(
        prompt: userQuery,
        history: safeHistory,
        systemInstruction: systemPrompt,
        maxTokens: 300,
        language: language,
      );
      if (geminiRes.isSuccess &&
          geminiRes.data != null &&
          geminiRes.data!.trim().isNotEmpty) {
        aiText = geminiRes.data!.trim();
      } else {
        aiText = isUrdu
            ? 'معذرت، میں آپ کی بات سمجھ نہیں سکا۔ کیا آپ دوبارہ دہرا سکتے ہیں؟'
            : 'I could not quite catch that. Could you please repeat your question?';
      }
    }

    // Clean markdown and mathematical notation for pristine speech synthesis.
    final cleanForSpeech = PromptBuilder.cleanSpokenText(aiText);

    _lastAiReply = aiText;
    _history.add(VoiceAgentTurn(
      userSpeech: userQuery,
      aiSpeech: aiText,
      timestamp: DateTime.now(),
    ));

    _setStatus(VoiceAgentStatus.speaking);
    onAiSpeaking?.call(aiText);
    _speakingCancelled = false;

    // Speak using sentence-chunked sequential playback.
    await _speakSequentially(cleanForSpeech, isUrdu);
  }

  // ── Sentence-chunked TTS (key bug fix) ──────────────────────────────────────

  /// Splits [text] into sentences and speaks them one by one, waiting for the
  /// OS TTS engine to finish each before starting the next.
  ///
  /// This is the primary fix for the "2–3 words then silence" bug — the old
  /// approach called `_tts.speak(entireText)` which overwhelmed the TTS
  /// buffer on Android. Sequential sentence delivery gives the engine time
  /// to render each chunk fully before the next is queued.
  Future<void> _speakSequentially(String text, bool isUrdu) async {
    if (!_ttsReady) {
      await _initTts();
    }

    try {
      final lang = isUrdu || RegExp(r'[\u0600-\u06FF]').hasMatch(text)
          ? 'ur-PK'
          : 'en-GB'; // British English female tends to be more natural
      await _tts.setLanguage(lang);
      // Re-apply speed and pitch on each utterance for robustness
      await _tts.setSpeechRate(0.72);  // 1.25×
      await _tts.setPitch(isUrdu ? 1.1 : 1.15); // feminine pitch
    } catch (_) {}

    final sentences = _splitIntoSentences(text);

    for (final sentence in sentences) {
      // Check for barge-in cancellation before each sentence.
      if (_speakingCancelled || _status != VoiceAgentStatus.speaking) break;

      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;

      // Completer resolves when the TTS engine finishes this sentence.
      final completer = Completer<void>();

      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      _tts.setErrorHandler((msg) {
        if (!completer.isCompleted) completer.complete(); // Continue on error
      });

      try {
        await _tts.speak(trimmed);
        // Wait for this sentence to finish (with a safety timeout).
        await completer.future.timeout(
          Duration(milliseconds: (trimmed.length * 80 + 2000).clamp(2000, 15000)),
          onTimeout: () {},
        );
      } catch (_) {
        // If speak() throws, continue to next sentence.
      }

      // Short inter-sentence breath pause for naturalness.
      if (!_speakingCancelled && _status == VoiceAgentStatus.speaking) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }

    // Only transition back to listening if we weren't interrupted.
    if (!_speakingCancelled && _status == VoiceAgentStatus.speaking) {
      _setStatus(VoiceAgentStatus.listening);
    }
  }

  /// Splits a cleaned text string into individual sentences for chunked TTS.
  /// Handles English sentence terminators and Urdu/Arabic full stops (۔).
  List<String> _splitIntoSentences(String text) {
    if (text.isEmpty) return [];

    // Split on sentence-ending punctuation, keeping the delimiter.
    final raw = text.splitMapJoin(
      RegExp(r'(?<=[.!?۔؟])\s+'),
      onMatch: (m) => '\n',
      onNonMatch: (s) => s,
    );

    final parts = raw
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // If no sentence boundaries found, use the whole text as one chunk.
    if (parts.isEmpty) return [text];

    // Merge very short fragments (< 25 chars) with the next sentence to avoid
    // overly short TTS calls that cause audible pops on some engines.
    final merged = <String>[];
    var buffer = '';
    for (final part in parts) {
      if (buffer.isEmpty) {
        buffer = part;
      } else if (buffer.length < 25) {
        buffer = '$buffer $part';
      } else {
        merged.add(buffer);
        buffer = part;
      }
    }
    if (buffer.isNotEmpty) merged.add(buffer);

    return merged;
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  /// User explicitly interrupts AI speech (barge-in).
  Future<void> interrupt() async {
    _speakingCancelled = true;
    await _tts.stop();
    _setStatus(VoiceAgentStatus.listening);
  }

  /// Stops voice agent session completely and releases all resources.
  Future<void> stopSession() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speakingCancelled = true;
    if (kIsWeb) {
      WebSpeechBridge.stop();
    }
    await _tts.stop();
    await _audioSub?.cancel();
    _audioSub = null;
    await _audio.stop();
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    await _assemblyAi.stopRealtimeSession();
    _setStatus(VoiceAgentStatus.idle);
  }

  void dispose() {
    stopSession();
    _audio.dispose();
  }
}
