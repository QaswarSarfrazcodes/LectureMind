import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../shared_models/lecture.dart';
import '../../../../shared_models/user_settings.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeNavigationDrawer extends ConsumerWidget {
  const HomeNavigationDrawer({
    super.key,
    required this.userSettings,
    required this.onEditProfile,
  });

  final UserSettings userSettings;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // Resolve user details
    final displayName = (user != null && user.displayName.trim().isNotEmpty)
        ? user.displayName
        : (user?.isAnonymous == true ? 'Guest Scholar' : userSettings.userName);
    final displayEmail = (user != null && user.email.trim().isNotEmpty)
        ? user.email
        : (user?.isAnonymous == true
            ? 'Guest Mode (محدود رسائی)'
            : 'Age: ${userSettings.userAge} • Keystore Protected');
    final avatarLetter = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'S';

    return Drawer(
      backgroundColor: isDark ? NeuColors.darkCanvas : NeuColors.lightCanvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: user?.isAnonymous == true
                        ? const Color(0xFF64748B)
                        : AppColors.crimsonRed,
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          displayEmail,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.profile);
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'AI STUDIOS & WORKFLOWS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.mic_none_rounded,
                    color: AppColors.crimsonRed,
                    title: 'Live Voice Input (STT)',
                    subtitle: 'Real-time speech-to-text recording',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.record);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFF97316),
                    title: 'PDF Reader Studio',
                    subtitle: 'Upload & read PDF, extract notes & mind map',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.documentStudio);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.hub_rounded,
                    color: const Color(0xFF6366F1),
                    title: 'Structured Notes & Mind Map',
                    subtitle: 'Hierarchical concepts, JPG export & AI quiz',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.notesQuiz);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.graphic_eq_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Voice-to-Voice AI Assistant',
                    subtitle: 'Real-time conversational speech & lecture replay',
                    onTap: () {
                      Navigator.pop(context);
                      final activeId = ref.read(selectedLectureIdProvider);
                      final lectures = ref.read(lecturesProvider);
                      final activeLec = lectures.cast<Lecture?>().firstWhere(
                            (l) => l?.id == activeId,
                            orElse: () => lectures.isNotEmpty ? lectures.first : null,
                          );
                      context.push(AppRoutes.voiceAgent, extra: activeLec?.transcript);
                    },
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'SETTINGS & PRIVACY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF38BDF8),
                    title: 'Scholar Hub & Settings (پروفائل و ترتیبات)',
                    subtitle: 'Security, notifications, languages & preferences',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.profile);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.insights_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Learning Analytics & Streaks',
                    subtitle: 'Heatmaps, retention curves & weak topics',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.analytics);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    color: AppColors.crimsonRed,
                    title: 'Sign Out (لاگ آؤٹ)',
                    subtitle: 'End current session securely',
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
        ),
      ),
      onTap: onTap,
    );
  }
}
