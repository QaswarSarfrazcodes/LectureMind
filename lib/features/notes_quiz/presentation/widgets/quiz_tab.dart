import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared_models/flashcard.dart';
import '../../../../shared_models/quiz.dart';
import '../../../../shared_widgets/app_button.dart';
import '../../../../shared_widgets/app_card.dart';
import '../controllers/notes_quiz_controller.dart';

class QuizTab extends ConsumerStatefulWidget {
  const QuizTab({super.key});
  @override
  ConsumerState<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<QuizTab> {
  int _idx = 0;
  int _correct = 0;
  int? _picked;
  bool _revealed = false;
  bool _done = false;
  final List<QuizQuestion> _missed = [];

  void _pick(QuizQuestion q, int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (q.options[i].isCorrect) {
        _correct++;
        AppHaptics.light();
      } else {
        _missed.add(q);
        AppHaptics.medium();
        ref.read(notesQuizControllerProvider.notifier).recordQuizMiss(q);
      }
    });
  }

  void _next(int total) => setState(() {
        if (_idx >= total - 1) {
          _done = true;
          if (_correct == total) {
            AppHaptics.celebrate();
          } else {
            AppHaptics.light();
          }
        } else {
          _idx++;
          _picked = null;
          _revealed = false;
          AppHaptics.selection();
        }
      });

  void _restart() => setState(() {
        _idx = 0;
        _correct = 0;
        _picked = null;
        _revealed = false;
        _done = false;
        _missed.clear();
      });

  void _saveQuestionToFlashcards(QuizQuestion q) {
    AppHaptics.light();
    final card = Flashcard(
      id: 'fc-${DateTime.now().millisecondsSinceEpoch}',
      sourceLectureId: ref.read(notesQuizControllerProvider).lecture?.id ?? 'lec-default',
      front: q.question,
      back: '${q.correctAnswer}\n\nConcept Anchor:\n${q.explanation}',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );
    ref.read(flashcardsProvider.notifier).addOrUpdateCard(card);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Spaced Repetition (SM-2) Queue!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSocraticSheet(QuizQuestion q, int pickedIndex) {
    AppHaptics.medium();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickedText = q.options[pickedIndex].text;
    final correctOpt = q.options.firstWhere(
      (o) => o.isCorrect,
      orElse: () => q.options.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.crimsonRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Socratic Remediation Tutor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Targeted Cognitive Diagnosis & Concept Repair',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Question Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUESTION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? NeuColors.mutedBlue : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      q.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Option comparison
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text('Your Pick', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(pickedText, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text('Correct Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(correctOpt.text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Socratic Trap & Cognitive Diagnosis
              _socraticSection(
                icon: Icons.psychology_alt_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Why You Might Have Fallen for this Trap',
                body: q.explanation.isNotEmpty
                    ? 'Students often mistake "$pickedText" because it shares terminology with related concepts, confusing cause with effect.'
                    : 'This distractor option is crafted to test whether you distinguish between theoretical definitions and practical implementations.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _socraticSection(
                icon: Icons.lightbulb_rounded,
                iconColor: AppColors.crimsonRed,
                title: 'The Inviolable Core Principle',
                body: q.explanation.isNotEmpty ? q.explanation : 'Remember: ${correctOpt.text} directly dictates system behavior in this context.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _socraticSection(
                icon: Icons.quiz_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Socratic Active Recall Question',
                body: 'Under what specific conditions would your choice fail, whereas the correct answer remains guaranteed to work?',
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.style_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Add to SM-2 Spaced Repetition Queue',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveQuestionToFlashcards(q);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socraticSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(notesQuizControllerProvider);
    final quiz   = state.quiz;
    final scheme = Theme.of(context).colorScheme;

    if (quiz == null || quiz.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(AppIcons.notebook, size: 48, color: AppColors.crimsonRed),
            const SizedBox(height: 16),
            Text('No quiz generated yet', style: AppTextStyles.title(scheme.onSurface)),
            const SizedBox(height: 8),
            Text('Generate 8–12 assessment questions from this lecture.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            AppButton(
              label: 'Generate Quiz Now',
              isLoading: state.isRegenerating,
              onPressed: () => ref.read(notesQuizControllerProvider.notifier).regenerateQuiz(),
            ),
          ]),
        ),
      );
    }

    if (_done) {
      return _ScoreSummary(
        correct: _correct,
        total: quiz.questions.length,
        missed: _missed,
        state: state,
        onRestart: _restart,
        onRegenerate: () async {
          await ref.read(notesQuizControllerProvider.notifier).regenerateQuiz();
          _restart();
        },
      );
    }

    final q = quiz.questions[_idx];
    final isMcq = q.type == QuestionType.mcq;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Progress row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Question ${_idx + 1} of ${quiz.questions.length}',
              style: AppTextStyles.caption(scheme.onSurfaceVariant)),
          Text('Score: $_correct',
              style: AppTextStyles.caption(AppColors.deepCrimson)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_idx + 1) / quiz.questions.length,
          backgroundColor: scheme.surfaceContainerHighest,
          color: AppColors.crimsonRed,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        ),
        const SizedBox(height: AppDimens.space16),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.question, style: AppTextStyles.title(scheme.onSurface)),
                const SizedBox(height: AppDimens.space16),

                if (isMcq)
                  for (int i = 0; i < q.options.length; i++)
                    _OptionItem(
                      letter: String.fromCharCode(65 + i),
                      text: q.options[i].text,
                      isSelected: _picked == i,
                      isCorrect: q.options[i].isCorrect,
                      revealed: _picked != null,
                      onTap: () => _pick(q, i),
                    )
                else if (!_revealed)
                  AppButton(
                    label: 'Reveal Model Answer', isOutlined: true,
                    onPressed: () => setState(() => _revealed = true),
                  )
                else
                  _InfoBox(
                    color: AppColors.sabaqGreenLight,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Model Answer:', style: AppTextStyles.bodyStrong(AppColors.deepCrimson)),
                      const SizedBox(height: 4),
                      Text(q.correctAnswer, style: AppTextStyles.body(scheme.onSurface)),
                    ]),
                  ),

                // Explanation
                if (_picked != null && q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InfoBox(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.crimsonRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(q.explanation,
                          style: AppTextStyles.caption(scheme.onSurfaceVariant))),
                    ]),
                  ),
                ],

                // Socratic Remediation action when wrong option was picked
                if (_picked != null && isMcq && !q.options[_picked!].isCorrect) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.school_rounded, size: 16, color: AppColors.crimsonRed),
                          label: const Text(
                            'Why I Was Wrong (Socratic)',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.crimsonRed, width: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openSocraticSheet(q, _picked!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Add to Spaced Repetition (SM-2)',
                        icon: const Icon(Icons.style_rounded, color: Color(0xFF10B981), size: 18),
                        onPressed: () => _saveQuestionToFlashcards(q),
                      ),
                    ],
                  ),
                ],
              ]),
            ),
          ),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            if (_idx > 0) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onPressed: () => setState(() {
                  _idx--;
                  _picked = null;
                  _revealed = false;
                }),
              ),
              const SizedBox(width: 10),
            ],
            if (_picked != null || _revealed)
              Expanded(
                child: AppButton(
                  label: _idx == quiz.questions.length - 1 ? 'See Score Summary' : 'Next Question',
                  onPressed: () => _next(quiz.questions.length),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

// ── Score Summary ─────────────────────────────────────────────────────────────

class _TopicStat {
  const _TopicStat({
    required this.topic,
    required this.total,
    required this.correct,
  });

  final String topic;
  final int total;
  final int correct;

  double get ratio => total > 0 ? (correct / total) : 0.0;
  int get percentage => (ratio * 100).round();
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({
    required this.correct,
    required this.total,
    required this.missed,
    required this.state,
    required this.onRestart,
    required this.onRegenerate,
  });

  final int correct, total;
  final List<QuizQuestion> missed;
  final NotesQuizState state;
  final VoidCallback onRestart;
  final VoidCallback onRegenerate;

  List<_TopicStat> _extractTopicStats() {
    final questions = state.quiz?.questions ?? [];
    if (questions.isEmpty) return const [];

    final map = <String, List<QuizQuestion>>{};
    for (final q in questions) {
      final t = _inferTopic(q.question);
      map.putIfAbsent(t, () => []).add(q);
    }

    return map.entries.map((e) {
      final topicQuestions = e.value;
      final topicMissed = topicQuestions.where((q) => missed.contains(q)).length;
      final topicCorrect = topicQuestions.length - topicMissed;
      return _TopicStat(
        topic: e.key,
        total: topicQuestions.length,
        correct: topicCorrect,
      );
    }).toList();
  }

  String _inferTopic(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('memory') || lower.contains('paging') || lower.contains('virtual') || lower.contains('ram')) {
      return 'Memory Management';
    } else if (lower.contains('cpu') || lower.contains('schedul') || lower.contains('process') || lower.contains('thread')) {
      return 'Process & Concurrency';
    } else if (lower.contains('deadlock') || lower.contains('banker') || lower.contains('mutex') || lower.contains('semaphore')) {
      return 'Deadlocks & Sync';
    } else if (lower.contains('file') || lower.contains('disk') || lower.contains('storage') || lower.contains('i/o')) {
      return 'Storage & I/O Systems';
    } else {
      return 'Core Lecture Principles';
    }
  }

  void _saveAllMissedToFlashcards(BuildContext context, WidgetRef ref) {
    AppHaptics.celebrate();
    final lectureId = state.lecture?.id ?? 'lec-default';
    int count = 0;
    for (final q in missed) {
      final card = Flashcard(
        id: 'fc-${DateTime.now().millisecondsSinceEpoch}-$count',
        sourceLectureId: lectureId,
        front: q.question,
        back: '${q.correctAnswer}\n\nConcept Note:\n${q.explanation}',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      ref.read(flashcardsProvider.notifier).addOrUpdateCard(card);
      count++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved $count missed questions to Spaced Repetition (SM-2) Queue!'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total > 0 ? ((correct / total) * 100).round() : 0;
    final topicStats = _extractTopicStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Circular gauge dial
          NeuGaugeDial(
            progress: total > 0 ? (correct / total) : 0.0,
            size: 150,
            strokeWidth: 10,
            activeColor: pct >= 70 ? AppColors.success : AppColors.crimsonRed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.crimsonRed,
                  ),
                ),
                Text(
                  '$correct/$total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? NeuColors.mutedBlue : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('$correct out of $total Correct', style: AppTextStyles.headline(scheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            pct >= 70 ? 'Excellent mastery of this academic lecture!'
                : 'Great practice session — review your diagnostic weak areas below.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // ── Topic-by-Topic Mastery Diagnostic Breakdown (Phase 2 UX) ──
          if (topicStats.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded, size: 18, color: AppColors.crimsonRed),
                      const SizedBox(width: 8),
                      Text(
                        'TOPIC MASTERY DIAGNOSTIC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final stat in topicStats) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stat.topic,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: stat.percentage >= 80
                                          ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                          : stat.percentage >= 50
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
                                              : const Color(0xFFEF4444).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      stat.percentage >= 80
                                          ? 'High Mastery'
                                          : stat.percentage >= 50
                                              ? 'Developing'
                                              : 'Needs Review',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: stat.percentage >= 80
                                            ? const Color(0xFF10B981)
                                            : stat.percentage >= 50
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${stat.percentage}%',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stat.ratio,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              color: stat.percentage >= 80
                                  ? const Color(0xFF10B981)
                                  : stat.percentage >= 50
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 1-Tap Save Missed Questions to Flashcards (SM-2)
          if (missed.isNotEmpty)
            Consumer(
              builder: (context, ref, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.style_rounded, size: 18, color: Colors.white),
                  label: Text(
                    'Save ${missed.length} Missed to Flashcards (SM-2)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () => _saveAllMissedToFlashcards(context, ref),
                ),
              ),
            ),

          Consumer(
            builder: (context, ref, _) => AppButton(
              label: 'Share Quiz Results as PDF',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: () async {
                final quiz = state.quiz;
                if (quiz == null) return;
                final userSettings = ref.read(userSettingsProvider);
                await PdfExportService.shareOrPrintQuizResult(
                  title: state.lecture?.title ?? 'Quiz Assessment',
                  quiz: quiz,
                  score: correct,
                  total: total,
                  userName: userSettings.userName,
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          AppButton(
            label: 'Regenerate Quiz (New Questions)',
            icon: AppIcons.refresh,
            isOutlined: true,
            isLoading: state.isRegenerating,
            onPressed: onRegenerate,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRestart, child: const Text('Retake This Quiz')),
        ],
      ),
    );
  }
}

// ── Option item ───────────────────────────────────────────────────────────────

class _OptionItem extends StatelessWidget {
  const _OptionItem({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool isSelected, isCorrect, revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BoxDecoration decoration;
    if (revealed) {
      if (isCorrect) {
        decoration = NeuDecorations.raised(
          isDark: isDark,
          radius: 16,
          surface: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
        );
      } else if (isSelected) {
        decoration = NeuDecorations.raised(
          isDark: isDark,
          radius: 16,
          surface: isDark ? const Color(0xFF2C1014) : const Color(0xFFFFEBEE),
        );
      } else {
        decoration = NeuDecorations.raised(isDark: isDark, radius: 16);
      }
    } else if (isSelected) {
      decoration = NeuDecorations.raised(
        isDark: isDark,
        radius: 16,
        surface: isDark ? NeuColors.darkSurfaceRaised : NeuColors.lightSurface,
        withRedGlow: true,
      );
    } else {
      decoration = NeuDecorations.raised(isDark: isDark, radius: 16);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: decoration,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: revealed && isCorrect
                      ? AppColors.success
                      : (revealed && isSelected
                          ? AppColors.error
                          : (isSelected
                              ? AppColors.crimsonRed
                              : (isDark ? NeuColors.darkSunken : const Color(0xFFD6E0EC)))),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: NeuColors.crimsonGlow, blurRadius: 8, offset: Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: (revealed && (isCorrect || isSelected)) || isSelected
                          ? Colors.white
                          : (isDark ? NeuColors.iceWhite : const Color(0xFF334155)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.body(Theme.of(context).colorScheme.onSurface),
                ),
              ),
              if (revealed)
                if (isCorrect)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 22)
                else if (isSelected)
                  const Icon(Icons.cancel_rounded,
                      color: AppColors.error, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared tinted box ─────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.color, required this.child});
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: child,
      );
}
