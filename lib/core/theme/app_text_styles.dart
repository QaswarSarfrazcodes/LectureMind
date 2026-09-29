import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text-style tokens — Minimalist Neumorphic & Modern Geometric hierarchy.
/// Uses Outfit for punchy modern headings, badges, and buttons,
/// Inter for crisp legible body and captions, and Noto Nastaliq Urdu for Urdu.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _outfit(double size, FontWeight weight, Color color, {double? letterSpacing, double? height}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);

  static TextStyle _inter(double size, FontWeight weight, Color color, {double? height}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle _nastaliq(double size, Color color) =>
      GoogleFonts.notoNastaliqUrdu(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.9,
      );

  // ── English / Latin Geometric Hierarchy ───────────────────────────────────
  static TextStyle heroHeadline(Color color) => _outfit(30, FontWeight.w800, color, letterSpacing: -0.6);
  static TextStyle headline(Color color) => _outfit(25, FontWeight.w700, color, letterSpacing: -0.4);
  static TextStyle title(Color color) => _outfit(19, FontWeight.w700, color, letterSpacing: -0.2);
  static TextStyle subtitle(Color color) => _outfit(16, FontWeight.w600, color);
  static TextStyle body(Color color) => _inter(14.5, FontWeight.w400, color, height: 1.55);
  static TextStyle bodyStrong(Color color) => _inter(14.5, FontWeight.w600, color, height: 1.5);
  static TextStyle caption(Color color) => _inter(12.5, FontWeight.w500, color);
  static TextStyle badge(Color color) => _outfit(11, FontWeight.w700, color, letterSpacing: 0.8);
  static TextStyle button(Color color) => _outfit(15, FontWeight.w700, color, letterSpacing: -0.1);

  // ── Urdu Script Content ───────────────────────────────────────────────────
  static TextStyle urduTitle(Color color) => _nastaliq(22, color);
  static TextStyle urduBody(Color color) => _nastaliq(20, color);
  static TextStyle urduHeadline(Color color) => _nastaliq(26, color);
}

