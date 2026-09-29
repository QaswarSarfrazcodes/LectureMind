import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/network/groq_client.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/utils/prompt_builder.dart';
import '../../../../shared_models/language.dart';
import '../../../../shared_models/lecture.dart';
import '../../../../shared_models/notes.dart';
import '../../../../shared_models/quiz.dart';

class NotesQuizState {
  const NotesQuizState({
    this.lecture,
    this.quiz,
    this.isRegenerating = false,
    this.isSimplifying = false,
    this.simplifiedSections = const {},
    this.missedQuestions = const [],
    this.feedbackMessage,
  });

  final Lecture? lecture;
  final Quiz? quiz;
  final bool isRegenerating;
  final bool isSimplifying;
  final Map<String, String> simplifiedSections;
  final List<QuizQuestion> missedQuestions;
  final String? feedbackMessage;

  NotesQuizState copyWith({
    Lecture? lecture, Quiz? quiz,
    bool? isRegenerating, bool? isSimplifying,
    Map<String, String>? simplifiedSections,
    List<QuizQuestion>? missedQuestions,
    String? feedbackMessage,
  }) => NotesQuizState(
        lecture: lecture ?? this.lecture,
        quiz: quiz ?? this.quiz,
        isRegenerating: isRegenerating ?? this.isRegenerating,
        isSimplifying: isSimplifying ?? this.isSimplifying,
        simplifiedSections: simplifiedSections ?? this.simplifiedSections,
        missedQuestions: missedQuestions ?? this.missedQuestions,
        feedbackMessage: feedbackMessage,
      );
}

final notesQuizControllerProvider =
    StateNotifierProvider.autoDispose<NotesQuizController, NotesQuizState>(
        (ref) => NotesQuizController(ref, ref.watch(groqClientProvider)));

class NotesQuizController extends StateNotifier<NotesQuizState> {
  NotesQuizController(this._ref, this._groq) : super(const NotesQuizState()) {
    _init();
  }

  final Ref _ref;
  final GroqClient _groq;

  void _init() {
    final lectures = _ref.read(lecturesProvider);
    if (lectures.isEmpty) return;
    final id     = _ref.read(selectedLectureIdProvider);
    final active = lectures.firstWhere((l) => l.id == id, orElse: () => lectures.first);
    final quiz   = _ref.read(quizzesProvider).firstWhere(
      (q) => q.lectureId == active.id || q.id == active.quizId,
      orElse: () => Quiz(id: 'q_${active.id}', lectureId: active.id, questions: []),
    );
    state = state.copyWith(lecture: active, quiz: quiz);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<String?> _chat(AiTaskType task, Language lang, String content,
      {bool json = false}) async {
    final res = await _groq.postChatCompletion(
      systemPrompt: PromptBuilder.buildSystemPrompt(task, lang),
      userContent: content,
      jsonMode: json, taskType: task, language: lang,
    );
    return res.isSuccess ? res.data : null;
  }

  List<QuizQuestion> _parseQuestions(String raw) {
    try {
      final q = (jsonDecode(raw) as Map<String, dynamic>)['questions'] as List? ?? [];
      return q.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  // ── ELI10 simplify ────────────────────────────────────────────────────────
  Future<void> simplifySection(NoteSection section) async {
    state = state.copyWith(isSimplifying: true);
    final lang = _ref.read(activeLanguageProvider);
    final text = await _chat(AiTaskType.eli10Simplify, lang,
        'Simplify this section clearly: ${section.title}\n${section.body}');
    state = state.copyWith(
      isSimplifying: false,
      simplifiedSections: text != null
          ? {...state.simplifiedSections, section.title: text}
          : state.simplifiedSections,
    );
  }

  // ── Regenerate notes in target language ──────────────────────────────────
  Future<void> regenerateInLanguage(Language lang) async {
    final lec = state.lecture;
    if (lec == null) return;
    state = state.copyWith(isRegenerating: true);
    _ref.read(activeLanguageProvider.notifier).state = lang;

    final raw = await _chat(AiTaskType.notesGeneration, lang,
        'Regenerate these notes completely in the requested language:\n${lec.transcript}',
        json: true);

    if (raw != null) {
      try {
        final p = jsonDecode(raw) as Map<String, dynamic>;
        final updated = lec.copyWith(
          title: p['title'] as String? ?? lec.title,
          summary: p['summary'] as String? ?? lec.summary,
          language: lang,
          sections: ((p['headings'] as List?) ?? [])
              .map((h) => NoteSection.fromJson(h as Map<String, dynamic>)).toList(),
        );
        await _ref.read(lecturesProvider.notifier).addOrUpdateLecture(updated);
        state = state.copyWith(
            lecture: updated, isRegenerating: false, simplifiedSections: {});
        return;
      } catch (_) {}
    }
    state = state.copyWith(isRegenerating: false);
  }

  // ── Regenerate quiz ───────────────────────────────────────────────────────
  Future<void> regenerateQuiz() async {
    final lec = state.lecture;
    if (lec == null) return;
    state = state.copyWith(isRegenerating: true);
    final lang = _ref.read(activeLanguageProvider);

    final raw = await _chat(AiTaskType.quizGeneration, lang,
        'Generate fresh quiz questions for this lecture:\n${lec.transcript}', json: true);

    if (raw != null) {
      final questions = _parseQuestions(raw);
      if (questions.isNotEmpty) {
        final updated =
            (state.quiz ?? Quiz(id: 'q_${lec.id}', lectureId: lec.id, questions: []))
                .copyWith(questions: questions, score: null, completed: false);
        await _ref.read(quizzesProvider.notifier).saveQuiz(updated);
        state = state.copyWith(quiz: updated, isRegenerating: false, missedQuestions: []);
        return;
      }
    }
    state = state.copyWith(isRegenerating: false);
  }

  void recordQuizMiss(QuizQuestion q) =>
      state = state.copyWith(missedQuestions: [...state.missedQuestions, q]);

  // ── PDF export ────────────────────────────────────────────────────────────
  Future<void> exportPdf() async {
    final lec = state.lecture;
    if (lec == null) return;
    await PdfExportService.shareOrPrintLecture(
      lecture: lec,
      quiz: state.quiz,
    );
  }
}
