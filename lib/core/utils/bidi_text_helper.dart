import 'package:flutter/material.dart';

/// Adaptive Bidirectional (BiDi) Text Rendering Engine.
///
/// Solves UX fault #4 from the LectureMind UX roadmap:
/// Mixed English-Urdu text causes clipped diacritics (زبر/زیر/پیش) and
/// inverted punctuation when Urdu is rendered in default LTR containers.
///
/// ### Rules:
/// - If ≥30% of characters are Urdu/Arabic Unicode, force RTL alignment.
/// - Nastaliq line height is always `1.95` to prevent diacritic collisions.
/// - Technical English terms inside Urdu blocks keep their own script without distortion.
class BidiTextHelper {
  const BidiTextHelper._();

  /// Unicode range for Urdu/Arabic script characters.
  static final _urduPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');

  /// Recommended line height multiplier for Noto Nastaliq Urdu to prevent
  /// diacritic (zabar/zer/pesh/tanween) from colliding with neighboring lines.
  static const double nastaliqLineHeight = 1.95;

  /// Standard body line height for English text.
  static const double latinLineHeight = 1.55;

  /// Returns `true` if the text contains ≥30% Urdu/Arabic characters.
  static bool isUrduDominant(String text) {
    if (text.trim().isEmpty) return false;
    final totalChars = text.replaceAll(RegExp(r'\s'), '').length;
    if (totalChars == 0) return false;
    final urduChars = _urduPattern.allMatches(text).length;
    return (urduChars / totalChars) >= 0.30;
  }

  /// Infer the correct [TextDirection] based on the dominant script in [text].
  static TextDirection directionOf(String text) =>
      isUrduDominant(text) ? TextDirection.rtl : TextDirection.ltr;

  /// Infer the correct [TextAlign] based on the dominant script in [text].
  static TextAlign alignOf(String text) =>
      isUrduDominant(text) ? TextAlign.right : TextAlign.start;

  /// Returns the ergonomically correct `height` for the [TextStyle] based on
  /// the dominant script. Nastaliq needs more vertical breathing room.
  static double lineHeightOf(String text) =>
      isUrduDominant(text) ? nastaliqLineHeight : latinLineHeight;

  /// Wraps [text] in a [Text] widget that automatically detects the script
  /// and applies the correct direction, alignment, and line-height.
  ///
  /// Usage:
  /// ```dart
  /// BidiTextHelper.autoText(
  ///   message.content,
  ///   style: AppTextStyles.body(scheme.onSurface),
  /// )
  /// ```
  static Widget autoText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    double? fontSizeOverride,
  }) {
    final isUrdu = isUrduDominant(text);
    final resolvedStyle = (style ?? const TextStyle()).copyWith(
      height: isUrdu ? nastaliqLineHeight : (style?.height ?? latinLineHeight),
      fontSize: fontSizeOverride ?? style?.fontSize,
      // Ensure Nastaliq glyphs are not impacted by letter spacing
      letterSpacing: isUrdu ? 0.0 : style?.letterSpacing,
    );

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        style: resolvedStyle,
        textAlign: isUrdu ? TextAlign.right : TextAlign.start,
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  /// A [Wrap]-based auto-direction widget for inline use inside [Row]/[Column].
  static Widget autoRichText(
    String text, {
    TextStyle? style,
  }) {
    final isUrdu = isUrduDominant(text);
    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        textAlign: isUrdu ? TextAlign.right : TextAlign.start,
        style: (style ?? const TextStyle()).copyWith(
          height: isUrdu ? nastaliqLineHeight : latinLineHeight,
          letterSpacing: isUrdu ? 0.0 : null,
        ),
      ),
    );
  }
}
