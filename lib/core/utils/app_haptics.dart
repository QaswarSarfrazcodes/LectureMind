import 'package:flutter/services.dart';

/// Systemic Micro-Haptics Engine.
///
/// Solves UX fault #5 from the LectureMind UX roadmap:
/// Provides tactile weight and physical sensory confirmation to eliminate
/// double-taps, confirm audio capture start/stop, and celebrate academic milestones.
class AppHaptics {
  const AppHaptics._();

  /// Soft click for low-friction interactions: navigation tab switch, pill selection,
  /// carousel paging.
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Haptics might be unavailable on desktop or test runners; fail silently
    }
  }

  /// Light tactile pop: tapping prompt suggestions, message copy, chip filter.
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium tactile pulse: starting/stopping recording, sending AI message,
  /// switching language modes.
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy tactile thud: destructive actions, resetting chat, clearing session.
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Celebratory double pulse: when student achieves 100% on a quiz or
  /// lecture processing successfully finishes.
  static Future<void> celebrate() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Subtle error / warning vibration when an action is rejected or mic is muted.
  static Future<void> warning() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
