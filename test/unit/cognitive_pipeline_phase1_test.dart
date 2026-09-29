import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/error/failures.dart';
import 'package:lecturemind/core/network/gemini_client.dart';
import 'package:lecturemind/core/network/groq_client.dart';
import 'package:lecturemind/core/services/ai_orchestrator_service.dart';
import 'package:lecturemind/core/utils/prompt_builder.dart';
import 'package:lecturemind/shared_models/language.dart';

/// Fake Groq client for Phase 1 Cognitive Engine tests.
class FakeGroqClient extends Fake implements GroqClient {
  FakeGroqClient({
    this.streamTokens = const ['Groq', ' streaming', ' output'],
    this.syncResponse = 'Groq sync response',
    this.shouldStreamThrow = false,
    this.shouldSyncFail = false,
  });

  final List<String> streamTokens;
  final String syncResponse;
  final bool shouldStreamThrow;
  final bool shouldSyncFail;

  int streamCalls = 0;
  int syncCalls = 0;

  @override
  Stream<String> streamChatCompletion({
    required String systemPrompt,
    required String userContent,
    List<Map<String, String>> history = const [],
    double temperature = 0.3,
    int? maxTokens,
    AiTaskType? taskType,
    Language? language,
  }) async* {
    streamCalls++;
    if (shouldStreamThrow) {
      throw const NetworkFailure('Groq stream connection failed');
    }
    for (final token in streamTokens) {
      yield token;
    }
  }

  @override
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
    syncCalls++;
    if (shouldSyncFail) {
      return Result.failure(const GroqFailure('Groq API error'));
    }
    return Result.success(syncResponse);
  }
}

/// Fake Gemini client for Phase 1 Cognitive Engine tests.
class FakeGeminiClient extends Fake implements GeminiClient {
  FakeGeminiClient({
    this.response = 'Gemini deep reasoning proof output',
    this.shouldFail = false,
  });

  final String response;
  final bool shouldFail;

  int calls = 0;

  @override
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
    calls++;
    if (shouldFail) {
      return Result.failure(const GeminiFailure('Gemini unavailable'));
    }
    return Result.success(response);
  }
}

void main() {
  group('Phase 1 — Cognitive Engine & Real-Time Pipeline Maturation', () {
    late FakeGroqClient fakeGroq;
    late FakeGeminiClient fakeGemini;
    late AiOrchestratorService orchestrator;

    setUp(() {
      fakeGroq = FakeGroqClient();
      fakeGemini = FakeGeminiClient();
      orchestrator = AiOrchestratorService(
        groqClient: fakeGroq,
        geminiClient: fakeGemini,
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1.1 Cognitive Query Classifier & Intelligent Routing
    // ─────────────────────────────────────────────────────────────────────────
    test('AiOrchestratorService routes math proofs, calculus, and derivations to Gemini deep reasoning', () {
      expect(
        orchestrator.classifyQuery('Prove that eigenvalues of a Hermitian matrix are real'),
        CognitiveRoute.deepReasoningGemini,
      );
      expect(
        orchestrator.classifyQuery('Derive the second-order differential equation for a damped oscillator'),
        CognitiveRoute.deepReasoningGemini,
      );
      expect(
        orchestrator.classifyQuery(r'Solve the definite integral \int_0^\pi \sin(x) dx'),
        CognitiveRoute.deepReasoningGemini,
      );
      expect(
        orchestrator.classifyQuery('کیلکولس اور ڈیریویشن کا ثبوت بیان کریں'),
        CognitiveRoute.deepReasoningGemini,
      );
      expect(
        orchestrator.classifyQuery('Provide a comprehensive comparative analysis of Distributed OS vs Microkernels'),
        CognitiveRoute.deepReasoningGemini,
      );
    });

    test('AiOrchestratorService routes definitions, summaries, and flash Q&A to fast Groq streaming', () {
      expect(
        orchestrator.classifyQuery('What is the difference between a process and a thread?'),
        CognitiveRoute.fastGroqStreaming,
      );
      expect(
        orchestrator.classifyQuery('Give me a brief summary of lecture 4'),
        CognitiveRoute.fastGroqStreaming,
      );
      expect(
        orchestrator.classifyQuery('Polymorphism کی سادہ تعریف کیا ہے؟'),
        CognitiveRoute.fastGroqStreaming,
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1.2 Speculative Dual-Engine Orchestration & Live Token Streaming
    // ─────────────────────────────────────────────────────────────────────────
    test('Fast streaming query executes via Groq stream and streams tokens progressively', () async {
      final streamed = <String>[];
      final response = await orchestrator.executeOrchestratedQuery(
        query: 'What is a cache hit?',
        systemPrompt: 'You are an academic tutor.',
        onStreamToken: (token) => streamed.add(token),
      );

      expect(response.route, CognitiveRoute.fastGroqStreaming);
      expect(response.isGroq, isTrue);
      expect(response.hasFallback, isFalse);
      expect(response.content, 'Groq streaming output');
      expect(fakeGroq.streamCalls, 1);
      expect(fakeGemini.calls, 0);
      expect(streamed, ['Groq', ' streaming', ' output']);
    });

    test('Deep reasoning query routes directly to Gemini first', () async {
      final streamed = <String>[];
      final response = await orchestrator.executeOrchestratedQuery(
        query: 'Prove that the square root of 2 is irrational step by step',
        systemPrompt: 'You are a mathematics tutor.',
        onStreamToken: (token) => streamed.add(token),
      );

      expect(response.route, CognitiveRoute.deepReasoningGemini);
      expect(response.isGemini, isTrue);
      expect(response.hasFallback, isFalse);
      expect(response.content, 'Gemini deep reasoning proof output');
      expect(fakeGemini.calls, 1);
      expect(fakeGroq.streamCalls, 0);
      expect(streamed, ['Gemini deep reasoning proof output']);
    });

    test('Fast streaming seamlessly falls back to sync Groq and Gemini on failure', () async {
      final failingGroq = FakeGroqClient(
        shouldStreamThrow: true,
        shouldSyncFail: true,
      );
      final fallbackGemini = FakeGeminiClient(
        response: 'Gemini rescued the query',
      );
      final fallbackOrchestrator = AiOrchestratorService(
        groqClient: failingGroq,
        geminiClient: fallbackGemini,
      );

      final response = await fallbackOrchestrator.executeOrchestratedQuery(
        query: 'Explain virtual memory paging',
        systemPrompt: 'You are an OS professor.',
      );

      expect(response.route, CognitiveRoute.fastGroqStreaming);
      expect(response.isGemini, isTrue);
      expect(response.hasFallback, isTrue);
      expect(response.content, 'Gemini rescued the query');
      expect(fallbackGemini.calls, 1);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1.3 Acoustic TTS Text Sanitization (cleanSpokenText)
    // ─────────────────────────────────────────────────────────────────────────
    test('PromptBuilder.cleanSpokenText converts LaTeX math symbols to natural spoken words', () {
      const rawMath = r'The integral \int_a^b f(x) dx is \approx to the sum \sum_{i=1}^n \Delta x';
      final cleaned = PromptBuilder.cleanSpokenText(rawMath);

      expect(cleaned.contains(r'\int'), isFalse);
      expect(cleaned.contains('integral'), isTrue);
      expect(cleaned.contains('sum of'), isTrue);
      expect(cleaned.contains('approximately'), isTrue);
      expect(cleaned.contains('delta'), isTrue);
    });

    test('PromptBuilder.cleanSpokenText converts fractions and exponents into natural speech', () {
      const text = r'Here \frac{a}{b} is velocity and x^2 + y^3 is kinetic energy.';
      final cleaned = PromptBuilder.cleanSpokenText(text);

      expect(cleaned.contains('over'), isTrue);
      expect(cleaned.contains('squared'), isTrue);
      expect(cleaned.contains('cubed'), isTrue);
      expect(cleaned.contains(r'\frac'), isFalse);
    });

    test('PromptBuilder.cleanSpokenText strips markdown code blocks and raw symbols for smooth TTS', () {
      const markdown = '''
Here is the solution:
```python
def calculate():
    return 42
```
Check [Link](https://example.com) and **bold** *italic* items!
''';
      final cleaned = PromptBuilder.cleanSpokenText(markdown);

      expect(cleaned.contains('def calculate'), isFalse);
      expect(cleaned.contains('```'), isFalse);
      expect(cleaned.contains('https://'), isFalse);
      expect(cleaned.contains('**'), isFalse);
      expect(cleaned.contains('Here is the solution:'), isTrue);
      expect(cleaned.contains('bold italic items!'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1.4 Feynman-Nastaliq Bilingual Code-Switching & Timestamp Citations
    // ─────────────────────────────────────────────────────────────────────────
    test('buildChatSystemPrompt enforces 4-step Feynman scaffold and timestamp citations', () {
      final prompt = PromptBuilder.buildChatSystemPrompt(
        lectureContext: 'Lecture context with algorithms',
        language: Language.urdu,
      );

      // Feynman pedagogical scaffold
      expect(prompt.contains('FEYNMAN PEDAGOGICAL SCAFFOLD'), isTrue);
      expect(prompt.contains('Hook'), isTrue);
      expect(prompt.contains('Mechanism'), isTrue);
      expect(prompt.contains('Daily Life Anchor'), isTrue);
      expect(prompt.contains('Socratic Check'), isTrue);

      // Bilingual Nastaliq code-switching rules
      expect(prompt.contains('BILINGUAL CODE-SWITCHING'), isTrue);
      expect(prompt.contains('Deadlock'), isTrue);

      // Mandatory timestamp citations
      expect(prompt.contains('RAG CITATIONS & TIMESTAMP GROUNDING'), isTrue);
      expect(prompt.contains('[⏱️ MM:SS - Topic]'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1.5 Acoustic Noise Gate & STT Cleansing Directives
    // ─────────────────────────────────────────────────────────────────────────
    test('buildSttRefinementPrompt enforces acoustic noise filtering and filler word removal', () {
      final sttPrompt = PromptBuilder.buildSttRefinementPrompt(language: Language.urdu);

      expect(sttPrompt.contains('ACOUSTIC NOISE & FILLER PURGE'), isTrue);
      expect(sttPrompt.contains('um'), isTrue);
      expect(sttPrompt.contains('matlab'), isTrue);
      expect(sttPrompt.contains('HALLUCINATION & REPETITION GATING'), isTrue);
    });
  });
}
