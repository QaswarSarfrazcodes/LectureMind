import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_neumorphic.dart';

class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.isRecording,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isRecording;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = widget.isRecording ? 1.0 + (_pulseController.value * 0.06) : 1.0;
        final glowAlpha = widget.isRecording ? 0.35 + (_pulseController.value * 0.30) : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 150,
            height: 150,
            // ── Outer Sunken Dial Socket (Image 1 & 2 style) ───────────────
            decoration: NeuDecorations.circleSunken(isDark: isDark),
            padding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing ring when recording
                if (widget.isRecording)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimsonRed.withValues(alpha: glowAlpha),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                // ── Inner Extruded Raised Circular Button ────────────────────
                GestureDetector(
                  onTap: widget.isEnabled ? widget.onPressed : null,
                  child: Container(
                    width: 114,
                    height: 114,
                    decoration: widget.isRecording
                        ? const BoxDecoration(
                            shape: BoxShape.circle,
                            color: NeuColors.crimsonRed,
                            boxShadow: [
                              BoxShadow(
                                color: NeuColors.crimsonGlow,
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: Offset(0, 4),
                              ),
                            ],
                          )
                        : NeuDecorations.circleRaised(
                            isDark: isDark,
                            surface: isDark ? NeuColors.darkSurfaceRaised : NeuColors.lightSurface,
                            withRedGlow: false,
                          ),
                    child: Center(
                      child: widget.isRecording
                          ? const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 48,
                            )
                          : SvgPicture.asset(
                              'assets/icon-mic-transcribe.svg',
                              width: 44,
                              height: 44,
                              colorFilter: const ColorFilter.mode(
                                AppColors.crimsonRed,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
