import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared_models/language.dart';

/// Top-right language toggle that regenerates content in place
/// (uiux.md §3.3) — reused wherever a screen needs the same control.
class LanguageTogglePill extends StatelessWidget {
  const LanguageTogglePill({super.key, required this.selected, required this.onChanged});

  final Language selected;
  final ValueChanged<Language> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Language>(
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (context) => Language.values
          .map((lang) => PopupMenuItem(value: lang, child: Text(lang.label)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.sabaqGreenLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        ),
        child: Text(selected.label, style: AppTextStyles.caption(AppColors.sabaqGreenDark)),
      ),
    );
  }
}
