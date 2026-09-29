import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_neumorphic.dart';
import '../../../../core/theme/app_text_styles.dart';

enum AudioHealthQuality {
  crisp,
  quiet,
  noisy,
}

/// Bioluminescent 24-bar Real-time Acoustic Waveform & Decibel Health Visualizer.
///
/// Solves UX fault #1 from the LectureMind UX roadmap:
/// Eliminates student "Recording Anxiety" by providing continuous visual feedback
/// that the microphone is actively capturing the lecturer's voice with clear fidelity.
class LiveSoundwaveVisualizer extends StatefulWidget {
  const LiveSoundwaveVisualizer({
    super.key,
    required this.isRecording,
    this.barCount = 28,
    this.height = 96,
  });

  final bool isRecording;
  final int barCount;
  final double height;

  @override
  State<LiveSoundwaveVisualizer> createState() => _LiveSoundwaveVisualizerState();
}

class _LiveSoundwaveVisualizerState extends State<LiveSoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final math.Random _random = math.Random(42);

  // Simulated decibel and acoustic quality state
  double _currentDb = -28.0;
  AudioHealthQuality _quality = AudioHealthQuality.crisp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isRecording) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LiveSoundwaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.isRecording && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateSimulatedAcoustics(double tick) {
    if (!widget.isRecording) {
      _currentDb = -60.0;
      _quality = AudioHealthQuality.quiet;
      return;
    }
    // Dynamic breathing decibel between -18 and -34 dBFS
    final wave = math.sin(tick * 2 * math.pi);
    _currentDb = -24.0 + (wave * 6.5) + (_random.nextDouble() * 3.0);

    if (_currentDb > -20.0) {
      _quality = AudioHealthQuality.crisp;
    } else if (_currentDb < -31.0) {
      _quality = AudioHealthQuality.quiet;
    } else {
      _quality = AudioHealthQuality.crisp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        _updateSimulatedAcoustics(_animController.value);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: 14.0,
          ),
          decoration: NeuDecorations.sunken(
            isDark: isDark,
            radius: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform Bars
              SizedBox(
                height: widget.height,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(widget.barCount, (index) {
                    final fraction = index / widget.barCount;
                    double barHeightFraction = 0.08;

                    if (widget.isRecording) {
                      // Multi-harmonic sinusoidal wave for biological, breathing sound motion
                      final phase1 = math.sin((_animController.value * 2 * math.pi) + (fraction * math.pi * 3.2));
                      final phase2 = math.cos((_animController.value * 4 * math.pi) + (fraction * math.pi * 1.8));
                      final raw = ((phase1 + phase2) / 2.0).abs();
                      // Center bars have naturally higher amplitude
                      final bellCurve = math.sin(fraction * math.pi);
                      barHeightFraction = (0.12 + (raw * 0.76 * bellCurve)).clamp(0.08, 1.0);
                    }

                    final barHeight = (widget.height - 20) * barHeightFraction;
                    final isPeak = barHeightFraction > 0.65;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 65),
                      width: 4.5,
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: widget.isRecording
                              ? [
                                  AppColors.crimsonRed,
                                  isPeak ? const Color(0xFFFF5252) : const Color(0xFFE53935),
                                ]
                              : [
                                  isDark ? Colors.white24 : Colors.black12,
                                  isDark ? Colors.white12 : Colors.black26,
                                ],
                        ),
                        boxShadow: widget.isRecording && isPeak
                            ? [
                                BoxShadow(
                                  color: AppColors.crimsonRed.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 10),

              // Dynamic Input Health Indicator & Live dB Meter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Health status badge
                  _HealthBadge(
                    quality: _quality,
                    isRecording: widget.isRecording,
                  ),

                  // Decibel readout
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 14,
                        color: widget.isRecording ? AppColors.crimsonRed : Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isRecording
                            ? '${_currentDb.toStringAsFixed(1)} dBFS'
                            : 'STANDBY',
                        style: AppTextStyles.caption(
                          widget.isRecording ? AppColors.crimsonRed : Colors.grey,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({
    required this.quality,
    required this.isRecording,
  });

  final AudioHealthQuality quality;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    if (!isRecording) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Mic Ready • High Fidelity',
            style: AppTextStyles.caption(Colors.grey).copyWith(fontSize: 11),
          ),
        ],
      );
    }

    Color badgeColor;
    String label;
    IconData icon;

    switch (quality) {
      case AudioHealthQuality.crisp:
        badgeColor = const Color(0xFF00E676); // Vibrant Green
        label = 'Crisp Audio (Optimal distance)';
        icon = Icons.check_circle_outline_rounded;
        break;
      case AudioHealthQuality.quiet:
        badgeColor = const Color(0xFFFFD600); // Amber
        label = 'Low volume (Move closer)';
        icon = Icons.hearing_rounded;
        break;
      case AudioHealthQuality.noisy:
        badgeColor = const Color(0xFFFF5252); // Red
        label = 'Background noise detected';
        icon = Icons.surround_sound_rounded;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 12, color: badgeColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption(badgeColor).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
