import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../shared_models/language.dart';
import '../../../../shared_models/notes.dart';
import '../../../../shared_widgets/async_state_views.dart';
import '../controllers/notes_quiz_controller.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  String? _currentlyPlayingSection;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setPitch(1.15); // Feminine pitch
      await _tts.setSpeechRate(0.72); // 1.25× speed
      await _tts.setVolume(1.0);
      await _tts.setLanguage('en-GB');
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingSection = null;
          });
        }
      });
      _tts.setErrorHandler((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingSection = null;
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _speakText(String text, {String? sectionKey}) async {
    if (_isPlaying && (_currentlyPlayingSection == sectionKey || sectionKey == null)) {
      await _tts.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSection = null;
        });
      }
      return;
    }

    await _tts.stop();
    if (mounted) {
      setState(() {
        _isPlaying = true;
        _currentlyPlayingSection = sectionKey;
      });
    }

    final isUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    await _tts.setLanguage(isUrdu ? 'ur-PK' : 'en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesQuizControllerProvider);
    final lecture = state.lecture;

    if (lecture == null || lecture.sections.isEmpty) {
      return const EmptyStateView(
        icon: AppIcons.notebook,
        title: 'No notes available',
        subtitle: 'Record a lecture first — structured notes with headings and subheadings '
            'will appear here automatically.',
      );
    }

    final isUrdu = lecture.language == Language.urdu;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // ── Title & Quick Action Strip ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.title,
                      style: isUrdu
                          ? AppTextStyles.urduHeadline(scheme.onSurface)
                          : AppTextStyles.headline(scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Structured Notes & Pedagogical Breakdown',
                      style: AppTextStyles.caption(NeuColors.mutedBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Action Buttons Strip (PDF & 1.25x Voice Replay) ────────────────
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: 'Download PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  height: 46,
                  radius: 23,
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating PDF export…')),
                    );
                    await ref.read(notesQuizControllerProvider.notifier).exportPdf();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeuButton(
                  label: _isPlaying && _currentlyPlayingSection == null ? 'Stop Audio' : 'Listen Notes',
                  icon: _isPlaying && _currentlyPlayingSection == null
                      ? Icons.stop_rounded
                      : Icons.volume_up_rounded,
                  isPrimary: false,
                  height: 46,
                  radius: 23,
                  onPressed: () {
                    final sectionsText = lecture.sections.map((s) => '${s.title}. ${s.body}').join('. ');
                    final fullText = '${lecture.title}. ${lecture.summary}. $sectionsText';
                    _speakText(fullText);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Neumorphic Executive Summary Card ──────────────────────────────
          NeuCard(
            radius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.crimsonRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUrdu ? 'مجموعی خلاصہ (Executive Summary)' : 'EXECUTIVE SUMMARY',
                      style: AppTextStyles.badge(AppColors.crimsonRed),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  lecture.summary,
                  style: isUrdu
                      ? AppTextStyles.urduBody(scheme.onSurface)
                      : AppTextStyles.body(scheme.onSurface).copyWith(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Section Heading & Structured Breakdown ─────────────────────────
          Row(
            children: [
              Text(
                'HEADINGS & KEY CONCEPTS',
                style: AppTextStyles.badge(isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                '(${lecture.sections.length} Sections)',
                style: AppTextStyles.caption(isDark ? NeuColors.subtleSlate : const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (int i = 0; i < lecture.sections.length; i++) ...[
            _SectionNeuCard(
              index: i + 1,
              section: lecture.sections[i],
              isUrdu: isUrdu,
              simplified: state.simplifiedSections[lecture.sections[i].title],
              isPlayingThis: _isPlaying && _currentlyPlayingSection == lecture.sections[i].title,
              onToggleVoice: () {
                final s = lecture.sections[i];
                final bulletsText = s.bulletItems.map((b) => '${b.point}: ${b.explanation}').join('. ');
                final secText = '${s.title}. ${s.body}. $bulletsText';
                _speakText(secText, sectionKey: s.title);
              },
              onSimplify: () =>
                  ref.read(notesQuizControllerProvider.notifier).simplifySection(lecture.sections[i]),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ── Neumorphic Section Card ──────────────────────────────────────────────────
class _SectionNeuCard extends StatelessWidget {
  const _SectionNeuCard({
    required this.index,
    required this.section,
    required this.isUrdu,
    this.simplified,
    required this.isPlayingThis,
    required this.onToggleVoice,
    required this.onSimplify,
  });

  final int index;
  final NoteSection section;
  final bool isUrdu;
  final String? simplified;
  final bool isPlayingThis;
  final VoidCallback onToggleVoice;
  final VoidCallback onSimplify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeuCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheading Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section number pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.crimsonRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: NeuColors.crimsonGlow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: isUrdu
                      ? AppTextStyles.urduTitle(scheme.onSurface)
                      : AppTextStyles.title(scheme.onSurface).copyWith(fontSize: 18),
                ),
              ),
              // Section Voice Audio Replay
              NeuIconButton(
                size: 38,
                iconSize: 18,
                icon: isPlayingThis ? Icons.stop_rounded : Icons.volume_up_rounded,
                iconColor: isPlayingThis ? AppColors.crimsonRed : null,
                tooltip: 'Listen to section audio',
                onPressed: onToggleVoice,
              ),
              const SizedBox(width: 8),
              // ELI10 Simplify Button
              NeuIconButton(
                size: 38,
                iconSize: 18,
                icon: AppIcons.simplify,
                iconColor: Colors.amber,
                tooltip: 'Simplify (ELI10 Mode)',
                onPressed: onSimplify,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main body text
          Text(
            section.body,
            style: isUrdu
                ? AppTextStyles.urduBody(scheme.onSurface)
                : AppTextStyles.body(scheme.onSurface).copyWith(fontSize: 15, height: 1.6),
          ),

          // ELI10 Box (Sunken Neumorphic Container)
          if (simplified != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: NeuDecorations.sunken(isDark: isDark, radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(AppIcons.simplify, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        isUrdu ? 'آسان فہم خلاصہ (ELI10 Explanation)' : 'SIMPLIFIED (ELI10 MODE)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    simplified!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? NeuColors.iceWhite : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bullets with Deep AI Pedagogical Breakdowns
          if (section.bulletItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final b in section.bulletItems)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: NeuDecorations.raised(
                  isDark: isDark,
                  radius: 16,
                  withRim: true,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppColors.crimsonRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b.point,
                            style: (isUrdu
                                    ? AppTextStyles.urduTitle(scheme.onSurface)
                                    : AppTextStyles.title(scheme.onSurface))
                                .copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    if (b.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: NeuDecorations.sunken(isDark: isDark, radius: 10),
                        child: Text(
                          b.explanation,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? NeuColors.mutedBlue : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ] else if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final b in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.crimsonRed, fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(child: Text(b, style: AppTextStyles.body(scheme.onSurface))),
                  ],
                ),
              ),
          ],

          // Key Terms (Neumorphic Pills)
          if (section.keyTerms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: section.keyTerms.map((t) => NeuPill(
                label: t,
                isSelected: false,
                onTap: null,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
