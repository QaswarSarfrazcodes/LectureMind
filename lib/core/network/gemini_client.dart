import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_secrets.dart';
import '../error/failures.dart';
import '../../shared_models/language.dart';

/// Client for Google Gemini API (supporting gemini-3.5-flash and multimodal capabilities).
class GeminiClient {
  GeminiClient({
    String? apiKey,
    String Function()? apiKeyProvider,
    Dio? dio,
  })  : _apiKeyProvider = apiKeyProvider ?? (() => apiKey ?? AppSecrets.geminiApiKey),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 70),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final String Function() _apiKeyProvider;
  final Dio _dio;

  String get _apiKey => _apiKeyProvider();

  static const String defaultModel = 'gemini-2.0-flash';
  static const List<String> fallbackModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.5-flash-8b',
  ];

  /// Generates content using Google Gemini model with automatic multi-model fallback.
  Future<Result<String, Failure>> generateContent({
    required String prompt,
    List<Map<String, String>> history = const [],
    String? systemInstruction,
    String? model,
    double temperature = 0.4,
    int maxTokens = 2000,
    Language? language,
    bool jsonMode = false,
  }) async {
    if (_apiKey.trim().isEmpty) {
      return Result.failure(const AuthFailure('Gemini API key is not configured.'));
    }
    final modelsToTry = <String>[];
    if (model != null && model.isNotEmpty) {
      modelsToTry.add(model);
    }
    for (final m in fallbackModels) {
      if (!modelsToTry.contains(m)) {
        modelsToTry.add(m);
      }
    }

    final safeHistory = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    final contents = <Map<String, dynamic>>[];
    for (final turn in safeHistory) {
      final role = (turn['role'] == 'assistant' || turn['role'] == 'model')
          ? 'model'
          : 'user';
      final text = turn['content'] ?? '';
      if (text.trim().isNotEmpty) {
        if (contents.isNotEmpty && contents.last['role'] == role) {
          final lastParts = contents.last['parts'] as List<dynamic>;
          lastParts.add({'text': text});
        } else {
          contents.add({
            'role': role,
            'parts': [
              {'text': text}
            ]
          });
        }
      }
    }
    if (contents.isNotEmpty && contents.last['role'] == 'user') {
      final lastParts = contents.last['parts'] as List<dynamic>;
      lastParts.add({'text': prompt});
    } else {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': prompt}
        ]
      });
    }

    final body = <String, dynamic>{
      'contents': contents,
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        if (jsonMode) 'responseMimeType': 'application/json',
      }
    };

    String lastErrorMessage = 'Unknown error';

    for (final currentModel in modelsToTry) {
      try {
        final response = await _dio.post(
          '/models/$currentModel:generateContent',
          queryParameters: {'key': _apiKey},
          data: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final candidates = response.data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String? ?? '';
              if (text.trim().isNotEmpty) {
                return Result.success(text.trim());
              }
            }
          }
        }
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401) {
          return Result.failure(const AuthFailure('Invalid Gemini API Key.'));
        }
        lastErrorMessage = 'Model $currentModel: ${e.message} (status: $status)';
        // 503 (high demand), 429 (rate limit), 404 (not found) -> try next model in fallback list
        if (status == 503 || status == 429 || status == 404 || status == 500) {
          continue;
        }
      } catch (e) {
        lastErrorMessage = 'Model $currentModel error: $e';
        continue;
      }
    }

    return Result.failure(
      GeminiFailure('Gemini API temporary unavailability: $lastErrorMessage'),
    );
  }

  /// Analyzes document text extracted from PDF or PPT slides.
  Future<Result<String, Failure>> analyzeDocument({
    required String documentTitle,
    required String documentText,
    required String userGoal,
    Language? language,
  }) async {
    const systemPrompt = '''You are LectureMind AI Multimodal Study Partner powered by Google Gemini and AssemblyAI.
Analyze the provided slide deck or document text with exceptional pedagogical clarity.
Extract core concepts, summarize key points with bullet points, and explain the underlying principles in bilingual Urdu and English as appropriate.''';

    final userPrompt = '''Document Title: $documentTitle

DOCUMENT CONTENT:
$documentText

STUDENT REQUEST:
$userGoal''';

    return generateContent(
      prompt: userPrompt,
      systemInstruction: systemPrompt,
      maxTokens: 1200,
      language: language,
    );
  }
}
