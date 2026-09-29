import 'package:flutter/material.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_neumorphic.dart';

/// Minimalist Neumorphic Card — extruded soft surface with dual shadows.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.withRedGlow = false,
    this.radius = AppDimens.radiusLg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool withRedGlow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(AppDimens.space16),
      radius: radius,
      withRedGlow: withRedGlow,
      child: child,
    );
  }
}
