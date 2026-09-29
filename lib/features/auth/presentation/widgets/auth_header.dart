import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.urduSubtitle = 'اپنا لیکچر، اپنی زبان',
  });

  final String title;
  final String subtitle;
  final String urduSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing brand badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.crimsonRed, AppColors.deepCrimson],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimsonRed.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            AppIcons.brain,
            size: 38,
            color: AppColors.pureWhite,
          ),
        ),
        const SizedBox(height: AppDimens.space16),

        // Brand Name
        Text(
          'LectureMind',
          style: AppTextStyles.heroHeadline(AppColors.pureWhite).copyWith(
            letterSpacing: -0.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppDimens.space4),

        // Bilingual tagline
        Text(
          urduSubtitle,
          style: AppTextStyles.body(AppColors.crimsonRed).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: AppDimens.space24),

        // Screen Title
        Text(
          title,
          style: AppTextStyles.headline(AppColors.pureWhite).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.space8),

        // Screen Subtitle
        Text(
          subtitle,
          style: AppTextStyles.body(AppColors.darkTextSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
