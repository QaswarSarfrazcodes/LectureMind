import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/config/app_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../widgets/streak_heatmap.dart';

class ActivityProgressSubScreen extends ConsumerWidget {
  const ActivityProgressSubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(userSettingsProvider);
    final lectures = ref.watch(lecturesProvider);

    final totalDurationMinutes =
        lectures.fold<int>(0, (sum, l) => sum + l.audioDurationSeconds) ~/ 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Study Progress'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // Stat Highlights Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Study Streak',
                  value: '${settings.streakDays} Days',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.crimsonRed,
                  subtext: 'Active consistency',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Recorded Notes',
                  value: '${lectures.length}',
                  icon: Icons.mic_none_rounded,
                  iconColor: const Color(0xFF2563EB),
                  subtext: 'Sessions saved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Audio Processed',
                  value: '$totalDurationMinutes min',
                  icon: Icons.headphones_rounded,
                  iconColor: const Color(0xFF059669),
                  subtext: 'Total listening',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _StatCard(
                  label: 'Retention Score',
                  value: '92%',
                  icon: Icons.psychology_rounded,
                  iconColor: Color(0xFF7C3AED),
                  subtext: 'Active recall',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Heatmap Section
          Text('Study Consistency Heatmap',
              style: AppTextStyles.title(scheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Visual log of your daily lecture recordings, structured notes, and quizzes.',
            style: AppTextStyles.caption(scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const StreakHeatmap(),
          const SizedBox(height: 24),

          // Daily Target Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weekly Study Goal',
                        style: AppTextStyles.bodyStrong(scheme.onSurface)),
                    const Text('5 / 7 Days',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.crimsonRed)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 5 / 7,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: AppColors.crimsonRed,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep up the momentum! Study for at least 15 minutes today to extend your streak.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.subtext,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.jetBlack)),
          const SizedBox(height: 2),
          Text(subtext,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
