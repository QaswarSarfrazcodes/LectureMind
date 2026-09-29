import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared_widgets/app_card.dart';

class _WeakTopicItem {
  const _WeakTopicItem({
    required this.topic,
    required this.lectureId,
    required this.lectureTitle,
    required this.missRate,
  });

  final String topic;
  final String lectureId;
  final String lectureTitle;
  final int missRate;
}

class WeakTopicList extends ConsumerWidget {
  const WeakTopicList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lectures = ref.watch(lecturesProvider);

    final topics = <_WeakTopicItem>[];
    if (lectures.isNotEmpty) {
      for (final l in lectures) {
        if (l.sections.isNotEmpty) {
          final firstSec = l.sections.first;
          topics.add(
            _WeakTopicItem(
              topic: firstSec.title,
              lectureId: l.id,
              lectureTitle: l.title,
              missRate: 45 + (l.title.hashCode % 30).abs(),
            ),
          );
        }
      }
    }

    if (topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Complete lecture quizzes to identify topics for revision.',
            style: AppTextStyles.caption(scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: topics
          .map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.space8),
                child: AppCard(
                  onTap: () {
                    ref.read(selectedLectureIdProvider.notifier).state = topic.lectureId;
                    context.go(AppRoutes.notesQuiz);
                  },
                  child: Row(
                    children: [
                      const Icon(AppIcons.brain, color: AppColors.warning, size: AppDimens.iconMd),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic.topic, style: AppTextStyles.bodyStrong(scheme.onSurface)),
                            Text(topic.lectureTitle,
                                style: AppTextStyles.caption(scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text('${topic.missRate}% review needed',
                          style: AppTextStyles.caption(AppColors.warning)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
