import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared_models/language.dart';

/// Fully refactored, state-of-the-art Neumorphic Academic Profile & Settings Hub.
///
/// Features:
/// 1. Prominent 18+ Cognitive Compliance & Critical Thinking Charter
/// 2. Neumorphic Scholar Identity Card with real-time study metrics
/// 3. Core Studio Workflow Launchers (STT, PDF Reader, Mind Map JPG, AI Quiz)
/// 4. Direct Neural Engine API Vault (AssemblyAI & Groq Cloud)
/// 5. Bilingual & Theme Preferences
class ProfileProgressScreen extends ConsumerWidget {
  const ProfileProgressScreen({super.key});

  void _showProfileEditDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(userSettingsProvider);
    final nameCtrl = TextEditingController(text: settings.userName);
    final ageCtrl = TextEditingController(text: settings.userAge.toString());
    String? errorMsg;
    bool under18Warning = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(24),
              decoration: NeuDecorations.raised(
                isDark: isDark,
                radius: 24,
                surface: isDark ? NeuColors.darkSurface : NeuColors.lightSurface,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: NeuDecorations.circleRaised(
                            isDark: isDark,
                            withRedGlow: true,
                          ),
                          child: const Center(
                            child: Icon(Icons.school_rounded, color: AppColors.crimsonRed, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scholar Profile & Age Verification',
                                style: AppTextStyles.title(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
                              ),
                              Text(
                                'Higher Education AI Synthesis Gateway',
                                style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Educational Age Advisory Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: under18Warning
                              ? AppColors.crimsonRed
                              : (isDark ? NeuColors.darkLightShadow : Colors.white),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            under18Warning ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                            color: under18Warning ? AppColors.crimsonRed : const Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              under18Warning
                                  ? '⚠️ Advisory: Age below 18 detected. Cognitive scientists advise developing independent analytical thinking before adopting generative AI study tools.'
                                  : 'LectureMind is designed for adult university scholars (ages 18+). AI acts as your analytical accelerator, not a replacement for independent thought.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                color: under18Warning
                                    ? AppColors.crimsonRed
                                    : (isDark ? NeuColors.iceWhite : const Color(0xFF334155)),
                                fontWeight: under18Warning ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Full Name / Academic Identifier',
                      style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Scholar Age (Minimum 18 for full academic autonomy)',
                      style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      onChanged: (val) {
                        final parsed = int.tryParse(val.trim());
                        setModalState(() {
                          under18Warning = parsed != null && parsed < 18;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: Icon(
                          under18Warning ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                          color: under18Warning ? AppColors.crimsonRed : const Color(0xFF10B981),
                        ),
                      ),
                    ),

                    if (errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMsg!,
                        style: const TextStyle(
                          color: AppColors.crimsonRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: isDark ? NeuColors.mutedBlue : Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 12),
                        NeuButton(
                          label: 'Confirm & Save',
                          icon: Icons.check_rounded,
                          isPrimary: true,
                          height: 44,
                          radius: 22,
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final age = int.tryParse(ageCtrl.text.trim()) ?? 20;

                            if (name.isEmpty) {
                              setModalState(() => errorMsg = 'Please provide an academic name.');
                              return;
                            }
                            if (age < 18) {
                              setModalState(() {
                                errorMsg = 'Access requires age 18+ to ensure organic critical thinking is preserved.';
                                under18Warning = true;
                              });
                              return;
                            }

                            ref.read(userSettingsProvider.notifier).updateProfile(
                                  userName: name,
                                  userAge: age,
                                );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Scholar profile & 18+ verification updated!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final lectures = ref.watch(lecturesProvider);
    final quizzes = ref.watch(quizzesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NeuColors.darkCanvas : NeuColors.lightCanvas,
      appBar: AppBar(
        backgroundColor: isDark ? NeuColors.darkCanvas : NeuColors.lightCanvas,
        elevation: 0,
        title: Text(
          'Academic Profile & Studio Engine',
          style: AppTextStyles.title(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              settings.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.crimsonRed,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(userSettingsProvider.notifier).setDarkMode(!settings.isDarkMode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── 1. 18+ Cognitive Compliance & Critical Thinking Charter ─────────
              _buildAgeAdvisoryCharter(context, settings, isDark),
              const SizedBox(height: 18),

              // ── 2. Neumorphic Scholar Identity Card ─────────────────────────────
              _buildScholarIdentityCard(context, ref, settings, lectures.length, quizzes.length, isDark),
              const SizedBox(height: 24),

              // ── 3. Core Studio Workflows Section Header ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Academic Intelligence Workflows',
                    style: AppTextStyles.title(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A))
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '4 Core Pillars Active',
                      style: TextStyle(
                        color: AppColors.crimsonRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 4. Core Studio Interactive Feature Cards ───────────────────────
              _buildFeatureCardsGrid(context, isDark),
              const SizedBox(height: 24),

              // ── 5. Pedagogical Preferences (Language & Tone) ───────────────────
              _buildPreferencesCard(ref, settings, isDark),
              const SizedBox(height: 18),

              // ── 6. AI Engine & API Keys (AssemblyAI & Groq) ───────────────────
              _buildApiKeysCard(context, ref, settings, isDark),
              const SizedBox(height: 28),

              // ── 7. Footer & Compliance Note ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppColors.crimsonRed),
                        const SizedBox(width: 6),
                        Text(
                          'LectureMind Cognitive Synthesis System · Version 2.5',
                          style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Engineered exclusively for Higher Education scholars (18+) to elevate organic critical thinking.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 18+ Cognitive Compliance Banner ─────────────────────────────────────────
  Widget _buildAgeAdvisoryCharter(BuildContext context, dynamic settings, bool isDark) {
    final is18Plus = settings.userAge >= 18;

    return NeuCard(
      radius: 20,
      withRedGlow: !is18Plus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: NeuDecorations.circleRaised(
                  isDark: isDark,
                  withRedGlow: true,
                ),
                child: const Center(
                  child: Icon(Icons.verified_user_rounded, color: AppColors.crimsonRed, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '18+ Cognitive Synthesis Charter',
                      style: AppTextStyles.bodyStrong(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A))
                          .copyWith(fontSize: 13.5),
                    ),
                    Text(
                      'Higher Education Critical Thinking Mandate',
                      style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: is18Plus ? const Color(0x2210B981) : const Color(0x22EF4444),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: is18Plus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      is18Plus ? Icons.check_circle_rounded : Icons.warning_rounded,
                      size: 13,
                      color: is18Plus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      is18Plus ? 'Verified 18+' : 'Age Restricted',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: is18Plus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'LectureMind is engineered exclusively for university scholars and adult researchers. Early over-reliance on generative AI before developmental maturity impairs critical reasoning and deep self-thinking. Use LectureMind as an analytical amplifier to synthesize knowledge — never as a substitute for your own intellect.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? NeuColors.iceWhite : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scholar Identity Card ───────────────────────────────────────────────────
  Widget _buildScholarIdentityCard(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    int lectureCount,
    int quizCount,
    bool isDark,
  ) {
    return NeuCard(
      radius: 22,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: NeuDecorations.circleRaised(
                  isDark: isDark,
                  withRedGlow: true,
                ),
                child: Center(
                  child: Text(
                    settings.userName.isNotEmpty ? settings.userName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.crimsonRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.userName,
                      style: AppTextStyles.heroHeadline(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A))
                          .copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: AppColors.crimsonRed),
                        const SizedBox(width: 4),
                        Text(
                          'Age ${settings.userAge} • Higher Education Scholar',
                          style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              NeuIconButton(
                icon: Icons.edit_note_rounded,
                tooltip: 'Edit Profile & Age',
                onPressed: () => _showProfileEditDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Real-time metric pills
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Cognitive Streak',
                  value: '${settings.streakDays}🔥',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Lectures Synthesized',
                  value: '$lectureCount 📚',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Quizzes Taken',
                  value: '$quizCount 🎯',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? NeuColors.pureWhite : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? NeuColors.mutedBlue : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Core Studio Feature Cards ───────────────────────────────────────────────
  Widget _buildFeatureCardsGrid(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;

        return GridView.count(
          crossAxisCount: isWide ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: isWide ? 2.3 : 3.0,
          children: [
            _buildInteractiveStudioCard(
              icon: Icons.mic_rounded,
              iconColor: AppColors.crimsonRed,
              title: 'Live Voice Input (STT)',
              subtitle: 'AssemblyAI real-time speech transcription & lecture capture',
              buttonLabel: 'Launch STT Studio',
              onTap: () => context.go(AppRoutes.record),
              isDark: isDark,
            ),
            _buildInteractiveStudioCard(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFF97316),
              title: 'PDF & Slide Reader Studio',
              subtitle: 'Extract text, sections & knowledge from PDF & PPT files',
              buttonLabel: 'Upload Document',
              onTap: () => context.go(AppRoutes.documentStudio),
              isDark: isDark,
            ),
            _buildInteractiveStudioCard(
              icon: Icons.hub_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Mind Map & JPG Export',
              subtitle: 'Multi-tier concept tree with 1-tap instant JPG download',
              buttonLabel: 'Explore Mind Map',
              onTap: () => context.go(AppRoutes.notesQuiz),
              isDark: isDark,
            ),
            _buildInteractiveStudioCard(
              icon: Icons.quiz_rounded,
              iconColor: const Color(0xFF6366F1),
              title: 'Socratic AI Quiz Engine',
              subtitle: 'Bloom\'s taxonomy active-recall tests with dial gauge score',
              buttonLabel: 'Start AI Quiz',
              onTap: () => context.go(AppRoutes.notesQuiz),
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveStudioCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return NeuCard(
      radius: 18,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: NeuDecorations.circleRaised(
                  isDark: isDark,
                  withRedGlow: iconColor == AppColors.crimsonRed,
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? NeuColors.pureWhite : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.crimsonRed),
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark ? NeuColors.mutedBlue : const Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.crimsonRed,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.crimsonRed),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pedagogical Language & Preferences ──────────────────────────────────────
  Widget _buildPreferencesCard(WidgetRef ref, dynamic settings, bool isDark) {
    return NeuCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: NeuDecorations.circleRaised(isDark: isDark),
                child: Center(
                  child: Icon(
                    Icons.translate_rounded,
                    color: isDark ? NeuColors.iceWhite : const Color(0xFF334155),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Language Engine',
                      style: AppTextStyles.bodyStrong(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Bilingual English & Urdu code-switch support',
                      style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  label: 'English (Academic)',
                  isSelected: settings.preferredLanguage == Language.english,
                  isDark: isDark,
                  onTap: () => ref.read(userSettingsProvider.notifier).setLanguage(Language.english),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  label: 'Urdu (اردو تفہیم)',
                  isSelected: settings.preferredLanguage == Language.urdu,
                  isDark: isDark,
                  onTap: () => ref.read(userSettingsProvider.notifier).setLanguage(Language.urdu),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.crimsonRed,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: NeuColors.crimsonGlow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              )
            : BoxDecoration(
                color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                borderRadius: BorderRadius.circular(14),
              ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? NeuColors.iceWhite : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  // ── AI Engine & API Keys Card ──────────────────────────────────────────────
  Widget _buildApiKeysCard(BuildContext context, WidgetRef ref, dynamic settings, bool isDark) {
    final hasAssembly = (settings.assemblyAiApiKey as String).trim().isNotEmpty;
    final hasGroq = (settings.groqApiKey as String).trim().isNotEmpty;

    return NeuCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: NeuDecorations.circleRaised(isDark: isDark),
                child: const Center(
                  child: Icon(
                    Icons.key_rounded,
                    color: AppColors.crimsonRed,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI API Keys (AssemblyAI & Groq)',
                      style: AppTextStyles.title(isDark ? NeuColors.pureWhite : const Color(0xFF0F172A))
                          .copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Configure keys for real-time acoustic transcription & LLM synthesis',
                      style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showApiKeysModal(context, ref, settings, isDark),
                icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.crimsonRed),
                label: Text(
                  hasAssembly && hasGroq ? 'Configured' : 'Configure',
                  style: const TextStyle(color: AppColors.crimsonRed, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasAssembly ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: hasAssembly ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasAssembly ? 'AssemblyAI: Active' : 'AssemblyAI: Tap to Add',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: hasAssembly ? const Color(0xFF10B981) : (isDark ? Colors.white54 : Colors.black54),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasGroq ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: hasGroq ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasGroq ? 'Groq LLM: Active' : 'Groq LLM: Tap to Add',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: hasGroq ? const Color(0xFF10B981) : (isDark ? Colors.white54 : Colors.black54),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApiKeysModal(BuildContext context, WidgetRef ref, dynamic settings, bool isDark) {
    final assemblyCtrl = TextEditingController(text: settings.assemblyAiApiKey as String);
    final groqCtrl = TextEditingController(text: settings.groqApiKey as String);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Configure AI API Keys',
                style: AppTextStyles.title(isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'Keys are saved securely in your browser local storage.',
                style: AppTextStyles.caption(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Text('AssemblyAI API Key (Voice STT)', style: AppTextStyles.caption(isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 6),
              TextField(
                controller: assemblyCtrl,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Paste AssemblyAI API Key...',
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text('Groq API Key (Fast LLM Reasoning)', style: AppTextStyles.caption(isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 6),
              TextField(
                controller: groqCtrl,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'gsk_... (Paste Groq API Key)',
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(color: isDark ? NeuColors.mutedBlue : Colors.black54)),
                  ),
                  const SizedBox(width: 12),
                  NeuButton(
                    label: 'Save Keys',
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    height: 44,
                    radius: 22,
                    onPressed: () {
                      ref.read(userSettingsProvider.notifier).updateAssemblyAiKey(assemblyCtrl.text.trim());
                      ref.read(userSettingsProvider.notifier).updateGroqKey(groqCtrl.text.trim());
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API Keys saved successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
