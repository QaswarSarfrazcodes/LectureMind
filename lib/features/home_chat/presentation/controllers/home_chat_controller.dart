import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/utils/prompt_builder.dart';
import '../../../../shared_models/chat_message.dart';
import '../../../../shared_models/language.dart';
import '../../../../shared_models/lecture.dart';
import '../../../../core/services/lecture_chunk_service.dart';
import '../../../../core/services/ai_feedback_service.dart';
import '../../../../core/services/subject_classifier_service.dart';
import '../../../../core/services/ai_orchestrator_service.dart';
import '../../../../shared_models/ai_feedback_record.dart';

class HomeChatState {
  const HomeChatState({
    this.selectedLecture,
    this.messages = const [],
    this.activeSubjectFolder = 'All',
    this.isSending = false,
    this.isVoiceMode = false,
    this.voiceStatusMessage,
  });

  final Lecture? selectedLecture;
  final List<ChatMessage> messages;
  final String activeSubjectFolder;
  final bool isSending;
  final bool isVoiceMode;
  final String? voiceStatusMessage;

  List<ChatMessage> get filteredMessages {
    if (activeSubjectFolder == 'All') return messages;
    return messages
        .where((m) => m.subjectFolder == activeSubjectFolder)
        .toList();
  }

  HomeChatState copyWith({
    Lecture? selectedLecture,
    List<ChatMessage>? messages,
    String? activeSubjectFolder,
    bool? isSending,
    bool? isVoiceMode,
    String? voiceStatusMessage,
  }) {
    return HomeChatState(
      selectedLecture: selectedLecture ?? this.selectedLecture,
      messages: messages ?? this.messages,
      activeSubjectFolder: activeSubjectFolder ?? this.activeSubjectFolder,
      isSending: isSending ?? this.isSending,
      isVoiceMode: isVoiceMode ?? this.isVoiceMode,
      voiceStatusMessage: voiceStatusMessage,
    );
  }
}

final homeChatControllerProvider =
    StateNotifierProvider.autoDispose<HomeChatController, HomeChatState>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final chunkService = ref.watch(lectureChunkServiceProvider);
  final classifier = ref.watch(subjectClassifierServiceProvider);
  final feedback = ref.watch(aiFeedbackServiceProvider);
  final orchestrator = ref.watch(aiOrchestratorServiceProvider);
  return HomeChatController(
    ref,
    storage,
    chunkService,
    classifier,
    feedback,
    orchestrator,
  );
});

class HomeChatController extends StateNotifier<HomeChatState> {
  HomeChatController(
    this._ref,
    this._storage,
    this._chunkService,
    this._classifier,
    this._feedbackService,
    this._orchestrator,
  ) : super(const HomeChatState()) {
    Future.microtask(_initDefaultLecture);
  }

  final Ref _ref;
  final dynamic _storage;
  final LectureChunkService _chunkService;
  final SubjectClassifierService _classifier;
  final AiFeedbackService _feedbackService;
  final AiOrchestratorService _orchestrator;

  static final Lecture generalStudyLecture = Lecture(
    id: 'general_ai_tutor',
    title: 'LectureMind AI Study Assistant',
    createdAt: DateTime.now(),
    audioDurationSeconds: 0,
    language: Language.urdu,
    summary: 'Universal AI study tutor powered by Qwen & LLaMA 3.3 70B.',
    transcript: 'General Academic Knowledge Base and AI Study Mentor.',
    sections: const [],
  );

  void _initDefaultLecture() {
    final lectures = _ref.read(lecturesProvider);
    final selectedId = _ref.read(selectedLectureIdProvider);

    if (lectures.isNotEmpty) {
      final active = lectures.firstWhere(
        (l) => l.id == selectedId,
        orElse: () => lectures.first,
      );
      selectLecture(active);
    } else {
      selectLecture(generalStudyLecture);
    }
  }

  void setActiveFolder(String folder) {
    state = state.copyWith(activeSubjectFolder: folder);
  }

  void addSubjectFolder(String folderName) {
    final clean = folderName.trim();
    if (clean.isEmpty) return;
    final current = _ref.read(userSettingsProvider).subjectFolders;
    if (!current.contains(clean)) {
      final updated = List<String>.from(current)..add(clean);
      _ref.read(userSettingsProvider.notifier).updateSubjectFolders(updated);
    }
    setActiveFolder(clean);
  }

  void selectLecture(Lecture lecture) {
    Future.microtask(() {
      _ref.read(selectedLectureIdProvider.notifier).state = lecture.id;
    });
    final messages = _storage.loadChatMessages(lecture.id) as List<ChatMessage>;
    state = state.copyWith(
      selectedLecture: lecture,
      messages: messages,
    );
  }

  void startNewChat() {
    Future.microtask(() {
      _ref.read(selectedLectureIdProvider.notifier).state =
          generalStudyLecture.id;
    });
    state = state.copyWith(
      selectedLecture: generalStudyLecture,
      messages: [],
    );
  }

  Future<void> clearCurrentChat() async {
    final lectureId = state.selectedLecture?.id ?? generalStudyLecture.id;
    await _storage.clearChatMessages(lectureId);
    state = state.copyWith(messages: []);
  }

  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    final lecture = state.selectedLecture ?? generalStudyLecture;
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final folder =
        state.activeSubjectFolder == 'All' ? 'General' : state.activeSubjectFolder;

    // 1. Build multi-turn conversation history (sliding window up to last 10 messages)
    final historyTurns = <Map<String, String>>[];
    for (final m in state.messages) {
      if (m.content.trim().isNotEmpty) {
        historyTurns.add({
          'role': m.role == ChatRole.user ? 'user' : 'assistant',
          'content': m.content.trim(),
        });
      }
    }
    final safeHistory = historyTurns.length > 10
        ? historyTurns.sublist(historyTurns.length - 10)
        : historyTurns;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      lectureId: lecture.id,
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
      isVoice: isVoice,
      subjectFolder: folder,
    );

    // Initial assistant message placeholder for real-time streaming
    final assistantMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch + 1}';
    var assistantMsg = ChatMessage(
      id: assistantMsgId,
      lectureId: lecture.id,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isVoice: isVoice,
      subjectFolder: folder,
    );

    final initialList = List<ChatMessage>.from(state.messages)
      ..add(userMsg)
      ..add(assistantMsg);

    state = state.copyWith(messages: initialList, isSending: true);
    try {
      await _storage.addChatMessage(userMsg);
    } catch (_) {}

    final language = _ref.read(activeLanguageProvider);

    final String baseSystemPrompt;
    if (lecture.id == 'general_ai_tutor') {
      baseSystemPrompt = '''You are LectureMind AI, a world-class academic study assistant specialized in bilingual Urdu and English reasoning.
${PromptBuilder.buildSystemPrompt(AiTaskType.chatQa, language)}

CAPABILITIES:
- Explain complex scientific, mathematical, computer science, and humanities concepts with high clarity and depth.
- Fluently communicate in natural Urdu (نستعلیق), English, and Roman Urdu.
- Structure explanations with clear headings, bullet points, and real-world analogies.
- Maintain a warm, encouraging, pedagogical tone.''';
    } else {
      // RAG Semantic Grounding: Retrieve top 3 relevant chunks from lecture
      final ragContext = _chunkService.buildRAGContext(lecture, trimmed, topK: 3);
      baseSystemPrompt = PromptBuilder.buildChatSystemPrompt(
        lectureContext: ragContext,
        language: language,
      );
    }

    // Phase 4.3: Subject Auto-Detection & Domain Context Injection
    final domainSource = '${lecture.title} ${lecture.summary} ${lecture.transcript} $trimmed';
    final domainResult = _classifier.classify(domainSource);
    final systemPrompt = domainResult.domain != AcademicDomain.generalAcademic
        ? '$baseSystemPrompt\n\n${domainResult.domainDirective}'
        : baseSystemPrompt;

    // Phase 4.2: Dynamic Temperature Tuning (0.12 for facts, 0.20 for problems, 0.55 for analogies)
    final adaptiveTemp = PromptBuilder.getAdaptiveTemperature(trimmed, AiTaskType.chatQa);

    // 2. Execute orchestrated query (Speculative Dual-Engine: Groq Streaming vs. Gemini Deep Reasoning)
    String accumulated = '';
    final response = await _orchestrator.executeOrchestratedQuery(
      query: trimmed,
      systemPrompt: systemPrompt,
      history: safeHistory,
      language: language,
      temperature: adaptiveTemp,
      maxTokens: 1800,
      onStreamToken: (delta) {
        accumulated += delta;
        assistantMsg = assistantMsg.copyWith(content: accumulated);
        final currentMessages = List<ChatMessage>.from(state.messages);
        final idx = currentMessages.indexWhere((m) => m.id == assistantMsgId);
        if (idx != -1) {
          currentMessages[idx] = assistantMsg;
          state = state.copyWith(messages: currentMessages);
        }
      },
    );

    if (response.content.trim().isNotEmpty) {
      assistantMsg = assistantMsg.copyWith(content: response.content.trim());
      _commitAssistantResponse(assistantMsg);
      return;
    }

    // 3. Graceful Localized Fallback
    final errorText = language == Language.urdu
        ? 'معذرت، اس وقت اے آئی سرور سے رابطہ قائم نہیں ہو پا رہا ہے۔ برائے مہربانی اپنا انٹرنیٹ چیک کریں۔'
        : 'Unable to reach the AI study engine. Please verify your internet connection and try again.';
    assistantMsg = assistantMsg.copyWith(content: errorText);
    _commitAssistantResponse(assistantMsg);
  }

  void _commitAssistantResponse(ChatMessage msg) {
    final current = List<ChatMessage>.from(state.messages);
    final idx = current.indexWhere((m) => m.id == msg.id);
    if (idx != -1) {
      current[idx] = msg;
    } else {
      current.add(msg);
    }
    state = state.copyWith(messages: current, isSending: false);
    try {
      _storage.addChatMessage(msg);
    } catch (_) {}
  }

  Future<void> rateMessage(String messageId, String rating) async {
    final current = List<ChatMessage>.from(state.messages);
    final idx = current.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final updated = current[idx].copyWith(rating: rating);
      current[idx] = updated;
      state = state.copyWith(messages: current);
      final lectureId = state.selectedLecture?.id ?? generalStudyLecture.id;
      try {
        await _storage.saveChatMessages(lectureId, current);

        // Phase 4.1: Record persistent RLHF feedback loop
        String userQuestion = '';
        if (idx > 0 && current[idx - 1].role == ChatRole.user) {
          userQuestion = current[idx - 1].content;
        }
        await _feedbackService.recordFeedback(
          AiFeedbackRecord(
            id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
            messageId: messageId,
            lectureId: lectureId,
            userQuestion: userQuestion,
            aiResponse: updated.content,
            rating: rating,
            taskType: 'chatQa',
            model: 'openai/gpt-oss-120b',
            timestamp: DateTime.now(),
            subjectFolder: state.activeSubjectFolder,
          ),
        );
      } catch (_) {}
    }
  }

  void toggleVoiceMode() {
    final newMode = !state.isVoiceMode;
    state = state.copyWith(
      isVoiceMode: newMode,
      voiceStatusMessage: newMode
          ? 'Listening (Voice Agent active — speak or interrupt anytime)'
          : null,
    );
  }

  void triggerVoiceTurn(String spokenQuestion) {
    if (spokenQuestion.trim().isNotEmpty) {
      sendMessage(spokenQuestion, isVoice: true);
    }
  }
}
