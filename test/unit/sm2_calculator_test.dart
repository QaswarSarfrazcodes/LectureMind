import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/utils/sm2_calculator.dart';
import 'package:lecturemind/shared_models/flashcard.dart';

void main() {
  group('Sm2Calculator (SuperMemo SM-2)', () {
    final baseCard = Flashcard(
      id: 'test-1',
      sourceLectureId: 'lec-1',
      front: 'What is Backpropagation?',
      back: 'Gradient computation algorithm for training neural networks.',
      intervalDays: 1,
      repetitions: 0,
      easeFactor: 2.5,
      dueDate: DateTime.now().subtract(const Duration(hours: 1)),
    );

    test('TC-FLASH-04: Quality 5 (Easy) on first repetition yields interval 1, repetitions 1', () {
      final updated = Sm2Calculator.calculateNextReview(baseCard, 5);

      expect(updated.repetitions, equals(1));
      expect(updated.intervalDays, equals(1));
      expect(updated.easeFactor, greaterThan(2.5));
      expect(updated.dueDate.isAfter(DateTime.now()), isTrue);
    });

    test('TC-FLASH-04: Second successful repetition (q=4) yields interval 6', () {
      final cardRep1 = baseCard.copyWith(repetitions: 1, intervalDays: 1, easeFactor: 2.5);
      final updated = Sm2Calculator.calculateNextReview(cardRep1, 4);

      expect(updated.repetitions, equals(2));
      expect(updated.intervalDays, equals(6));
    });

    test('Third successful repetition scales by ease factor (interval = 6 * 2.5 = 15)', () {
      final cardRep2 = baseCard.copyWith(repetitions: 2, intervalDays: 6, easeFactor: 2.5);
      final updated = Sm2Calculator.calculateNextReview(cardRep2, 4);

      expect(updated.repetitions, equals(3));
      expect(updated.intervalDays, equals(15));
    });

    test('Failure (q < 3) resets repetitions to 0 and interval to 1', () {
      final veteranCard = baseCard.copyWith(repetitions: 5, intervalDays: 45, easeFactor: 2.4);
      final updated = Sm2Calculator.calculateNextReview(veteranCard, 1);

      expect(updated.repetitions, equals(0));
      expect(updated.intervalDays, equals(1));
      expect(updated.easeFactor, lessThan(2.4));
    });

    test('Ease factor never drops below minimum threshold of 1.3', () {
      var card = baseCard.copyWith(easeFactor: 1.35);
      for (int i = 0; i < 5; i++) {
        card = Sm2Calculator.calculateNextReview(card, 0);
      }

      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });
  });
}
