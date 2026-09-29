import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_icons.dart';
import '../core/config/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../shared_models/connectivity_status.dart';

/// Shown above any action gated behind the `ConnectivityGate` — the app
/// disables the action rather than queuing it (architecture.md §6).
/// Bilingual copy per the "never silently fail" interaction principle.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);
    if (status == ConnectivityStatus.online) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(AppIcons.wifiOff,
              size: AppDimens.iconMd, color: AppColors.warning),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              'No internet — یہ عمل آف لائن دستیاب نہیں۔ Please reconnect to continue.',
              style: AppTextStyles.caption(AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
