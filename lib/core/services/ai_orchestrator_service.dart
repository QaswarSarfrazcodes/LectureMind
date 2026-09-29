import 'dart:async';
import '../network/gemini_client.dart';
import '../network/groq_client.dart';
import '../utils/prompt_builder.dart';
import '../../shared_models/language.dart';

/// Target cognitive route decided by the AI Orchestration Engine.
enum CognitiveRoute {
  /// Ultra-low-latency streaming (~350ms) for Q&A, definitions, summaries, and lecture recall.
  fastGroqStreaming,

  /// Deep reasoning & high-order logic for mathematical proofs, derivations, and long-context synthesis.
  deepReasoningGemini,
}

/// Metadata-rich response from the cognitive orchestrator.
class OrchestratedAiResponse {
  const OrchestratedAiResponse({
    required this.content,
    required this.engineUsed,
    required this.route,
    required this.latencyMs,
    required this.hasFallback,
    required this.timestamp,
  });

  final String content;
  final String engineUsed;
  final CognitiveRoute route;
  final int latencyMs;
  final bool hasFallback;
  final DateTime timestamp;

  bool get isGemini => engineUsed.contains('gemini');
  bool get isGroq => engineUsed.contains('groq') || engineUsed.contains('gpt-oss');
}

/// Dual-Engine Cognitive Orchestrator for LectureMind (Phase 1).
/// Dynamically routes between Groq (sub-second streaming speed) and Google Gemini (deep reasoning),
/// with speculative timeout failover, zero user-visible disruption, and full bilingual support.
class AiOrchestratorService {
  const AiOrchestratorService({
    required GroqClient groqClient,
    required GeminiClient geminiClient,
  })  : _groq = groqClient,
        _gemini = geminiClient;

  final GroqClient _groq;
  final GeminiClient _gemini;

  static const Duration _kStreamingFirstTokenTimeout = Duration(milliseconds: 2500);

  /// Analyzes query semantics and mathematical complexity to select optimal cognitive engine.
  CognitiveRoute classifyQuery(String query) {
    final lower = query.toLowerCase();

    // Mathematical proofs, step-by-step derivations & complex calculus
    final isMathOrProof = lower.contains('prove that') ||
        lower.contains('derivation') ||
        lower.contains('derive the') ||
        lower.contains('eigenvalue') ||
        lower.contains('eigenvector') ||
        lower.contains('differential equation') ||
        lower.contains('matrix determinant') ||
        lower.contains('integral') ||
        lower.contains('calculus') ||
        lower.contains('ثبوت') ||
        lower.contains('ڈیریویشن') ||
        lower.contains('میتھمیٹیکل ثبوت') ||
        lower.contains(r'\int') ||
        lower.contains(r'\sum');

    // Multi-page comparative synthesis
    final isDeepSynthesis = lower.contains('comprehensive comparative analysis') ||
        lower.contains('deep technical comparison') ||
        lower.contains('complete research paper summary');

    if (isMathOrProof || isDeepSynthesis) {
      return CognitiveRoute.deepReasoningGemini;
    }

    return CognitiveRoute.fastGroqStreaming;
  }

  /// Executes an orchestrated query across Groq and Gemini with automatic speculative failover.
  Future<OrchestratedAiResponse> executeOrchestratedQuery({
    required String query,
    required String systemPrompt,
    List<Map<String, String>> history = const [],
    Language language = Language.english,
    double? temperature,
    int maxTokens = 1800,
    void Function(String delta)? onStreamToken,
  }) async {
    final stopwatch = Stopwatch()..start();
    final route = classifyQuery(query);
    final effectiveTemp = temperature ?? PromptBuilder.getAdaptiveTemperature(query, AiTaskType.chatQa);

    // ─────────────────────────────────────────────────────────────────────────
    // Route 1: Deep Reasoning Path (Gemini First -> Groq Fallback)
    // ─────────────────────────────────────────────────────────────────────────
    if (route == CognitiveRoute.deepReasoningGemini) {
      try {
        final geminiResult = await _gemini.generateContent(
          prompt: query,
          history: history,
          systemInstruction: systemPrompt,
          temperature: effectiveTemp,
          maxTokens: maxTokens,
          language: language,
        );

        if (geminiResult.isSuccess &&
            geminiResult.data != null &&
            geminiResult.data!.trim().isNotEmpty) {
          stopwatch.stop();
          final output = geminiResult.data!.trim();
          onStreamToken?.call(output);
          return OrchestratedAiResponse(
            content: output,
            engineUsed: 'google/${GeminiClient.defaultModel}',
            route: route,
            latencyMs: stopwatch.elapsedMilliseconds,
            hasFallback: false,
            timestamp: DateTime.now(),
          );
        }
      } catch (_) {
        // Fall through to Groq fallback
      }

      // Speculative fallback to Groq if Gemini is unconfigured or fails
      final groqFallback = await _groq.postChatCompletion(
        systemPrompt: systemPrompt,
        userContent: query,
        history: history,
        temperature: effectiveTemp,
        maxTokens: maxTokens,
        taskType: AiTaskType.chatQa,
        language: language,
      );

      stopwatch.stop();
      final fallbackContent = groqFallback.data?.trim() ?? '';
      onStreamToken?.call(fallbackContent);
      return OrchestratedAiResponse(
        content: fallbackContent,
        engineUsed: 'groq/${GroqClient.modelName}',
        route: route,
        latencyMs: stopwatch.elapsedMilliseconds,
        hasFallback: true,
        timestamp: DateTime.now(),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Route 2: Fast Streaming Path (Groq Streaming -> Gemini Fallback)
    // ─────────────────────────────────────────────────────────────────────────
    String accumulated = '';
    bool firstTokenReceived = false;
    bool groqStreamingSucceeded = false;

    try {
      final stream = _groq.streamChatCompletion(
        systemPrompt: systemPrompt,
        userContent: query,
        history: history,
        temperature: effectiveTemp,
        maxTokens: maxTokens,
        taskType: AiTaskType.chatQa,
        language: language,
      );

      final completer = Completer<bool>();
      late StreamSubscription<String> sub;

      // Timeout guard: If first token does not arrive in 2.5s, cancel and fallback
      final timer = Timer(_kStreamingFirstTokenTimeout, () {
        if (!firstTokenReceived && !completer.isCompleted) {
          completer.complete(false);
        }
      });

      sub = stream.listen(
        (delta) {
          firstTokenReceived = true;
          accumulated += delta;
          onStreamToken?.call(delta);
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          timer.cancel();
          if (!completer.isCompleted) completer.complete(true);
        },
      );

      final success = await completer.future;
      await sub.cancel();
      timer.cancel();

      if (success && accumulated.trim().isNotEmpty) {
        groqStreamingSucceeded = true;
      }
    } catch (_) {
      groqStreamingSucceeded = false;
    }

    if (groqStreamingSucceeded) {
      stopwatch.stop();
      return OrchestratedAiResponse(
        content: accumulated.trim(),
        engineUsed: 'groq/${GroqClient.modelName}',
        route: route,
        latencyMs: stopwatch.elapsedMilliseconds,
        hasFallback: false,
        timestamp: DateTime.now(),
      );
    }

    // Secondary fallback: Non-streaming Groq
    try {
      final groqSyncResult = await _groq.postChatCompletion(
        systemPrompt: systemPrompt,
        userContent: query,
        history: history,
        temperature: effectiveTemp,
        maxTokens: maxTokens,
        taskType: AiTaskType.chatQa,
        language: language,
      );

      if (groqSyncResult.isSuccess &&
          groqSyncResult.data != null &&
          groqSyncResult.data!.trim().isNotEmpty) {
        stopwatch.stop();
        final content = groqSyncResult.data!.trim();
        onStreamToken?.call(content);
        return OrchestratedAiResponse(
          content: content,
          engineUsed: 'groq/${GroqClient.modelName}',
          route: route,
          latencyMs: stopwatch.elapsedMilliseconds,
          hasFallback: true,
          timestamp: DateTime.now(),
        );
      }
    } catch (_) {}

    // Tertiary fallback: Google Gemini
    final geminiFallback = await _gemini.generateContent(
      prompt: query,
      history: history,
      systemInstruction: systemPrompt,
      temperature: effectiveTemp,
      maxTokens: maxTokens,
      language: language,
    );

    stopwatch.stop();
    final geminiContent = geminiFallback.data?.trim() ?? '';
    onStreamToken?.call(geminiContent);
    return OrchestratedAiResponse(
      content: geminiContent,
      engineUsed: 'google/${GeminiClient.defaultModel}',
      route: route,
      latencyMs: stopwatch.elapsedMilliseconds,
      hasFallback: true,
      timestamp: DateTime.now(),
    );
  }
}
