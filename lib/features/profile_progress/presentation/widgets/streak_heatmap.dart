import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/config/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Streak calendar heatmap (uiux.md §3.6) displaying active streak count
/// and interactive activity calendar using `table_calendar`.
class StreakHeatmap extends ConsumerWidget {
  const StreakHeatmap({super.key});

  bool _isActiveDay(DateTime day, int streakDays) {
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(day.year, day.month, day.day))
        .inDays;
    final activeCount = streakDays.clamp(1, 30);
    return diff >= 0 && diff < activeCount;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      padding: const EdgeInsets.all(AppDimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sabaqGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${settings.streakDays} Day Streak!',
                      style: AppTextStyles.bodyStrong(AppColors.sabaqGreen),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Keep going every day!',
                style: AppTextStyles.caption(scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          TableCalendar(
            firstDay: DateTime(now.year, now.month - 1, 1),
            lastDay: now,
            focusedDay: now,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (!_isActiveDay(day, settings.streakDays)) return null;
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.sabaqGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

