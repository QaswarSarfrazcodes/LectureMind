import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Phase 2 — Frosted Glass Card widget.
///
/// Implements the "Midnight Velvet" glassmorphism aesthetic:
///   • Semi-transparent [Colors.white] fill at [glassOpacity]
///   • [BackdropFilter] Gaussian blur of [frostedBlur]
///   • Thin luminous rim border
///   • Optional neon [glowColor] box-shadow for accent elements
class VelvetGlassCard extends StatelessWidget {
  const VelvetGlassCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.glowColor,
    this.borderColor,
    this.blur = AppVelvetTokens.frostedBlur,
    this.fillOpacity = AppVelvetTokens.glassOpacity,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? glowColor;
  final Color? borderColor;
  final double blur;
  final double fillOpacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: AppVelvetTokens.frostedDecoration(
            radius: radius,
            borderColor: borderColor,
            glowColor: glowColor,
            glowBlur: 18,
          ).copyWith(
            color: Colors.white.withValues(alpha: fillOpacity),
          ),
          child: child,
        ),
      ),
    );

    return Container(
      margin: margin,
      decoration: glowColor != null
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: AppVelvetTokens.neonGlowShadow(glowColor!, blur: 22),
            )
          : null,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: card,
              ),
            )
          : card,
    );
  }
}

/// Thin animated shimmer overlay for streaming AI responses.
/// Wrap the content placeholder with this during loading / streaming.
class VelvetShimmer extends StatefulWidget {
  const VelvetShimmer({super.key, required this.child, this.isActive = true});

  final Widget child;
  final bool isActive;

  @override
  State<VelvetShimmer> createState() => _VelvetShimmerState();
}

class _VelvetShimmerState extends State<VelvetShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(
                -1.5 + (_anim.value * 4.0), 0), // sweeps left-to-right
            end: Alignment(0.5 + (_anim.value * 4.0), 0),
            colors: const [
              AppVelvetTokens.shimmerBase,
              AppVelvetTokens.shimmerHighlight,
              AppVelvetTokens.shimmerAccent,
              AppVelvetTokens.shimmerBase,
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ).createShader(bounds),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// Neon-pulsing badge indicator — used in the dock and header.
class NeonPulseBadge extends StatefulWidget {
  const NeonPulseBadge({
    super.key,
    required this.color,
    this.size = 8,
  });

  final Color color;
  final double size;

  @override
  State<NeonPulseBadge> createState() => _NeonPulseBadgeState();
}

class _NeonPulseBadgeState extends State<NeonPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3 + _ctrl.value * 0.5),
              blurRadius: 6 + _ctrl.value * 10,
              spreadRadius: _ctrl.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}
