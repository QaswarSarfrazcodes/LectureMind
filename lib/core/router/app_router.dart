import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home_chat/presentation/screens/home_chat_screen.dart';
import '../../features/notes_quiz/presentation/screens/notes_quiz_screen.dart';
import '../../features/profile_progress/presentation/screens/profile_progress_screen.dart';
import '../../features/profile_progress/presentation/screens/profile_settings_screen.dart';
import '../../features/record_process/presentation/screens/record_process_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/voice_agent/presentation/screens/voice_agent_screen.dart';
import '../../features/document_studio/presentation/screens/document_studio_screen.dart';
import '../../shared_widgets/app_shell.dart';

/// Route paths as typed constants.
class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const record = '/record';
  static const documentStudio = '/document-studio';
  static const notesQuiz = '/notes-quiz';
  static const profile = '/profile';
  static const analytics = '/analytics';
  static const voiceAgent = '/voice-agent';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.voiceAgent,
      builder: (context, state) {
        final lectureContext = state.extra as String?;
        return VoiceAgentScreen(lectureContext: lectureContext);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeChatScreen(),
        ),
        GoRoute(
          path: AppRoutes.record,
          builder: (context, state) => const RecordProcessScreen(),
        ),
        GoRoute(
          path: AppRoutes.documentStudio,
          builder: (context, state) => const DocumentStudioScreen(),
        ),
        GoRoute(
          path: AppRoutes.notesQuiz,
          builder: (context, state) => const NotesQuizScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.analytics,
          builder: (context, state) => const ProfileProgressScreen(),
        ),
      ],
    ),
  ],
);
