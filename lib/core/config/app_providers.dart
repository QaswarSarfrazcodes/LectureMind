import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared_models/connectivity_status.dart';
import '../../shared_models/flashcard.dart';
import '../../shared_models/language.dart';
import '../../shared_models/lecture.dart';
import '../../shared_models/quiz.dart';
import '../../shared_models/user_settings.dart';
import '../network/assembly_ai_client.dart';
import '../network/groq_client.dart';
import '../network/gemini_client.dart';
import '../services/voice_agent_service.dart';
import '../services/lecture_chunk_service.dart';
import '../utils/document_parser_service.dart';
import '../../features/record_process/data/audio_recording_service.dart';
import 'app_secrets.dart';
import '../storage/local_storage_service.dart';

import '../services/ai_feedback_service.dart';
import '../services/ai_orchestrator_service.dart';
import '../services/subject_classifier_service.dart';

final lectureChunkServiceProvider = Provider<LectureChunkService>((ref) {
  return const LectureChunkService();
});

final subjectClassifierServiceProvider = Provider<SubjectClassifierService>((ref) {
  return const SubjectClassifierService();
});

final aiFeedbackServiceProvider = Provider<AiFeedbackService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AiFeedbackService(storage.prefs);
});

// ── Storage ───────────────────────────────────────────────────────────────────
final localStorageServiceProvider = Provider<LocalStorageService>((ref) =>
    throw UnimplementedError('localStorageServiceProvider must be overridden'));

// ── User Settings ─────────────────────────────────────────────────────────────
final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettings>(
        (ref) => UserSettingsNotifier(ref.watch(localStorageServiceProvider)));

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  UserSettingsNotifier(this._storage) : super(const UserSettings()) {
    _storage.loadSettings().then((s) => state = s);
  }

  final LocalStorageService _storage;

  Future<void> _update(UserSettings next) async {
    state = next;
    await _storage.saveSettings(next);
  }

  Future<void> updateAssemblyAiKey(String key) => _update(state.copyWith(assemblyAiApiKey: key.trim()));
  Future<void> updateGroqKey(String key)       => _update(state.copyWith(groqApiKey: key.trim()));
  Future<void> setLanguage(Language lang)      => _update(state.copyWith(preferredLanguage: lang));
  Future<void> setDarkMode(bool dark)          => _update(state.copyWith(isDarkMode: dark));
  Future<void> updateProfile({required String userName, required int userAge}) =>
      _update(state.copyWith(userName: userName.trim(), userAge: userAge));
  Future<void> updateSubjectFolders(List<String> folders) =>
      _update(state.copyWith(subjectFolders: folders));
  Future<void> incrementStreak()               => _update(state.copyWith(
        streakDays: state.streakDays + 1, lastStudyDate: DateTime.now()));
}

// ── Derived / client providers ────────────────────────────────────────────────
final activeLanguageProvider = StateProvider<Language>(
    (ref) => ref.watch(userSettingsProvider).preferredLanguage);

final assemblyAiClientProvider = Provider<AssemblyAiClient>((ref) {
  final key = ref.watch(userSettingsProvider.select((s) => s.assemblyAiApiKey));
  return AssemblyAiClient(apiKeyProvider: () => key.isNotEmpty ? key : AppSecrets.assemblyAiApiKey);
});

final groqClientProvider = Provider<GroqClient>((ref) {
  final key = ref.watch(userSettingsProvider.select((s) => s.groqApiKey));
  return GroqClient(apiKeyProvider: () => key.isNotEmpty ? key : AppSecrets.groqApiKey);
});

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient(apiKeyProvider: () => AppSecrets.geminiApiKey);
});

final documentParserServiceProvider = Provider<DocumentParserService>((ref) {
  return const DocumentParserService();
});

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

final voiceAgentServiceProvider = Provider<VoiceAgentService>((ref) {
  final assembly = ref.watch(assemblyAiClientProvider);
  final groq = ref.watch(groqClientProvider);
  final gemini = ref.watch(geminiClientProvider);
  final audio = ref.watch(audioRecordingServiceProvider);
  return VoiceAgentService(
    assemblyAi: assembly,
    groq: groq,
    gemini: gemini,
    audio: audio,
  );
});

final aiOrchestratorServiceProvider = Provider<AiOrchestratorService>((ref) {
  final groq = ref.watch(groqClientProvider);
  final gemini = ref.watch(geminiClientProvider);
  return AiOrchestratorService(
    groqClient: groq,
    geminiClient: gemini,
  );
});

// ── Connectivity ──────────────────────────────────────────────────────────────
final connectivityStatusProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
        (_) => ConnectivityNotifier());

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.online) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    try {
      final initial = await Connectivity().checkConnectivity();
      _updateStatus(initial);
    } catch (_) {}

    _sub = Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);
    state = hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ── Data Notifiers (Lectures / Quizzes / Flashcards / Zubaan) ─────────────────

final lecturesProvider =
    StateNotifierProvider<LecturesNotifier, List<Lecture>>(
        (ref) => LecturesNotifier(ref.watch(localStorageServiceProvider)));

class LecturesNotifier extends StateNotifier<List<Lecture>> {
  LecturesNotifier(this._s) : super([]) { state = _s.loadLectures(); }
  final LocalStorageService _s;
  Future<void> addOrUpdateLecture(Lecture l) async {
    await _s.upsertLecture(l);
    state = _s.loadLectures();
  }
}

final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, List<Quiz>>(
        (ref) => QuizzesNotifier(ref.watch(localStorageServiceProvider)));

class QuizzesNotifier extends StateNotifier<List<Quiz>> {
  QuizzesNotifier(this._s) : super([]) { state = _s.loadQuizzes(); }
  final LocalStorageService _s;
  Future<void> saveQuiz(Quiz q) async {
    await _s.upsertQuiz(q);
    state = _s.loadQuizzes();
  }
}

final flashcardsProvider =
    StateNotifierProvider<FlashcardsNotifier, List<Flashcard>>(
        (ref) => FlashcardsNotifier(ref.watch(localStorageServiceProvider)));

class FlashcardsNotifier extends StateNotifier<List<Flashcard>> {
  FlashcardsNotifier(this._s) : super([]) { state = _s.loadFlashcards(); }
  final LocalStorageService _s;

  Future<void> addOrUpdateCard(Flashcard card) async {
    await _s.upsertFlashcard(card);
    state = _s.loadFlashcards();
  }
}

// ── UI State ──────────────────────────────────────────────────────────────────
final selectedLectureIdProvider = StateProvider<String?>((ref) => 'lec-101');
