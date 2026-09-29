import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../core/utils/app_haptics.dart';
import '../controllers/notes_quiz_controller.dart';
import '../widgets/language_toggle_pill.dart';
import '../widgets/mind_map_tab.dart';
import '../widgets/notes_tab.dart';
import '../widgets/quiz_tab.dart';

enum _NotesQuizTab { notes, mindMap, quiz }

class NotesQuizScreen extends ConsumerStatefulWidget {
  const NotesQuizScreen({super.key});

  @override
  ConsumerState<NotesQuizScreen> createState() => _NotesQuizScreenState();
}

class _NotesQuizScreenState extends ConsumerState<NotesQuizScreen> {
  _NotesQuizTab _tab = _NotesQuizTab.notes;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tab.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(_NotesQuizTab target) {
    AppHaptics.selection();
    setState(() => _tab = target);
    _pageController.animateToPage(
      target.index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesQuizControllerProvider);
    final lecture = state.lecture;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lecture != null ? lecture.title : 'Notes & Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.crimsonRed),
            tooltip: 'Export Notes & Quiz as PDF (FR-9.1)',
            onPressed: lecture != null
                ? () async {
                    AppHaptics.light();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating PDF export…')),
                    );
                    await ref.read(notesQuizControllerProvider.notifier).exportPdf();
                  }
                : null,
          ),
          if (lecture != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.space12),
              child: LanguageTogglePill(
                selected: lecture.language,
                onChanged: (lang) {
                  AppHaptics.selection();
                  ref.read(notesQuizControllerProvider.notifier).regenerateInLanguage(lang);
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (state.isRegenerating)
            const LinearProgressIndicator(
              minHeight: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.crimsonRed),
            ),
          // ── Neumorphic Segmented Tab Switcher (Image 3 style) ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: NeuDecorations.sunken(isDark: isDark, radius: 26),
              child: Row(
                children: [
                  _neuTabItem(
                    label: 'Structured Notes',
                    icon: AppIcons.notes,
                    isSelected: _tab == _NotesQuizTab.notes,
                    onTap: () => _switchTab(_NotesQuizTab.notes),
                  ),
                  _neuTabItem(
                    label: 'Visual Mind Map',
                    icon: AppIcons.brain,
                    isSelected: _tab == _NotesQuizTab.mindMap,
                    onTap: () => _switchTab(_NotesQuizTab.mindMap),
                  ),
                  _neuTabItem(
                    label: 'AI Quiz',
                    icon: AppIcons.checkCircle,
                    isSelected: _tab == _NotesQuizTab.quiz,
                    onTap: () => _switchTab(_NotesQuizTab.quiz),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) {
                AppHaptics.selection();
                setState(() => _tab = _NotesQuizTab.values[idx]);
              },
              children: const [
                NotesTab(),
                MindMapTab(),
                QuizTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _neuTabItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.crimsonRed,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: NeuColors.crimsonGlow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? NeuColors.mutedBlue : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? NeuColors.iceWhite : const Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
