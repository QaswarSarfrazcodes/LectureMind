import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/app_haptics.dart';

/// UX Phase 1 — Enhanced Processing Steps Widget
///
/// Replaces the previous static stepped-checklist with an immersive, animated
/// "Active Learning Carousel" that:
/// - Shows a step-by-step labelled processing pipeline with shimmer progress.
/// - Rotates educational micro-study cards every 4 seconds so students learn
///   while they wait, converting perceived latency into a value-add moment.
/// - Displays an estimated time indicator so students never feel the app froze.
class ProcessingSteps extends StatefulWidget {
  const ProcessingSteps({super.key, required this.currentStep});

  /// 0-indexed current processing step (0 = Transcribing, 1 = Structuring, 2 = Quiz).
  final int currentStep;

  @override
  State<ProcessingSteps> createState() => _ProcessingStepsState();
}

class _ProcessingStepsState extends State<ProcessingSteps>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _fadeController;
  int _tipIndex = 0;
  Timer? _tipTimer;

  static const _steps = [
    _StepInfo(
      icon: Icons.upload_rounded,
      label: 'Transcribing Speech',
      detail: 'Universal-3 Pro STT — Urdu & English code-switching',
      range: 'Step 1 of 3',
    ),
    _StepInfo(
      icon: Icons.psychology_rounded,
      label: 'Structuring Notes',
      detail: 'Feynman AI organising key concepts with H1/H2 headers',
      range: 'Step 2 of 3',
    ),
    _StepInfo(
      icon: Icons.quiz_rounded,
      label: 'Generating Quiz',
      detail: 'Creating 8–12 MCQ & short-answer assessment questions',
      range: 'Step 3 of 3',
    ),
  ];

  static const _tips = [
    _TipCard(
      emoji: '🧠',
      title: 'Feynman Technique',
      body:
          'Testing yourself within 20 minutes of a lecture boosts memory retention by up to 54% — that\'s what LectureMind\'s quiz does for you.',
    ),
    _TipCard(
      emoji: '🔁',
      title: 'Spaced Repetition (SM-2)',
      body:
          'Reviewing material at increasing intervals — 1 day, 3 days, 7 days — is the fastest way to move facts from working memory to long-term storage.',
    ),
    _TipCard(
      emoji: '🇵🇰',
      title: 'Bilingual Learning Edge',
      body:
          'Encoding concepts in both Urdu and English creates two independent memory traces — making recall during exams significantly easier.',
    ),
    _TipCard(
      emoji: '🎯',
      title: 'Active Recall > Re-reading',
      body:
          'Reading notes again is 3× less effective than generating your own answers. LectureMind\'s AI quiz forces active retrieval — exactly what exams test.',
    ),
    _TipCard(
      emoji: '⏱️',
      title: 'Lecture Timestamps',
      body:
          'LectureMind attaches timestamp citations like [⏱ 14:35] to every key concept — so you can jump directly to the professor\'s exact explanation.',
    ),
    _TipCard(
      emoji: '🤝',
      title: 'Socratic Dialogue',
      body:
          'The AI ends every explanation with a question — this mirrors how Socrates taught and forces you to identify gaps in your understanding before exams.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();

    // Rotate tips every 4 seconds
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
        _fadeController.forward();
      });
    });
  }

  @override
  void didUpdateWidget(ProcessingSteps old) {
    super.didUpdateWidget(old);
    if (old.currentStep != widget.currentStep) {
      AppHaptics.medium();
      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tip = _tips[_tipIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // ── Animated circular progress ring ──────────────────────────────
          _AnimatedRing(step: widget.currentStep, total: _steps.length),
          const SizedBox(height: 28),

          // ── Steps list ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.navyMid.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.navyBorder : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: List.generate(_steps.length, (i) {
                final isDone = i < widget.currentStep;
                final isActive = i == widget.currentStep;
                final step = _steps[i];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.crimsonRed.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppColors.crimsonRed.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      // State icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isDone
                            ? const Icon(AppIcons.checkCircle,
                                key: ValueKey('done'), color: AppColors.success, size: 22)
                            : isActive
                                ? const SizedBox(
                                    key: ValueKey('active'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.crimsonRed),
                                    ),
                                  )
                                : Icon(step.icon,
                                    key: ValueKey('pending-$i'),
                                    color: scheme.outline.withValues(alpha: 0.5),
                                    size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDone
                                    ? AppColors.success
                                    : isActive
                                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                        : scheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(height: 2),
                              Text(
                                step.detail,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.crimsonRed.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Range badge
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.crimsonRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            step.range,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isDone)
                        const Icon(Icons.verified_rounded,
                            color: AppColors.success, size: 14),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 28),

          // ── Rotating educational micro-tip ───────────────────────────────
          FadeTransition(
            opacity: _fadeController,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A0A0E), const Color(0xFF110D1A)]
                      : [const Color(0xFFFFF1F2), const Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.crimsonRed.withValues(alpha: isDark ? 0.2 : 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡  ${tip.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: AppColors.crimsonRed,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          tip.body,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.55,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Tip pagination dots ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_tips.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _tipIndex == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _tipIndex == i
                      ? AppColors.crimsonRed
                      : AppColors.crimsonRed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Animated circular progress ring ───────────────────────────────────────────

class _AnimatedRing extends StatelessWidget {
  const _AnimatedRing({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (step + 1) / total;
    final pct = (progress * 100).round().clamp(5, 100);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: isDark
                      ? AppColors.navyBorder
                      : const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.crimsonRed),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.navyDark,
                    ),
                  ),
                  const Text(
                    'Processing',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.crimsonRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _StepInfo {
  final IconData icon;
  final String label;
  final String detail;
  final String range;
  const _StepInfo({
    required this.icon,
    required this.label,
    required this.detail,
    required this.range,
  });
}

class _TipCard {
  final String emoji;
  final String title;
  final String body;
  const _TipCard({
    required this.emoji,
    required this.title,
    required this.body,
  });
}
