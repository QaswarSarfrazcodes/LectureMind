import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../widgets/weak_topic_list.dart';

class WeakTopicsSubScreen extends ConsumerWidget {
  const WeakTopicsSubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weak Topics & Smart Revision'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.track_changes_rounded,
                      color: AppColors.crimsonRed, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Targeted Spaced Repetition',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.jetBlack),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Topics where quiz accuracy dropped below 65% are flagged for priority spaced repetition.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Topics Requiring Attention',
              style: AppTextStyles.title(scheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Tap on any topic below to open its structured lecture notes, in-depth bullet explanations, and AI quiz.',
            style: AppTextStyles.caption(scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          const WeakTopicList(),
        ],
      ),
    );
  }
}
