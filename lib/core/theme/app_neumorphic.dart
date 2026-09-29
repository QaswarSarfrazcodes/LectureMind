import 'package:flutter/material.dart';

/// Minimalist Neumorphism Design System for LectureMind.
///
/// Implements dual-shadow soft extrusion ("Soft UI") inspired by:
/// - Light/Dark Neumorphic cards & dials (Alex Plyuto / Michał Malewicz style)
/// - Dark Navy Blue canvas with top-left blue highlight & bottom-right deep shadow
/// - Vibrant Crimson Red accents and crisp pure white typography
class NeuColors {
  const NeuColors._();

  // ── Dark Blue Neumorphic Canvas (Primary) ──────────────────────────────────
  static const Color darkCanvas        = Color(0xFF0F172A); // Base navy canvas
  static const Color darkSurface       = Color(0xFF131D33); // Extruded card surface
  static const Color darkSurfaceRaised = Color(0xFF16223B); // Higher layer surface
  static const Color darkSunken        = Color(0xFF0B1120); // Recessed/inner surface

  // Dark Shadows (Dual light source: top-left highlight + bottom-right shadow)
  static const Color darkLightShadow   = Color(0x2E4D7EC7); // Top-left soft highlight
  static const Color darkDarkShadow    = Color(0x9903060E); // Bottom-right deep shadow
  static const Color darkRimHighlight  = Color(0x1F7BA7E8); // Subtle rim border

  // ── Light Neumorphic Canvas (Day mode fallback) ───────────────────────────
  static const Color lightCanvas       = Color(0xFFE9EEF5);
  static const Color lightSurface      = Color(0xFFE9EEF5);
  static const Color lightSunken       = Color(0xFFDEE5EE);
  static const Color lightLightShadow  = Color(0xFFFFFFFF);
  static const Color lightDarkShadow   = Color(0x4D9BB1CE);

  // ── Vibrant Crimson Red Accents ───────────────────────────────────────────
  static const Color crimsonRed        = Color(0xFFE8192C);
  static const Color deepCrimson       = Color(0xFFBF1122);
  static const Color brightRed         = Color(0xFFFF2E44);
  static const Color crimsonGlow       = Color(0x44E8192C);

  // ── Crisp High-Contrast Typography ────────────────────────────────────────
  static const Color pureWhite         = Color(0xFFFFFFFF);
  static const Color iceWhite          = Color(0xFFE2EBF8);
  static const Color mutedBlue         = Color(0xFF8FA8CC);
  static const Color subtleSlate       = Color(0xFF5B6E8C);
}

/// Neumorphic Decoration Builders
class NeuDecorations {
  const NeuDecorations._();

  /// Raised (extruded) box decoration.
  static BoxDecoration raised({
    bool isDark = true,
    double radius = 20,
    Color? surface,
    bool withRedGlow = false,
    bool withRim = true,
    BorderRadius? customRadius,
  }) {
    final bg = surface ?? (isDark ? NeuColors.darkSurface : NeuColors.lightSurface);
    final lShadow = isDark ? NeuColors.darkLightShadow : NeuColors.lightLightShadow;
    final dShadow = isDark ? NeuColors.darkDarkShadow : NeuColors.lightDarkShadow;

    return BoxDecoration(
      color: bg,
      borderRadius: customRadius ?? BorderRadius.circular(radius),
      border: withRim
          ? Border.all(
              color: isDark ? NeuColors.darkRimHighlight : Colors.white.withValues(alpha: 0.6),
              width: 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: lShadow,
          offset: const Offset(-5, -5),
          blurRadius: 10,
        ),
        BoxShadow(
          color: dShadow,
          offset: const Offset(6, 6),
          blurRadius: 12,
        ),
        if (withRedGlow)
          const BoxShadow(
            color: NeuColors.crimsonGlow,
            blurRadius: 16,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
      ],
    );
  }

  /// Sunken (inset/recessed) box decoration for inputs, selected tabs, progress bars.
  static BoxDecoration sunken({
    bool isDark = true,
    double radius = 18,
    BorderRadius? customRadius,
  }) {
    return BoxDecoration(
      color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
      borderRadius: customRadius ?? BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF090E1A), const Color(0xFF131D33)]
            : [const Color(0xFFD6DFEC), const Color(0xFFF1F5FB)],
      ),
      border: Border.all(
        color: isDark ? const Color(0x1F3B82F6) : const Color(0x33A0AEC0),
        width: 1.2,
      ),
    );
  }

  /// Circular raised decoration (for mic, dials, circular icon buttons).
  static BoxDecoration circleRaised({
    bool isDark = true,
    Color? surface,
    bool withRedGlow = false,
  }) {
    final bg = surface ?? (isDark ? NeuColors.darkSurface : NeuColors.lightSurface);
    final lShadow = isDark ? NeuColors.darkLightShadow : NeuColors.lightLightShadow;
    final dShadow = isDark ? NeuColors.darkDarkShadow : NeuColors.lightDarkShadow;

    return BoxDecoration(
      shape: BoxShape.circle,
      color: bg,
      border: Border.all(
        color: isDark ? NeuColors.darkRimHighlight : Colors.white.withValues(alpha: 0.7),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: lShadow,
          offset: const Offset(-6, -6),
          blurRadius: 12,
        ),
        BoxShadow(
          color: dShadow,
          offset: const Offset(7, 7),
          blurRadius: 14,
        ),
        if (withRedGlow)
          const BoxShadow(
            color: NeuColors.crimsonGlow,
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
      ],
    );
  }

  /// Circular sunken decoration (recessed dial socket).
  static BoxDecoration circleSunken({bool isDark = true}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isDark ? NeuColors.darkSunken : NeuColors.lightSunken,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF070B14), const Color(0xFF121B2F)]
            : [const Color(0xFFD3DCE8), const Color(0xFFF0F4FA)],
      ),
      border: Border.all(
        color: isDark ? const Color(0x1F3B82F6) : const Color(0x33A0AEC0),
        width: 1.2,
      ),
    );
  }
}

/// Extruded Neumorphic Card with optional tap animation.
class NeuCard extends StatefulWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.radius = 20,
    this.withRedGlow = false,
    this.surfaceColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool withRedGlow;
  final Color? surfaceColor;

  @override
  State<NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<NeuCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: _isPressed
          ? NeuDecorations.sunken(isDark: isDark, radius: widget.radius)
          : NeuDecorations.raised(
              isDark: isDark,
              radius: widget.radius,
              surface: widget.surfaceColor,
              withRedGlow: widget.withRedGlow,
            ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Neumorphic Button with tactile press feeling & Crimson Red accent.
class NeuButton extends StatefulWidget {
  const NeuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.height = 52,
    this.radius = 26, // Pill by default
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double height;
  final double radius;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = widget.isPrimary
        ? NeuColors.crimsonRed
        : (isDark ? NeuColors.darkSurface : NeuColors.lightSurface);

    final textColor = widget.isPrimary
        ? NeuColors.pureWhite
        : (isDark ? NeuColors.pureWhite : NeuColors.darkCanvas);

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: widget.height,
        decoration: _isPressed
            ? NeuDecorations.sunken(isDark: isDark, radius: widget.radius)
            : NeuDecorations.raised(
                isDark: isDark,
                radius: widget.radius,
                surface: bg,
                withRedGlow: widget.isPrimary,
                withRim: !widget.isPrimary,
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular Neumorphic Icon Button (like the < > + in Neumorphic sample).
class NeuIconButton extends StatefulWidget {
  const NeuIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 22,
    this.iconColor,
    this.tooltip,
    this.withRedGlow = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final String? tooltip;
  final bool withRedGlow;

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.iconColor ?? (isDark ? NeuColors.pureWhite : NeuColors.darkCanvas);

    Widget btn = GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: widget.size,
        height: widget.size,
        decoration: _isPressed
            ? NeuDecorations.circleSunken(isDark: isDark)
            : NeuDecorations.circleRaised(
                isDark: isDark,
                withRedGlow: widget.withRedGlow,
              ),
        child: Center(
          child: Icon(widget.icon, size: widget.iconSize, color: color),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Neumorphic Pill Chip (for language toggles, filter tags).
class NeuPill extends StatelessWidget {
  const NeuPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: isSelected
            ? BoxDecoration(
                color: NeuColors.crimsonRed,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: NeuColors.crimsonGlow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              )
            : NeuDecorations.raised(
                isDark: isDark,
                radius: 22,
                withRim: true,
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? NeuColors.pureWhite
                    : (isDark ? NeuColors.iceWhite : NeuColors.darkCanvas),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neumorphic Sunken Input Field (matching the Input/Search in Neumorphic sample).
class NeuInputField extends StatelessWidget {
  const NeuInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: NeuDecorations.sunken(isDark: isDark, radius: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            prefixIcon!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(
                color: isDark ? NeuColors.pureWhite : NeuColors.darkCanvas,
                fontSize: 14.5,
              ),
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? NeuColors.mutedBlue : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 8),
            suffixIcon!,
          ],
        ],
      ),
    );
  }
}

/// Neumorphic Dial / Progress Gauge (exactly as seen in sample Image 1 & 2).
class NeuGaugeDial extends StatelessWidget {
  const NeuGaugeDial({
    super.key,
    required this.progress, // 0.0 to 1.0
    required this.child,
    this.size = 180,
    this.strokeWidth = 12,
    this.activeColor = NeuColors.crimsonRed,
  });

  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: NeuDecorations.circleSunken(isDark: isDark),
      padding: EdgeInsets.all(strokeWidth + 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner raised socket
          Container(
            decoration: NeuDecorations.circleRaised(isDark: isDark),
            child: Center(child: child),
          ),
          // Circular progress ring
          SizedBox(
            width: size - (strokeWidth * 2),
            height: size - (strokeWidth * 2),
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}
