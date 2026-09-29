import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../shared_widgets/async_state_views.dart';

/// Export history: past lecture notes with one-tap PDF export (notes + quiz)
/// and direct system share action (uiux.md §3.6, differentiator #7).
class ExportHistoryList extends ConsumerWidget {
  const ExportHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectures = ref.watch(lecturesProvider);
    final quizzes = ref.watch(quizzesProvider);
    final scheme = Theme.of(context).colorScheme;

    if (lectures.isEmpty) {
      return const EmptyStateView(
        icon: AppIcons.notes,
        title: 'No lectures yet',
        subtitle: 'Recorded or uploaded lectures will appear here ready for PDF export.',
      );
    }

    return Column(
      children: lectures.map((lecture) {
        final hasQuiz = quizzes.any((q) => q.lectureId == lecture.id);
        final lectureQuiz = hasQuiz ? quizzes.firstWhere((q) => q.lectureId == lecture.id) : null;

        final dateStr =
            '${lecture.createdAt.year}-${lecture.createdAt.month.toString().padLeft(2, '0')}-${lecture.createdAt.day.toString().padLeft(2, '0')}';

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimens.space8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space4),
            leading: CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Icon(AppIcons.notes, color: scheme.primary, size: AppDimens.iconSm),
            ),
            title: Text(
              lecture.title,
              style: AppTextStyles.bodyStrong(scheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$dateStr • ${lecture.sections.length} sections${hasQuiz ? ' • Quiz' : ''}',
              style: AppTextStyles.caption(scheme.onSurfaceVariant),
            ),
            trailing: IconButton(
              icon: const Icon(AppIcons.share, size: AppDimens.iconSm),
              tooltip: 'Export & Share PDF',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Generating PDF for "${lecture.title}"...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
                try {
                  await PdfExportService.shareOrPrintLecture(
                    lecture: lecture,
                    quiz: lectureQuiz,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF export error: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

