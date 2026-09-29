import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_providers.dart';
import 'core/config/app_secrets.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage_service.dart';
import 'core/theme/app_colors.dart';

// ──────────────────────────────────────────────────────────────────────────────
// API keys are injected via --dart-define at build time (see .env.example).
// On mobile they are additionally encrypted via FlutterSecureStorage.
// On web, dart-define values are compiled into the JS bundle (no persistent
// storage needed since the session is ephemeral).
//
// ⚠️  SECURITY: Never hardcode keys here. Use --dart-define in your CI/CD.
// ──────────────────────────────────────────────────────────────────────────────
const _kSeededFlag = 'lecturemind_keys_seeded_v2';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  LocalStorageService storageService;

  if (kIsWeb) {
    // Flutter Web: FlutterSecureStorage is not available.
    // Use SharedPreferences only (keys come from --dart-define, not stored).
    storageService = LocalStorageService(prefs, null);
  } else {
    // Mobile: Encrypt keys in OS keychain on first launch.
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    storageService = LocalStorageService(prefs, secureStorage);

    // Seed keys from --dart-define into keychain exactly once.
    final alreadySeeded = prefs.getBool(_kSeededFlag) ?? false;
    if (!alreadySeeded && AppSecrets.allKeysConfigured) {
      final existingAssembly =
          await secureStorage.read(key: 'sec_assemblyai_api_key') ?? '';
      final existingGroq =
          await secureStorage.read(key: 'sec_groq_api_key') ?? '';

      if (existingAssembly.isEmpty) {
        await secureStorage.write(
            key: 'sec_assemblyai_api_key',
            value: AppSecrets.assemblyAiApiKey);
      }
      if (existingGroq.isEmpty) {
        await secureStorage.write(
            key: 'sec_groq_api_key', value: AppSecrets.groqApiKey);
      }
      await prefs.setBool(_kSeededFlag, true);
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const LectureMindApp(),
    ),
  );
}

/// Root widget — reactive theme + GoRouter.
class LectureMindApp extends ConsumerWidget {
  const LectureMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return MaterialApp.router(
      title: 'LectureMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
