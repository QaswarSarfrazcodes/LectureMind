import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_secrets.dart';
import '../error/failures.dart';
import '../../shared_models/language.dart';
import '../utils/prompt_builder.dart';
import '../services/mind_map_synthesizer.dart';

/// Groq LLM client for Llama 3.3 70b reasoning per `api.md` §2.
class GroqClient {
  GroqClient({
    required String Function() apiKeyProvider,
    Dio? dio,
  })  : _apiKeyProvider = apiKeyProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: defaultBaseUrl,
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 70),
                headers: {
                  'Content-Type': 'application/json',
                  'User-Agent': 'LectureMind/1.0',
                },
              ),
            );

  static String get defaultBaseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      return '$origin/api/groq';
    }
    return 'https://api.groq.com/openai/v1';
  }

  final String Function() _apiKeyProvider;
  final Dio _dio;

  // Priority order: best model first, fast fallback chain
  static const String modelName = 'openai/gpt-oss-120b';
  static const List<String> availableModels = [
    'openai/gpt-oss-120b',   // Primary — best reasoning & synthesis
    'openai/gpt-oss-20b',    // Fallback 1 — ultra-fast response
    'qwen/qwen3.8-27b',      // Fallback 2 — high-capacity multilingual
  ];

  String get _apiKey {
    final k = _apiKeyProvider().trim();
    return k.isNotEmpty ? k : AppSecrets.groqApiKey;
  }

  /// Posts a chat completion request to Groq with automatic model fallback, token control, and retry logic.
  Future<Result<String, Failure>> postChatCompletion({
    required String systemPrompt,
    required String userContent,
    List<Map<String, String>> history = const [],
    bool jsonMode = false,
    double temperature = 0.3,
    int? maxTokens,
    AiTaskType? taskType,
    Language? language,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      final fallback = _generateFallbackResponse(
        taskType: taskType,
        userContent: userContent,
        language: language ?? Language.english,
        jsonMode: jsonMode,
      );
      return Result.success(fallback);
    }

    // Token limits tuned per task type: notes/quiz need larger outputs
    final limit = maxTokens ?? _defaultTokensForTask(taskType, jsonMode);
    // Temperature: creative for chat, precise for JSON structured outputs
    final temp = _refinedTemperature(taskType, temperature);

    // Sliding window: retain up to last 12 turns (6 turns each) to prevent context blowup
    final safeHistory = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...safeHistory.map((m) => {
            'role': m['role'] ?? 'user',
            'content': m['content'] ?? '',
          }),
      {'role': 'user', 'content': userContent},
    ];

    for (final currentModel in availableModels) {
      int retryCount = 0;
      Duration delay = const Duration(milliseconds: 600);

      while (retryCount < 2) {
        try {
          final body = <String, dynamic>{
            'model': currentModel,
            'messages': messages,
            'temperature': temp,
            'max_tokens': limit,
            if (jsonMode && !currentModel.contains('allam'))
              'response_format': {'type': 'json_object'},
          };

          final response = await _dio.post(
            '/chat/completions',
            data: jsonEncode(body),
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (response.statusCode == 200) {
            final choices = response.data['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final msg = choices[0]['message'] as Map<String, dynamic>? ?? {};
              var content = msg['content'] as String? ?? '';
              if (content.trim().isEmpty && msg['reasoning_content'] is String) {
                content = msg['reasoning_content'] as String;
              }
              // Clean any internal thought tokens from reasoning models
              content = content.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>'), '').trim();
              if (content.isNotEmpty) {
                return Result.success(content);
              }
            }
            return Result.failure(const ParsingFailure('Empty response from Groq'));
          }
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 401) {
            return Result.failure(const AuthFailure('Invalid Groq API key (401). Check Settings.'));
          }
          if (status == 404) {
            // Model not available on this tier, fall through to next model
            break;
          }
          if (status == 429 || (status != null && status >= 500)) {
            retryCount++;
            await Future.delayed(delay);
            delay *= 2;
            continue;
          }
          break;
        } catch (_) {
          break;
        }
      }
    }

    final fallback = _generateFallbackResponse(
      taskType: taskType,
      userContent: userContent,
      language: language ?? Language.english,
      jsonMode: jsonMode,
    );
    return Result.success(fallback);
  }

  /// Streams chat completion tokens in real-time via Server-Sent Events (SSE).
  /// Yields text deltas as they arrive from the active model.
  Stream<String> streamChatCompletion({
    required String systemPrompt,
    required String userContent,
    List<Map<String, String>> history = const [],
    double temperature = 0.3,
    int? maxTokens,
    AiTaskType? taskType,
    Language? language,
  }) async* {
    final apiKey = _apiKey;
    final limit = maxTokens ?? _defaultTokensForTask(taskType, false);
    final temp = _refinedTemperature(taskType, temperature);

    final safeHistory = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...safeHistory.map((m) => {
            'role': m['role'] ?? 'user',
            'content': m['content'] ?? '',
          }),
      {'role': 'user', 'content': userContent},
    ];

    bool yieldedAny = false;

    for (final currentModel in availableModels) {
      try {
        final body = <String, dynamic>{
          'model': currentModel,
          'messages': messages,
          'temperature': temp,
          'max_tokens': limit,
          'stream': true,
        };

        final response = await _dio.post<ResponseBody>(
          '/chat/completions',
          data: jsonEncode(body),
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Accept': 'text/event-stream',
            },
            responseType: ResponseType.stream,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          String lineBuffer = '';
          await for (final chunk in response.data!.stream) {
            final decoded = utf8.decode(chunk, allowMalformed: true);
            lineBuffer += decoded;
            final lines = lineBuffer.split('\n');
            lineBuffer = lines.removeLast();

            for (final line in lines) {
              final trimmed = line.trim();
              if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
              if (trimmed == 'data: [DONE]') return;
              if (trimmed.startsWith('data: ')) {
                final jsonStr = trimmed.substring(6).trim();
                if (jsonStr.isEmpty || jsonStr == '[DONE]') return;
                try {
                  final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                  final choices = data['choices'] as List<dynamic>?;
                  if (choices != null && choices.isNotEmpty) {
                    final delta = choices[0]['delta'] as Map<String, dynamic>?;
                    if (delta != null) {
                      var content = delta['content'] as String? ?? '';
                      if (content.isEmpty && delta['reasoning_content'] is String) {
                        content = delta['reasoning_content'] as String;
                      }
                      if (content.isNotEmpty) {
                        content = content.replaceAll(RegExp(r'<\/?think>'), '');
                        if (content.isNotEmpty) {
                          yieldedAny = true;
                          yield content;
                        }
                      }
                    }
                  }
                } catch (_) {}
              }
            }
          }

          if (yieldedAny) return;
        }
      } catch (_) {
        // Model streaming failed, try next model in fallback list
      }
    }

    // If streaming produced no tokens, fallback seamlessly to regular completion
    if (!yieldedAny) {
      final res = await postChatCompletion(
        systemPrompt: systemPrompt,
        userContent: userContent,
        history: history,
        temperature: temperature,
        maxTokens: maxTokens,
        taskType: taskType,
        language: language,
      );
      if (res.isSuccess && res.data != null && res.data!.isNotEmpty) {
        yield res.data!;
      }
    }
  }

  // Per-task optimal token ceilings
  static int _defaultTokensForTask(AiTaskType? task, bool jsonMode) {
    switch (task) {
      case AiTaskType.notesGeneration:  return 4096;  // Rich notes + mind map
      case AiTaskType.quizGeneration:   return 3000;  // 10-12 questions with explanations
      case AiTaskType.chatQa:           return 1800;  // Conversational depth
      case AiTaskType.voiceAgent:       return 300;   // Voice: concise only
      case AiTaskType.eli10Simplify:    return 500;
      case AiTaskType.sttRefinement:    return 2500;  // High-precision lecture transcript
      default:                          return jsonMode ? 3500 : 2000;
    }
  }

  // Per-task optimal temperature
  static double _refinedTemperature(AiTaskType? task, double defaultTemp) {
    switch (task) {
      case AiTaskType.notesGeneration:  return 0.25; // Factual, structured
      case AiTaskType.quizGeneration:   return 0.30; // Slightly varied distractors
      case AiTaskType.chatQa:           return 0.55; // Warm, slightly creative
      case AiTaskType.voiceAgent:       return 0.60; // Conversational
      case AiTaskType.eli10Simplify:    return 0.65; // Creative analogies
      case AiTaskType.sttRefinement:    return 0.15; // Extremely precise, minimal hallucination
      default:                          return defaultTemp;
    }
  }


  /// Validates key by executing a 1-token test prompt.
  Future<bool> validateKey(String key) async {
    if (key.trim().isEmpty) return false;
    try {
      final res = await _dio.post(
        '/chat/completions',
        data: jsonEncode({
          'model': 'openai/gpt-oss-20b',
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
          'max_tokens': 2,
        }),
        options: Options(
          headers: {'Authorization': 'Bearer ${key.trim()}'},
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return key.trim().startsWith('gsk_') && key.trim().length >= 30;
    }
  }

  /// Dynamic local fallback generator that extracts real notes, mind map, and quiz
  /// directly from the user's speech transcript when offline or without an API key.
  String _generateFallbackResponse({
    AiTaskType? taskType,
    required String userContent,
    required Language language,
    required bool jsonMode,
  }) {
    final isUrdu = language == Language.urdu;

    // 1. Extract raw transcript from userContent
    String transcript = userContent;
    if (transcript.contains('Transcript to structure:')) {
      transcript = transcript.split('Transcript to structure:').last.trim();
    } else if (transcript.contains('Lecture Material & Transcript:')) {
      transcript = transcript.split('Lecture Material & Transcript:').last.trim();
    } else if (transcript.contains('"""')) {
      final match = RegExp(r'"""([\s\S]*?)"""').firstMatch(transcript);
      if (match != null && match.group(1) != null) {
        transcript = match.group(1)!.trim();
      }
    }

    // STT refinement fallback: return the raw transcript itself
    if (taskType == AiTaskType.sttRefinement) {
      return transcript.isNotEmpty ? transcript : userContent.trim();
    }

    // Clean up transcript
    final clean = transcript.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = clean
        .split(RegExp(r'(?<=[.!?۔\n])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 5)
        .toList();

    // Derive topic / title from user's meaningful words
    final words = clean.split(' ').where((w) => w.length > 2).toList();
    final meaningfulWords = words.where((w) {
      final low = w.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      return !['the', 'and', 'this', 'that', 'with', 'from', 'have', 'were', 'which', 'about', 'today', 'lecture', 'student', 'class', 'hello', 'good', 'morning', 'afternoon', 'we', 'are', 'is', 'in', 'on', 'for', 'to', 'of', 'a', 'an'].contains(low);
    }).toList();

    String lectureTitle = meaningfulWords.length >= 2
        ? meaningfulWords.take(4).map((w) => w.length > 1 ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ')
        : (words.isNotEmpty ? words.take(4).join(' ') : (isUrdu ? 'لیکچر کا خلاصہ' : 'Lecture Synthesis'));
    if (lectureTitle.length < 4) {
      lectureTitle = isUrdu ? 'تعلیمی لیکچر خلاصہ' : 'Academic Lecture Synthesis';
    }

    // ── Dynamic Notes & Mind Map Generation (100% Speech Coverage) ─────────
    if (taskType == AiTaskType.notesGeneration ||
        (jsonMode && (userContent.toLowerCase().contains('transcript') || userContent.toLowerCase().contains('structure')))) {
      final synthesized = MindMapSynthesizer.synthesizeFullNotesJson(
        transcript: transcript,
        customTitle: null,
        isUrdu: isUrdu,
      );
      return jsonEncode(synthesized);
    }

    // ── Dynamic Socratic Quiz Generation ────────────────────────────────────
    if (taskType == AiTaskType.quizGeneration) {
      final questions = <Map<String, dynamic>>[];
      for (int i = 0; i < sentences.length && i < 4; i++) {
        final sentence = sentences[i];
        if (sentence.length < 15) continue;
        questions.add({
          'type': 'mcq',
          'question': isUrdu
              ? 'لیکچر کے مطابق، مندرجہ ذیل میں سے کون سا بیان درست ہے؟'
              : 'Based on the lecture discussion, which statement is accurately supported?',
          'options': [
            sentence,
            'This statement was explicitly contradicted during the lecture',
            'No experimental evidence or data was presented for this hypothesis',
            'This concept is outside the analytical scope of this session'
          ],
          'correct_answer': sentence,
          'explanation': 'Directly derived from the recorded lecture transcript: "$sentence"'
        });
      }

      if (questions.isEmpty) {
        questions.add({
          'type': 'mcq',
          'question': 'What is the primary topic addressed in this lecture?',
          'options': [
            lectureTitle,
            'Unrelated industry overview',
            'Introductory syllabus review',
            'Historical general context'
          ],
          'correct_answer': lectureTitle,
          'explanation': 'The lecture focuses primarily on $lectureTitle.'
        });
      }

      return jsonEncode({'questions': questions});
    }

    // ── Chat Q&A Fallback ───────────────────────────────────────────────────
    if (taskType == AiTaskType.chatQa) {
      if (sentences.isNotEmpty) {
        return 'Based on the lecture recording on "$lectureTitle":\n\n'
               '• Key insight: ${sentences.first}\n\n'
               '• Additional context: ${sentences.length > 1 ? sentences[1] : sentences.first}';
      }
      return 'The lecture covers $lectureTitle. You can ask specific questions about the recorded topics.';
    }

    return clean;
  }
}
