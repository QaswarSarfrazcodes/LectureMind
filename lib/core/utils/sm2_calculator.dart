import '../../shared_models/flashcard.dart';

/// SuperMemo SM-2 Spaced Repetition Algorithm Implementation.
class Sm2Calculator {
  const Sm2Calculator._();

  static const double minEaseFactor = 1.3;

  /// Calculates the next review schedule for a flashcard given a quality rating (0-5).
  static Flashcard calculateNextReview(Flashcard card, int quality) {
    assert(quality >= 0 && quality <= 5, 'Quality score must be between 0 and 5');

    int nextRepetitions;
    int nextIntervalDays;

    if (quality < 3) {
      nextRepetitions = 0;
      nextIntervalDays = 1;
    } else {
      if (card.repetitions == 0) {
        nextIntervalDays = 1;
        nextRepetitions = 1;
      } else if (card.repetitions == 1) {
        nextIntervalDays = 6;
        nextRepetitions = 2;
      } else {
        nextIntervalDays = (card.intervalDays * card.easeFactor).round();
        nextRepetitions = card.repetitions + 1;
      }
    }

    final calculatedEase = card.easeFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    final nextEaseFactor = calculatedEase < minEaseFactor ? minEaseFactor : calculatedEase;

    final nextDueDate = DateTime.now().add(Duration(days: nextIntervalDays));

    return card.copyWith(
      repetitions: nextRepetitions,
      intervalDays: nextIntervalDays,
      easeFactor: nextEaseFactor,
      dueDate: nextDueDate,
    );
  }
}
