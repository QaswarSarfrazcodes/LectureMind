import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_secrets.dart';
import '../../shared_models/chat_message.dart';
import '../../shared_models/flashcard.dart';
import '../../shared_models/language.dart';
import '../../shared_models/lecture.dart';
import '../../shared_models/quiz.dart';
import '../../shared_models/user_settings.dart';

/// Thin persistence layer — all domain storage goes through here.
/// Pattern: _load<T> / _save for lists; read/write wrappers for secure keys.
///
/// [_secureStorage] is nullable — on Flutter Web, pass null (the Web platform
/// does not support FlutterSecureStorage; keys come from --dart-define instead).
class LocalStorageService {
  LocalStorageService(this._prefs, this._secureStorage);

  final SharedPreferences _prefs;
  final FlutterSecureStorage? _secureStorage;

  SharedPreferences get prefs => _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kLectures        = 'lecturemind_lectures_v2';
  static const _kQuizzes         = 'lecturemind_quizzes_v2';
  static const _kFlashcards      = 'lecturemind_flashcards_v2';
  static const _kChatPrefix      = 'lecturemind_chat_v2_';
  static const _kSettings        = 'lecturemind_settings_v2';
  static const _kAssemblyAiKey   = 'sec_assemblyai_api_key';
  static const _kGroqKey         = 'sec_groq_api_key';

  // ── Generic helpers ───────────────────────────────────────────────────────
  List<T> _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson,
      List<T> Function() seed) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      final s = seed();
      _prefs.setString(key, jsonEncode(s.map((e) => (e as dynamic).toJson()).toList()));
      return s;
    }
    try {
      return (jsonDecode(raw) as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return seed();
    }
  }

  Future<void> _saveList<T>(String key, List<T> items) async =>
      _prefs.setString(key, jsonEncode(items.map((e) => (e as dynamic).toJson()).toList()));

  Future<void> _upsertById<T>(
    String key,
    T item,
    List<T> Function() loader,
    String Function(T) getId,
    T Function(Map<String, dynamic>) fromJson,
    List<T> Function() seed,
  ) async {
    final list = loader();
    final i = list.indexWhere((e) => getId(e) == getId(item));
    i >= 0 ? list[i] = item : list.insert(0, item);
    await _saveList(key, list);
  }

  // ── Secure API Keys ──────────────────────────────────────────────────────
  // On mobile: read/write from OS keychain (FlutterSecureStorage).
  // On web: _secureStorage is null; keys come from --dart-define directly.

  Future<String> getAssemblyAiKey() async {
    final store = _secureStorage;
    if (!kIsWeb && store != null) {
      try {
        final v = await store.read(key: _kAssemblyAiKey);
        if (v != null && v.trim().isNotEmpty) return v.trim();
      } catch (_) {}
    }
    return _prefs.getString(_kAssemblyAiKey) ?? AppSecrets.assemblyAiApiKey;
  }

  Future<void> saveAssemblyAiKey(String v) async {
    final clean = v.trim();
    if (clean.isEmpty) return;
    final store = _secureStorage;
    if (!kIsWeb && store != null) {
      try {
        await store.write(key: _kAssemblyAiKey, value: clean);
      } catch (_) {}
    }
    await _prefs.setString(_kAssemblyAiKey, clean);
  }

  Future<String> getGroqKey() async {
    final store = _secureStorage;
    if (!kIsWeb && store != null) {
      try {
        final v = await store.read(key: _kGroqKey);
        if (v != null && v.trim().isNotEmpty) return v.trim();
      } catch (_) {}
    }
    return _prefs.getString(_kGroqKey) ?? AppSecrets.groqApiKey;
  }

  Future<void> saveGroqKey(String v) async {
    final clean = v.trim();
    if (clean.isEmpty) return;
    final store = _secureStorage;
    if (!kIsWeb && store != null) {
      try {
        await store.write(key: _kGroqKey, value: clean);
      } catch (_) {}
    }
    await _prefs.setString(_kGroqKey, clean);
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Future<UserSettings> loadSettings() async {
    final aKey = await getAssemblyAiKey();
    final gKey = await getGroqKey();
    final raw  = _prefs.getString(_kSettings);
    if (raw == null) {
      return UserSettings(
        assemblyAiApiKey: aKey,
        groqApiKey: gKey,
        preferredLanguage: Language.english,
        streakDays: 4,
      );
    }
    try {
      return UserSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        assemblyKey: aKey,
        groqKey: gKey,
      );
    } catch (_) {
      return UserSettings(assemblyAiApiKey: aKey, groqApiKey: gKey);
    }
  }

  Future<void> saveSettings(UserSettings s) async {
    try {
      await Future.wait([
        saveAssemblyAiKey(s.assemblyAiApiKey),
        saveGroqKey(s.groqApiKey),
      ]);
    } catch (_) {}
    await _prefs.setString(_kSettings, jsonEncode(s.toJson()));
  }

  // ── Lectures ──────────────────────────────────────────────────────────────
  List<Lecture> loadLectures() => _loadList(_kLectures, Lecture.fromJson, _seedLectures);

  Future<void> saveLectures(List<Lecture> v) => _saveList(_kLectures, v);

  Future<void> upsertLecture(Lecture l) => _upsertById(
        _kLectures, l, loadLectures, (e) => e.id, Lecture.fromJson, _seedLectures);

  // ── Quizzes ───────────────────────────────────────────────────────────────
  List<Quiz> loadQuizzes() => _loadList(_kQuizzes, Quiz.fromJson, _seedQuizzes);

  Future<void> saveQuizzes(List<Quiz> v) => _saveList(_kQuizzes, v);

  Future<void> upsertQuiz(Quiz q) async {
    final list = loadQuizzes();
    final i = list.indexWhere((e) => e.id == q.id || e.lectureId == q.lectureId);
    i >= 0 ? list[i] = q : list.insert(0, q);
    await saveQuizzes(list);
  }

  // ── Flashcards (SM-2 Spaced Repetition) ───────────────────────────────────
  List<Flashcard> loadFlashcards() =>
      _loadList(_kFlashcards, Flashcard.fromJson, () => const []);

  Future<void> saveFlashcards(List<Flashcard> cards) =>
      _saveList(_kFlashcards, cards);

  Future<void> upsertFlashcard(Flashcard card) async {
    final list = List<Flashcard>.from(loadFlashcards());
    final i = list.indexWhere((c) => c.id == card.id);
    if (i >= 0) {
      list[i] = card;
    } else {
      list.insert(0, card);
    }
    await saveFlashcards(list);
  }

  // ── Chat Messages ─────────────────────────────────────────────────────────
  List<ChatMessage> loadChatMessages(String lectureId) {
    final raw = _prefs.getString('$_kChatPrefix$lectureId');
    if (raw == null) return _seedChat(lectureId);
    try {
      return (jsonDecode(raw) as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChatMessages(String lectureId, List<ChatMessage> msgs) =>
      _prefs.setString('$_kChatPrefix$lectureId',
          jsonEncode(msgs.map((m) => m.toJson()).toList()));

  Future<void> addChatMessage(ChatMessage msg) async {
    final list = loadChatMessages(msg.lectureId)..add(msg);
    await saveChatMessages(msg.lectureId, list);
  }

  Future<void> clearChatMessages(String lectureId) =>
      _prefs.remove('$_kChatPrefix$lectureId');

  // ── Seed Data (Clean startup with zero mock data) ─────────────────────────
  List<Lecture> _seedLectures() => const [];
  List<Quiz> _seedQuizzes() => const [];
  List<ChatMessage> _seedChat(String lectureId) => const [];
}
