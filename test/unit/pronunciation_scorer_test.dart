import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/utils/pronunciation_scorer.dart';

void main() {
  group('PronunciationScorer (Urdu Phonetic Sequence Scorer)', () {
    test('Exact match yields score 100 with all green words', () {
      const target = 'قلم میز پر رکھا ہے';
      const spoken = 'قلم میز پر رکھا ہے';

      final result = PronunciationScorer.score(target: target, spoken: spoken);

      expect(result.overallScore, equals(100));
      expect(result.words.length, equals(5));
      expect(result.words.every((w) => w.status == WordScoringStatus.match), isTrue);
    });

    test('Confusable pair (ق vs ک) produces partial credit and detected confusable', () {
      const target = 'قلم';
      const spoken = 'کلم';

      final result = PronunciationScorer.score(target: target, spoken: spoken);

      expect(result.overallScore, inInclusiveRange(60, 85));
      expect(result.confusablesDetected.isNotEmpty, isTrue);
      expect(result.words.first.status, equals(WordScoringStatus.close));
    });

    test('Confusable pair (ص vs س vs ث) correctly flagged', () {
      const target = 'صبر';
      const spoken = 'سبر';

      final result = PronunciationScorer.score(target: target, spoken: spoken);

      expect(result.confusablesDetected.any((c) => c.contains('ص') || c.contains('س')), isTrue);
      expect(result.words.first.status, equals(WordScoringStatus.close));
    });

    test('Completely incorrect pronunciation gives low score and incorrect status', () {
      const target = 'کمپیوٹر سائنس';
      const spoken = 'گاڑی سڑک';

      final result = PronunciationScorer.score(target: target, spoken: spoken);

      expect(result.overallScore, lessThan(40));
      expect(result.words.every((w) => w.status == WordScoringStatus.missed), isTrue);
    });

    test('Empty spoken transcript yields score 0', () {
      const target = 'صبح بخیر';
      const spoken = '';

      final result = PronunciationScorer.score(target: target, spoken: spoken);

      expect(result.overallScore, equals(0));
    });
  });
}
