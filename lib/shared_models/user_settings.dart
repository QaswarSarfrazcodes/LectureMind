import '../core/config/app_secrets.dart';
import 'language.dart';

class UserSettings {
  const UserSettings({
    this.assemblyAiApiKey = '',
    this.groqApiKey = '',
    this.preferredLanguage = Language.english,
    this.isDarkMode = false,
    this.streakDays = 4,
    this.lastStudyDate,
    this.userName = 'Scholar',
    this.userAge = 20,
    this.subjectFolders = const [
      'General',
      'Computer Science',
      'Physics & Maths',
      'Biology & Medical',
      'Urdu Literature',
    ],
  });

  final String assemblyAiApiKey;
  final String groqApiKey;
  final Language preferredLanguage;
  final bool isDarkMode;
  final int streakDays;
  final DateTime? lastStudyDate;
  final String userName;
  final int userAge;
  final List<String> subjectFolders;

  /// Effective API key: user-configured key takes precedence over build-time environment key
  String get effectiveAssemblyAiKey =>
      assemblyAiApiKey.isNotEmpty ? assemblyAiApiKey : AppSecrets.assemblyAiApiKey;

  String get effectiveGroqKey =>
      groqApiKey.isNotEmpty ? groqApiKey : AppSecrets.groqApiKey;

  bool get hasAssemblyAiKey => effectiveAssemblyAiKey.isNotEmpty;
  bool get hasGroqKey => effectiveGroqKey.isNotEmpty;

  UserSettings copyWith({
    String? assemblyAiApiKey,
    String? groqApiKey,
    Language? preferredLanguage,
    bool? isDarkMode,
    int? streakDays,
    DateTime? lastStudyDate,
    String? userName,
    int? userAge,
    List<String>? subjectFolders,
  }) {
    return UserSettings(
      assemblyAiApiKey: (assemblyAiApiKey != null && assemblyAiApiKey.trim().isNotEmpty)
          ? assemblyAiApiKey.trim()
          : this.assemblyAiApiKey,
      groqApiKey: (groqApiKey != null && groqApiKey.trim().isNotEmpty)
          ? groqApiKey.trim()
          : this.groqApiKey,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      streakDays: streakDays ?? this.streakDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      userName: userName ?? this.userName,
      userAge: userAge ?? this.userAge,
      subjectFolders: subjectFolders ?? this.subjectFolders,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferred_language': preferredLanguage.name,
        'is_dark_mode': isDarkMode,
        'streak_days': streakDays,
        'last_study_date': lastStudyDate?.toIso8601String(),
        'user_name': userName,
        'user_age': userAge,
        'subject_folders': subjectFolders,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json, {String? assemblyKey, String? groqKey}) {
    return UserSettings(
      assemblyAiApiKey: (assemblyKey != null && assemblyKey.trim().isNotEmpty)
          ? assemblyKey.trim()
          : (json['assembly_ai_key'] as String? ?? ''),
      groqApiKey: (groqKey != null && groqKey.trim().isNotEmpty)
          ? groqKey.trim()
          : (json['groq_key'] as String? ?? ''),
      preferredLanguage: Language.values.firstWhere(
        (e) => e.name == json['preferred_language'],
        orElse: () => Language.english,
      ),
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      streakDays: json['streak_days'] as int? ?? 4,
      lastStudyDate: json['last_study_date'] != null
          ? DateTime.tryParse(json['last_study_date'] as String)
          : null,
      userName: json['user_name'] as String? ?? 'Scholar',
      userAge: json['user_age'] as int? ?? 20,
      subjectFolders: (json['subject_folders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'General',
            'Computer Science',
            'Physics & Maths',
            'Biology & Medical',
            'Urdu Literature',
          ],
    );
  }
}
