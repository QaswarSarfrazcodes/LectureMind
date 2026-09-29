import 'package:flutter/material.dart';

/// Bionic Reading & Synchronized Karaoke Highlighting Engine.
///
/// Solves UX fault #7 from the LectureMind UX roadmap:
/// - Mitigates reading fatigue during academic paper / slide reading by guiding
///   the eye through word fixations (first 30-50% of each word bolded).
/// - Provides karaoke-style visual tracking of the active spoken sentence
///   during TTS audio playback.
class BionicReadingHelper {
  const BionicReadingHelper._();

  /// Builds rich text spans with Bionic letter bolding.
  static List<InlineSpan> buildBionicSpans(
    String text, {
    required bool isDark,
    int? activeSentenceIndex,
    double fontSize = 13.5,
    double lineHeight = 1.6,
  }) {
    final sentences = splitSentences(text);
    final spans = <InlineSpan>[];

    for (int sIdx = 0; sIdx < sentences.length; sIdx++) {
      final sentence = sentences[sIdx];
      final isKaraokeActive = activeSentenceIndex != null && sIdx == activeSentenceIndex;

      final words = sentence.split(RegExp(r'(\s+)'));
      final sentenceSpans = <InlineSpan>[];

      for (final part in words) {
        if (part.trim().isEmpty) {
          sentenceSpans.add(TextSpan(text: part));
          continue;
        }

        // Calculate bionic fixation length
        final fixationLen = _fixationLength(part);
        final boldPart = part.substring(0, fixationLen);
        final lightPart = part.substring(fixationLen);

        sentenceSpans.add(
          TextSpan(
            children: [
              TextSpan(
                text: boldPart,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isKaraokeActive
                      ? const Color(0xFFF59E0B)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              TextSpan(
                text: lightPart,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: isKaraokeActive
                      ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        );
      }

      if (isKaraokeActive) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFB45309).withValues(alpha: 0.28)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text.rich(
                TextSpan(children: sentenceSpans),
                style: TextStyle(fontSize: fontSize, height: lineHeight),
              ),
            ),
          ),
        );
      } else {
        spans.addAll(sentenceSpans);
      }

      if (sIdx < sentences.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return spans;
  }

  static int _fixationLength(String word) {
    final clean = word.replaceAll(RegExp(r'[^\w]'), '');
    final len = clean.length;
    if (len <= 0) return word.length;
    if (len <= 3) return 1.clamp(1, word.length);
    if (len <= 5) return 2.clamp(1, word.length);
    if (len <= 8) return 3.clamp(1, word.length);
    if (len <= 11) return 4.clamp(1, word.length);
    return 5.clamp(1, word.length);
  }

  static List<String> splitSentences(String text) {
    if (text.trim().isEmpty) return const [];
    final raw = text.split(RegExp(r'(?<=[.!?])\s+'));
    return raw.where((s) => s.trim().isNotEmpty).toList();
  }
}
