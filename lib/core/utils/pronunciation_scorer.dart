import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import 'package:flutter/painting.dart';

enum WordScoringStatus {
  match, // Green (1.0 weight)
  close, // Amber (0.6 weight) - e.g. confusable phonemes or close Levenshtein
  missed, // Red (0.0 weight) - omitted or wrong
}

class ScoredWord {
  const ScoredWord({
    required this.referenceWord,
    required this.spokenWord,
    required this.status,
    required this.feedback,
  });

  final String referenceWord;
  final String spokenWord;
  final WordScoringStatus status;
  final String? feedback;

  Color get color => switch (status) {
        WordScoringStatus.match => AppColors.scoreCorrect,
        WordScoringStatus.close => AppColors.scoreClose,
        WordScoringStatus.missed => AppColors.scoreMissed,
      };
}

class PronunciationResult {
  const PronunciationResult({
    required this.score,
    required this.scoredWords,
    required this.focusSounds,
    required this.feedbackMessage,
  });

  final int score;
  final List<ScoredWord> scoredWords;
  final List<String> focusSounds;
  final String feedbackMessage;

  int get overallScore => score;
  List<ScoredWord> get words => scoredWords;
  List<String> get confusablesDetected => focusSounds;
}

/// Pronunciation Diff & Scoring Engine per urdu-speaking.md §4.
class PronunciationScorer {
  const PronunciationScorer._();

  /// Convenient alias for scoreAttempt.
  static PronunciationResult score({
    required String target,
    required String spoken,
  }) =>
      scoreAttempt(referenceText: target, spokenTranscript: spoken);

  // Known confusable Urdu phoneme pairs per urdu-speaking.md §8
  static const _confusableGroups = [
    {'ق', 'ک'},
    {'ز', 'ذ', 'ض', 'ظ'},
    {'ص', 'س', 'ث'},
    {'ت', 'ط'},
    {'ڑ', 'ر'},
    {'ہ', 'ح'},
  ];

  /// Scores a spoken attempt against reference Urdu text.
  static PronunciationResult scoreAttempt({
    required String referenceText,
    required String spokenTranscript,
  }) {
    final refWords = _cleanWords(referenceText);
    final spokenWords = _cleanWords(spokenTranscript);

    if (refWords.isEmpty) {
      return const PronunciationResult(
        score: 0,
        scoredWords: [],
        focusSounds: [],
        feedbackMessage: 'No reference words found.',
      );
    }

    final scoredWords = <ScoredWord>[];
    final focusSounds = <String>{};
    double totalEarned = 0.0;

    for (int i = 0; i < refWords.length; i++) {
      final ref = refWords[i];
      final spoken = i < spokenWords.length ? spokenWords[i] : '';

      if (spoken.isEmpty) {
        scoredWords.add(ScoredWord(
          referenceWord: ref,
          spokenWord: '',
          status: WordScoringStatus.missed,
          feedback: 'چھوٹ گیا (Omitted)',
        ));
        continue;
      }

      if (_isExactMatch(ref, spoken)) {
        scoredWords.add(ScoredWord(
          referenceWord: ref,
          spokenWord: spoken,
          status: WordScoringStatus.match,
          feedback: 'درست (Correct)',
        ));
        totalEarned += 1.0;
      } else if (_isConfusablePair(ref, spoken, focusSounds)) {
        scoredWords.add(ScoredWord(
          referenceWord: ref,
          spokenWord: spoken,
          status: WordScoringStatus.close,
          feedback: 'قریب ترین (Close phoneme match)',
        ));
        totalEarned += 0.7; // Weighted partial credit
      } else {
        final similarity = _levenshteinSimilarity(ref, spoken);
        if (similarity >= 0.65) {
          scoredWords.add(ScoredWord(
            referenceWord: ref,
            spokenWord: spoken,
            status: WordScoringStatus.close,
            feedback: 'قریب ہے، دوبارہ سنیں (Almost)',
          ));
          totalEarned += 0.6;
        } else {
          scoredWords.add(ScoredWord(
            referenceWord: ref,
            spokenWord: spoken,
            status: WordScoringStatus.missed,
            feedback: 'تلفظ درست نہیں (Missed)',
          ));
        }
      }
    }

    final int calculatedScore = ((totalEarned / refWords.length) * 100).round().clamp(0, 100);

    String message;
    if (calculatedScore >= 85) {
      message = 'بہترین روانی اور تلفظ! ماشاءاللہ (Excellent fluency & pronunciation!)';
    } else if (calculatedScore >= 65) {
      message = 'اچھی کوشش! چند الفاظ پر مزید توجہ دیں۔ (Good effort! Focus on highlighted sounds)';
    } else {
      message = 'دوبارہ مشق کریں۔ الفاظ کے صحیح مخرج پر دھیان دیں۔ (Practice again with reference audio)';
    }

    return PronunciationResult(
      score: calculatedScore,
      scoredWords: scoredWords,
      focusSounds: focusSounds.toList(),
      feedbackMessage: message,
    );
  }

  static List<String> _cleanWords(String text) {
    return text
        .replaceAll(RegExp(r'[۔،؛؟!\.,\?]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static bool _isExactMatch(String a, String b) {
    return _normalize(a) == _normalize(b);
  }

  static bool _isConfusablePair(String ref, String spoken, Set<String> focusSounds) {
    final normRef = _normalize(ref);
    final normSpk = _normalize(spoken);

    // If word lengths are wildly different, they are not a confusable pair substitution
    if ((normRef.length - normSpk.length).abs() > 2) return false;

    for (final group in _confusableGroups) {
      for (final char1 in group) {
        if (normRef.contains(char1)) {
          for (final char2 in group) {
            if (char1 != char2 && normSpk.contains(char2)) {
              final substituted = normRef.replaceAll(char1, char2);
              if (substituted == normSpk || _levenshteinSimilarity(substituted, normSpk) >= 0.7) {
                focusSounds.add('$char1 vs $char2');
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  static String _normalize(String s) {
    return s
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ہ')
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), ''); // remove diacritics
  }

  static double _levenshteinSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final d = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce(math.min);
      }
    }

    final distance = d[s1.length][s2.length];
    final maxLen = math.max(s1.length, s2.length);
    return 1.0 - (distance / maxLen);
  }
}
