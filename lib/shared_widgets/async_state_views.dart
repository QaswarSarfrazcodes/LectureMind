import 'package:flutter/material.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// Every async call site shows one of these three — never a blank screen,
/// never a silent failure (coding.md §6 checklist, uiux.md §4).

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppDimens.space16),
            Text(message!, style: AppTextStyles.body(color)),
          ],
        ],
      ),
    );
  }
}

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.wifiOff,
                size: AppDimens.iconLg, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppDimens.space12),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body(color)),
            const SizedBox(height: AppDimens.space16),
            AppButton(label: 'Retry', icon: AppIcons.refresh, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.primary),
            const SizedBox(height: AppDimens.space16),
            Text(title, style: AppTextStyles.title(scheme.onSurface)),
            const SizedBox(height: AppDimens.space8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(scheme.onSurfaceVariant)),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: AppDimens.space24),
              AppButton(label: ctaLabel!, onPressed: onCta),
            ],
          ],
        ),
      ),
    );
  }
}
