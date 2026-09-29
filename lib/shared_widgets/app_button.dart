import 'package:flutter/material.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_neumorphic.dart';

/// Minimalist Neumorphic Button — keeps tactile extrusion and loading consistent.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: NeuButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isPrimary: !isOutlined,
        isLoading: isLoading,
        height: AppDimens.minTapTarget,
        radius: AppDimens.radiusMd,
      ),
    );
  }
}
