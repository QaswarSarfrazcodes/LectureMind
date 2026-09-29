// ──────────────────────────────────────────────────────────────────────────────
// app_secrets.dart — LectureMind Secure Configuration
// ──────────────────────────────────────────────────────────────────────────────
// Keys are injected at build time via --dart-define flags.
// See DEPLOYMENT.md for exact build commands with --dart-define.
//
// Local development: copy .env.example to .env and fill in your keys,
// then use the launch configuration in .vscode/launch.json.
// ──────────────────────────────────────────────────────────────────────────────
class AppSecrets {
  const AppSecrets._();

  // Injected via --dart-define at build time.
  // Provide your keys using:
  //   flutter run --dart-define=ASSEMBLYAI_API_KEY=xxx --dart-define=GROQ_API_KEY=yyy
  static const String assemblyAiApiKey = String.fromEnvironment(
    'ASSEMBLYAI_API_KEY',
    defaultValue: '',
  );

  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Returns true if voice & LLM pipelines are ready to operate.
  static bool get isVoiceConfigured => assemblyAiApiKey.isNotEmpty;
  static bool get isLlmConfigured => groqApiKey.isNotEmpty || geminiApiKey.isNotEmpty;
  static bool get allKeysConfigured => isVoiceConfigured && isLlmConfigured;

  /// Returns a masked version of a key for safe display in UI/logs.
  static String masked(String key) {
    final clean = key.trim();
    if (clean.length <= 4) return '••••';
    return '•' * (clean.length - 4) + clean.substring(clean.length - 4);
  }
}
