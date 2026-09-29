import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/network/assembly_ai_client.dart';
import '../../../../core/network/groq_client.dart';
import '../../../../core/network/gemini_client.dart';
import '../../../../core/services/web_speech/web_speech.dart';
import '../../../../core/utils/prompt_builder.dart';
import '../../../../shared_models/connectivity_status.dart';
import '../../../../shared_models/language.dart';
import '../../../../shared_models/lecture.dart';
import '../../../../shared_models/notes.dart';
import '../../../../shared_models/quiz.dart';
import '../../data/audio_recording_service.dart';

import '../../../../core/services/subject_classifier_service.dart';

enum RecordStatus { idle, recording, reviewingTranscript, processing, completed, error }

class RecordSessionState {
  const RecordSessionState({
    this.status = RecordStatus.idle,
    this.partialTranscript = '',
    this.fullTranscript = '',
    this.elapsedSeconds = 0,
    this.processingStepIndex = 0,
    this.errorMessage,
    this.createdLecture,
  });

  final RecordStatus status;
  final String partialTranscript;
  final String fullTranscript;
  final int elapsedSeconds;
  final int processingStepIndex;
  final String? errorMessage;
  final Lecture? createdLecture;

  bool get isRecording => status == RecordStatus.recording;
  bool get isReviewing => status == RecordStatus.reviewingTranscript;
  bool get isProcessing => status == RecordStatus.processing;

  RecordSessionState copyWith({
    RecordStatus? status,
    String? partialTranscript,
    String? fullTranscript,
    int? elapsedSeconds,
    int? processingStepIndex,
    String? errorMessage,
    Lecture? createdLecture,
  }) =>
      RecordSessionState(
        status: status ?? this.status,
        partialTranscript: partialTranscript ?? this.partialTranscript,
        fullTranscript: fullTranscript ?? this.fullTranscript,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        processingStepIndex: processingStepIndex ?? this.processingStepIndex,
        errorMessage: errorMessage,
        createdLecture: createdLecture ?? this.createdLecture,
      );
}

final recordSessionControllerProvider = StateNotifierProvider.autoDispose<
    RecordSessionController, RecordSessionState>((ref) =>
    RecordSessionController(
      ref,
      ref.watch(assemblyAiClientProvider),
      ref.watch(groqClientProvider),
      ref.watch(geminiClientProvider),
      AudioRecordingService(),
      ref.watch(subjectClassifierServiceProvider),
    ));

class RecordSessionController extends StateNotifier<RecordSessionState> {
  RecordSessionController(
    this._ref,
    this._assemblyAi,
    this._groq,
    this._gemini,
    this._audio,
    this._subjectClassifier,
  ) : super(const RecordSessionState());

  final Ref _ref;
  final AssemblyAiClient _assemblyAi;
  final GroqClient _groq;
  final GeminiClient _gemini;
  final AudioRecordingService _audio;
  final SubjectClassifierService _subjectClassifier;

  StreamSubscription<TranscriptSegment>? _transcriptSub;
  Timer? _timer;

  void _setError(String msg) =>
      state = state.copyWith(status: RecordStatus.error, errorMessage: msg);

  Future<void> startRecording() async {
    if (_ref.read(connectivityStatusProvider) != ConnectivityStatus.online) {
      return _setError(
          'You are offline — LectureMind needs internet to transcribe. (انٹرنیٹ کنکشن درکار ہے)');
    }

    try {
      final permitted = await _audio.hasPermission();
      if (!permitted && !kIsWeb) {
        return _setError(
            'Microphone permission required. Please grant microphone access to record lectures.');
      }

      state = const RecordSessionState(status: RecordStatus.recording);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.isRecording) {
          state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
        }
      });

      if (kIsWeb) {
        // Start native browser audio recorder
        await WebSpeechBridge.startNativeAudio();
        // Start live speech recognizer for immediate on-screen feedback
        final lang = _ref.read(activeLanguageProvider);
        WebSpeechBridge.start(
          language: lang == Language.urdu ? 'ur' : 'en',
          onResult: (text, isFinal) {
            state = state.copyWith(
              fullTranscript: text.trim(),
              partialTranscript: '',
            );
          },
          onError: (_) {},
        );
      } else {
        // 1. Start audio file recording to capture real voice bytes
        await _audio.startRecordingToFile();

        // 2. Connect real-time streaming on non-web platforms (avoids web recorder conflicts)
        final audioStream = await _audio.startStream();
        if (audioStream != null) {
          audioStream.listen(_assemblyAi.sendAudioChunk);
          _transcriptSub = _assemblyAi.startRealtimeSession().listen(
            (seg) {
              if (!seg.isFinal) {
                state = state.copyWith(partialTranscript: seg.text);
              } else {
                final full = state.fullTranscript.isEmpty
                    ? seg.text
                    : '${state.fullTranscript} ${seg.text}';
                state = state.copyWith(
                    fullTranscript: full.trim(), partialTranscript: '');
              }
            },
            onError: (_) {},
          );
        }
      }
    } catch (e) {
      _setError('Failed to start recording: $e');
    }
  }

  Future<Lecture?> stopRecording() async {
    _timer?.cancel();
    _timer = null;

    Uint8List? audioBytes;
    if (kIsWeb) {
      final jsTranscript = WebSpeechBridge.stop();
      if (jsTranscript.isNotEmpty && state.fullTranscript.isEmpty) {
        state = state.copyWith(fullTranscript: jsTranscript);
      }
      audioBytes = await WebSpeechBridge.stopNativeAudio();
    } else {
      await _transcriptSub?.cancel();
      _transcriptSub = null;
      await _assemblyAi.stopRealtimeSession();
      audioBytes = await _audio.stopAndGetBytes();
    }

    var text = state.fullTranscript.trim();
    if (state.partialTranscript.trim().isNotEmpty) {
      final partial = state.partialTranscript.trim();
      if (!text.contains(partial)) {
        text = text.isEmpty ? partial : '$text $partial';
      }
    }

    // 2. High-precision transcription via AssemblyAI 'universal-3-5-pro' if audio bytes were captured
    if (audioBytes != null && audioBytes.isNotEmpty) {
      state = state.copyWith(
        status: RecordStatus.processing,
        processingStepIndex: 0,
      );
      final res = await _assemblyAi.transcribeFile(
        fileBytes: audioBytes,
        fileName: kIsWeb ? 'recorded_lecture.webm' : 'recorded_lecture.m4a',
      );
      if (res.isSuccess && res.data != null && res.data!.trim().isNotEmpty) {
        text = res.data!.trim();
      }
    }

    if (text.isEmpty) {
      state = state.copyWith(
        status: RecordStatus.idle,
        errorMessage:
            'No speech was detected. Please check microphone permissions, record again, and speak clearly. (آواز ریکارڈ نہیں ہوئی، براہ کرم مائیک چیک کریں)',
      );
      return null;
    }

    // 3. Neural STT Post-Processing & Domain-Aware Grammar Normalization (Phase 4.3):
    // Automatically classifies subject domain and applies specialized vocabulary guards
    state = state.copyWith(
      status: RecordStatus.processing,
      processingStepIndex: 1,
    );
    final domainResult = _subjectClassifier.classify(text);
    final cleverText = await refineTranscriptWithAi(
      text,
      subjectHint: domainResult.domain != AcademicDomain.generalAcademic
          ? domainResult.domain.displayName
          : null,
    );

    state = state.copyWith(
      status: RecordStatus.reviewingTranscript,
      fullTranscript: cleverText,
      partialTranscript: '',
    );
    return null;
  }

  /// Neural STT Post-Processor & Grammar Normalizer.
  /// Fixes acoustic mis-transcriptions, removes fillers, and organizes thoughts into academic prose.
  Future<String> refineTranscriptWithAi(String text, {String? subjectHint}) async {
    final clean = text.trim();
    if (clean.isEmpty) return clean;

    try {
      final lang = _ref.read(activeLanguageProvider);
      final prompt = PromptBuilder.buildSttRefinementPrompt(
        language: lang,
        subjectHint: subjectHint,
      );

      final res = await _groq.postChatCompletion(
        systemPrompt: prompt,
        userContent: 'Raw Speech Transcript to normalize:\n"""$clean"""',
        temperature: 0.15,
        maxTokens: 2500,
        taskType: AiTaskType.sttRefinement,
        language: lang,
      );

      if (res.isSuccess && res.data != null && res.data!.trim().isNotEmpty) {
        var refined = res.data!.trim();
        if (refined.startsWith('"""') && refined.endsWith('"""') && refined.length > 6) {
          refined = refined.substring(3, refined.length - 3).trim();
        }
        return refined;
      }

      // Gemini fallback
      final geminiRes = await _gemini.generateContent(
        prompt: '$prompt\n\nRaw Speech Transcript to normalize:\n"""$clean"""',
        temperature: 0.15,
        maxTokens: 2500,
        language: lang,
      );
      if (geminiRes.isSuccess && geminiRes.data != null && geminiRes.data!.trim().isNotEmpty) {
        var refined = geminiRes.data!.trim();
        if (refined.startsWith('"""') && refined.endsWith('"""') && refined.length > 6) {
          refined = refined.substring(3, refined.length - 3).trim();
        }
        return refined;
      }
    } catch (_) {}

    return clean;
  }

  void updateTranscript(String edited) {
    state = state.copyWith(fullTranscript: edited);
  }

  Future<Lecture?> processReviewedTranscript({String? customTitle}) =>
      _processTranscript(state.fullTranscript, state.elapsedSeconds, customTitle: customTitle);

  Future<Lecture?> processUploadedText(String text, {String? customTitle}) =>
      _processTranscript(text, 120, customTitle: customTitle);

  // ── JSON Sanitizer ────────────────────────────────────────────────────────
  Map<String, dynamic>? _cleanAndParseJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var clean = raw.trim();
    clean = clean.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>'), '').trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      clean = clean.substring(start, end + 1);
    }
    try {
      final decoded = jsonDecode(clean);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  // ── Parallel Pipeline AI Helpers (Phase 2.2 & 4.2) ───────────────────────

  Future<Map<String, dynamic>?> _generateNotesAi(
    String transcript,
    Language lang,
  ) async {
    final basePrompt =
        PromptBuilder.buildSystemPrompt(AiTaskType.notesGeneration, lang);
    final domainResult = _subjectClassifier.classify(transcript);
    final notesPrompt = domainResult.domain != AcademicDomain.generalAcademic
        ? '$basePrompt\n\n${domainResult.domainDirective}'
        : basePrompt;
    final notesContent = 'Transcript to structure:\n$transcript';
    final temp = PromptBuilder.getAdaptiveTemperature(transcript, AiTaskType.notesGeneration);

    // 1. Try Groq (ultra-fast inference)
    final groqRes = await _groq.postChatCompletion(
      systemPrompt: notesPrompt,
      userContent: notesContent,
      jsonMode: true,
      maxTokens: 3500,
      temperature: temp,
      taskType: AiTaskType.notesGeneration,
      language: lang,
    );

    if (groqRes.isSuccess && groqRes.data != null) {
      final parsed = _cleanAndParseJson(groqRes.data);
      if (parsed != null && (parsed['headings'] as List?)?.isNotEmpty == true) {
        return parsed;
      }
    }

    // 2. Resilient fallback to Gemini if Groq failed or unparseable
    final geminiRes = await _gemini.generateContent(
      prompt: '$notesPrompt\n\n$notesContent',
      maxTokens: 2500,
      temperature: temp,
      language: lang,
    );
    if (geminiRes.isSuccess && geminiRes.data != null) {
      return _cleanAndParseJson(geminiRes.data);
    }

    return null;
  }

  Future<Map<String, dynamic>?> _generateQuizAi(
    String transcript,
    String? customTitle,
    Language lang,
  ) async {
    final quizPrompt =
        PromptBuilder.buildSystemPrompt(AiTaskType.quizGeneration, lang);
    final titleHint = customTitle != null ? 'Subject: $customTitle\n\n' : '';
    final quizContent =
        'Generate quiz questions for lecture:\n${titleHint}Lecture Material & Transcript:\n$transcript';
    final temp = PromptBuilder.getAdaptiveTemperature(
      customTitle ?? transcript,
      AiTaskType.quizGeneration,
    );

    // 1. Try Groq
    final quizGroq = await _groq.postChatCompletion(
      systemPrompt: quizPrompt,
      userContent: quizContent,
      jsonMode: true,
      maxTokens: 2500,
      temperature: temp,
      taskType: AiTaskType.quizGeneration,
      language: lang,
    );
    if (quizGroq.isSuccess && quizGroq.data != null) {
      final parsed = _cleanAndParseJson(quizGroq.data);
      if (parsed != null && (parsed['questions'] as List?)?.isNotEmpty == true) {
        return parsed;
      }
    }

    // 2. Gemini fallback
    final geminiQuiz = await _gemini.generateContent(
      prompt: '$quizPrompt\n\n$quizContent',
      maxTokens: 1800,
      temperature: temp,
      language: lang,
    );
    if (geminiQuiz.isSuccess && geminiQuiz.data != null) {
      return _cleanAndParseJson(geminiQuiz.data);
    }

    return null;
  }

  // ── Core pipeline ─────────────────────────────────────────────────────────
  Future<Lecture?> _processTranscript(
    String transcript,
    int duration, {
    String? customTitle,
  }) async {
    state = state.copyWith(
        status: RecordStatus.processing, processingStepIndex: 0);
    final lang = _ref.read(activeLanguageProvider);

    // Step 1 & 2 — Parallel Notes & Psychometric Quiz Generation (Phase 2.2)
    await Future.delayed(const Duration(milliseconds: 200));
    state = state.copyWith(processingStepIndex: 1);

    final parallelResults = await Future.wait([
      _generateNotesAi(transcript, lang),
      _generateQuizAi(transcript, customTitle, lang),
    ]);

    final parsedNotes = parallelResults[0];
    final parsedQuiz = parallelResults[1];

    state = state.copyWith(processingStepIndex: 2);

    var title = customTitle;
    var summary = '';
    var sections = <NoteSection>[];
    var nodes = <MindMapNode>[];

    if (parsedNotes != null) {
      title ??= parsedNotes['title'] as String?;
      summary = parsedNotes['summary'] as String? ?? '';
      final rawHeadings = parsedNotes['headings'] as List?;
      if (rawHeadings != null) {
        sections = rawHeadings
            .whereType<Map<String, dynamic>>()
            .map((h) => NoteSection.fromJson(h))
            .where((s) =>
                s.title.isNotEmpty ||
                s.bullets.isNotEmpty ||
                s.body.isNotEmpty)
            .toList();
      }
      final mm = parsedNotes['mind_map'] as Map<String, dynamic>?;
      if (mm != null) {
        final rawNodes = mm['nodes'] as List?;
        if (rawNodes != null) {
          nodes = rawNodes
              .whereType<Map<String, dynamic>>()
              .map((n) => MindMapNode.fromJson(n))
              .toList();
        }
      }
    }

    // Dynamic content extraction if AI was unavailable (Zero generic placeholders!)
    if (sections.isEmpty) {
      final sentences = transcript
          .split(RegExp(r'(?<=[.!?۔\n])\s+'))
          .map((s) => s.trim())
          .where((s) => s.length > 8)
          .toList();

      final bulletItems = <NoteBullet>[];
      for (int i = 0; i < sentences.length && i < 6; i++) {
        final sentence = sentences[i];
        final words = sentence.split(' ');
        final point = words.take(6).join(' ');
        bulletItems.add(NoteBullet(
          point: point,
          explanation: sentence,
        ));
      }

      final cleanText = transcript
          .replaceAll(
              RegExp(
                  r'\b(hello|hi|hey|ok|okay|welcome|today|we are|teaching you|this is the subject of|this is the)\b',
                  caseSensitive: false),
              '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final words = cleanText.split(' ').where((w) => w.length > 2).toList();
      final derivedTitle = title ??
          (words.isNotEmpty
              ? words
                  .take(5)
                  .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                  .join(' ')
              : 'Lecture: ${DateTime.now().toLocal().toString().split(' ')[0]}');
      title = derivedTitle;
      summary = sentences.isNotEmpty
          ? sentences.take(2).join(' ')
          : transcript;

      sections = [
        NoteSection(
          title: title,
          body: transcript,
          bullets: bulletItems.map((b) => b.point).toList(),
          bulletItems: bulletItems,
          keyTerms: sentences
              .expand((s) => s.split(' '))
              .where((w) => w.length > 5)
              .take(4)
              .toList(),
          aiSynthesis:
              'Key concepts synthesized directly from the spoken audio.',
        ),
      ];
    }

    title ??= 'Lecture: ${DateTime.now().toLocal().toString().split(' ')[0]}';
    if (summary.isEmpty) {
      summary =
          sections.first.body.isNotEmpty ? sections.first.body : transcript;
    }

    // Multi-tier Mind Map guaranteed from the actual lecture content
    if (nodes.isEmpty || nodes.length < 3) {
      nodes = [
        MindMapNode(id: 'root', label: title, tier: 0),
        for (int i = 0; i < sections.length; i++) ...[
          MindMapNode(
            id: 'sec_$i',
            label: sections[i].title,
            parentId: 'root',
            tier: 1,
          ),
          for (int j = 0; j < sections[i].bulletItems.length; j++)
            MindMapNode(
              id: 'b_${i}_$j',
              label: sections[i].bulletItems[j].point,
              parentId: 'sec_$i',
              tier: 2,
            ),
        ],
      ];
    }

    final lectureId = 'lec_${DateTime.now().millisecondsSinceEpoch}';
    final quizId = 'quiz_$lectureId';

    var questions = <QuizQuestion>[];
    if (parsedQuiz != null && parsedQuiz['questions'] is List) {
      questions = (parsedQuiz['questions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((q) => QuizQuestion.fromJson(q))
          .where((q) => q.question.isNotEmpty && q.options.isNotEmpty)
          .toList();
    }

    // Dynamic quiz questions generated from the actual lecture bullet points
    if (questions.isEmpty) {
      int qIdx = 1;
      for (final s in sections) {
        for (final b in s.bulletItems) {
          if (questions.length >= 6) break;
          questions.add(
            QuizQuestion(
              id: 'q${qIdx++}',
              type: QuestionType.mcq,
              question:
                  'In "${s.title}", what is the primary role of "${b.point}"?',
              options: [
                QuizOption(
                  text: b.explanation.isNotEmpty ? b.explanation : b.point,
                  isCorrect: true,
                ),
                const QuizOption(
                  text: 'It is an unrelated legacy protocol with no relevance',
                  isCorrect: false,
                ),
                const QuizOption(
                  text: 'It is only used for offline disk caching',
                  isCorrect: false,
                ),
                const QuizOption(
                  text: 'None of the above',
                  isCorrect: false,
                ),
              ],
              correctAnswer: b.explanation.isNotEmpty ? b.explanation : b.point,
              explanation: 'Based on the lecture notes: ${b.explanation}',
            ),
          );
        }
      }
    }

    await _ref.read(quizzesProvider.notifier).saveQuiz(
          Quiz(id: quizId, lectureId: lectureId, questions: questions),
        );

    final lecture = Lecture(
      id: lectureId,
      title: title,
      transcript: transcript,
      summary: summary,
      createdAt: DateTime.now(),
      language: lang,
      sections: sections,
      mindMapNodes: nodes,
      quizId: quizId,
      audioDurationSeconds: duration,
    );

    await _ref.read(lecturesProvider.notifier).addOrUpdateLecture(lecture);
    _ref.read(selectedLectureIdProvider.notifier).state = lectureId;

    state = state.copyWith(
      status: RecordStatus.completed,
      createdLecture: lecture,
    );
    return lecture;
  }

  void cancelSession() {
    _timer?.cancel();
    _timer = null;
    if (kIsWeb) {
      WebSpeechBridge.stop();
    }
    _audio.stop();
    _assemblyAi.stopRealtimeSession();
    _transcriptSub?.cancel();
    _transcriptSub = null;
    state = const RecordSessionState(status: RecordStatus.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (kIsWeb) {
      WebSpeechBridge.stop();
    }
    _transcriptSub?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
