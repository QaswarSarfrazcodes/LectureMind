import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecturemind/core/config/app_providers.dart';
import 'package:lecturemind/core/storage/local_storage_service.dart';
import 'package:lecturemind/core/utils/bionic_reading_helper.dart';
import 'package:lecturemind/core/utils/sm2_calculator.dart';
import 'package:lecturemind/features/notes_quiz/presentation/screens/notes_quiz_screen.dart';
import 'package:lecturemind/shared_models/flashcard.dart';
import 'package:lecturemind/shared_models/quiz.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX Phase 2 — BionicReadingHelper Engine Tests', () {
    test('Splits multi-sentence academic paragraphs accurately', () {
      const paragraph =
          'Virtual Memory decouples physical memory from logical address spaces. '
          'Paging allows non-contiguous allocation of memory! '
          'Does segmentation offer finer grain logical protection? Yes, it does.';

      final sentences = BionicReadingHelper.splitSentences(paragraph);
      expect(sentences.length, equals(4));
      expect(sentences[0], equals('Virtual Memory decouples physical memory from logical address spaces.'));
      expect(sentences[1], equals('Paging allows non-contiguous allocation of memory!'));
      expect(sentences[2], equals('Does segmentation offer finer grain logical protection?'));
      expect(sentences[3], equals('Yes, it does.'));
    });

    test('Splits empty or single-word strings safely without exceptions', () {
      expect(BionicReadingHelper.splitSentences(''), isEmpty);
      expect(BionicReadingHelper.splitSentences('   '), isEmpty);
      final single = BionicReadingHelper.splitSentences('Operating.');
      expect(single.length, equals(1));
      expect(single.first, equals('Operating.'));
    });

    test('Generates bionic spans with first letters weighted heavy (w900)', () {
      const sample = 'Kernel schedules threads efficiently.';
      final spans = BionicReadingHelper.buildBionicSpans(
        sample,
        isDark: false,
        fontSize: 14,
      );

      expect(spans, isNotEmpty);

      // Verify that at least one TextSpan has w900 weight (the bionic fixation)
      bool foundFixation = false;
      for (final span in spans) {
        if (span is TextSpan) {
          if (span.children != null) {
            for (final child in span.children!) {
              if (child is TextSpan && child.style?.fontWeight == FontWeight.w900) {
                foundFixation = true;
                break;
              }
            }
          }
        }
      }
      expect(foundFixation, isTrue);
    });

    test('Highlights active spoken sentence during TTS karaoke playback', () {
      const sample = 'First sentence of slide. Second sentence being read aloud. Third sentence.';
      final spans = BionicReadingHelper.buildBionicSpans(
        sample,
        isDark: true,
        activeSentenceIndex: 1, // Second sentence
      );

      // The active karaoke sentence is rendered with a WidgetSpan container
      final widgetSpans = spans.whereType<WidgetSpan>().toList();
      expect(widgetSpans.length, equals(1));
    });
  });

  group('UX Phase 2 — Spaced Repetition (SM-2) Flashcard Bridge Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs, null);
    });

    test('SM-2 calculator schedules next review and adjusts ease factor', () {
      final card = Flashcard(
        id: 'q1_fc',
        sourceLectureId: 'lec_os_101',
        front: 'What is thrashing in OS?',
        back: 'A state where the CPU spends more time paging than executing instructions.',
        intervalDays: 1,
        repetitions: 0,
        easeFactor: 2.5,
        dueDate: DateTime.now(),
      );

      final nextCard = Sm2Calculator.calculateNextReview(card, 4);

      expect(nextCard.repetitions, equals(1));
      expect(nextCard.intervalDays, equals(1));
      expect(nextCard.easeFactor, greaterThanOrEqualTo(2.5));
      expect(nextCard.dueDate.isAfter(card.dueDate), isTrue);
    });

    test('LocalStorageService persists and loads Flashcards correctly', () async {
      final card = Flashcard(
        id: 'quiz_q1_fc',
        sourceLectureId: 'lec_os_101',
        front: 'What is thrashing in OS?',
        back: 'A state where the CPU spends more time paging than executing instructions.',
        intervalDays: 1,
        repetitions: 0,
        easeFactor: 2.5,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      await storage.upsertFlashcard(card);
      final loaded = storage.loadFlashcards();

      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('quiz_q1_fc'));
      expect(loaded.first.front, equals('What is thrashing in OS?'));
      expect(loaded.first.sourceLectureId, equals('lec_os_101'));
    });

    test('FlashcardsNotifier in Riverpod container handles addOrUpdateCard', () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(flashcardsProvider);
      expect(initial, isEmpty);

      final card = Flashcard(
        id: 'quiz_trap_1',
        sourceLectureId: 'lec_102',
        front: 'Why does round-robin scheduling avoid starvation?',
        back: 'Because each process receives a bounded time quantum in cyclic order.',
        intervalDays: 1,
        repetitions: 0,
        easeFactor: 2.5,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      await container.read(flashcardsProvider.notifier).addOrUpdateCard(card);
      final updated = container.read(flashcardsProvider);

      expect(updated.length, equals(1));
      expect(updated.first.id, equals('quiz_trap_1'));
      expect(updated.first.sourceLectureId, equals('lec_102'));
    });
  });

  group('UX Phase 2 — Topic Mastery Diagnostic Calculation Tests', () {
    test('Correctly aggregates topics and grades mastery percentages', () {
      final questions = [
        const QuizQuestion(
          id: 'q1',
          type: QuestionType.mcq,
          question: 'Q1 Memory Management',
          options: [
            QuizOption(text: 'Option A', isCorrect: true),
            QuizOption(text: 'Option B', isCorrect: false),
          ],
          correctAnswer: 'Option A',
          explanation: 'Expl 1',
        ),
        const QuizQuestion(
          id: 'q2',
          type: QuestionType.mcq,
          question: 'Q2 Memory Management',
          options: [
            QuizOption(text: 'Option A', isCorrect: false),
            QuizOption(text: 'Option B', isCorrect: true),
          ],
          correctAnswer: 'Option B',
          explanation: 'Expl 2',
        ),
        const QuizQuestion(
          id: 'q3',
          type: QuestionType.mcq,
          question: 'Q3 Process Scheduling',
          options: [
            QuizOption(text: 'Option A', isCorrect: true),
            QuizOption(text: 'Option B', isCorrect: false),
          ],
          correctAnswer: 'Option A',
          explanation: 'Expl 3',
        ),
        const QuizQuestion(
          id: 'q4',
          type: QuestionType.mcq,
          question: 'Q4 Process Scheduling',
          options: [
            QuizOption(text: 'Option A', isCorrect: false),
            QuizOption(text: 'Option B', isCorrect: true),
          ],
          correctAnswer: 'Option B',
          explanation: 'Expl 4',
        ),
      ];

      // Simulated user responses:
      // Memory Management: 2 questions, 2 correct (100% -> High Mastery)
      // Process Scheduling: 2 questions, 0 correct (0% -> Needs Review)
      final userAnswers = {0: 0, 1: 1, 2: 1, 3: 0};

      final topicStats = <String, List<int>>{
        'Memory Management': [0, 0],
        'Process Scheduling': [0, 0],
      };

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final topic = i < 2 ? 'Memory Management' : 'Process Scheduling';
        topicStats[topic]![1]++; // total
        final selectedOptIndex = userAnswers[i]!;
        if (q.options[selectedOptIndex].isCorrect) {
          topicStats[topic]![0]++; // correct
        }
      }

      final memStat = topicStats['Memory Management']!;
      final schedStat = topicStats['Process Scheduling']!;

      final memPct = memStat[0] / memStat[1];
      final schedPct = schedStat[0] / schedStat[1];

      expect(memPct, equals(1.0)); // 100%
      expect(schedPct, equals(0.0)); // 0%

      // Verify categorization logic matching QuizTab topic mastery radar
      String categorize(double pct) {
        if (pct >= 0.8) return 'High Mastery';
        if (pct >= 0.5) return 'Developing';
        return 'Needs Review';
      }

      expect(categorize(memPct), equals('High Mastery'));
      expect(categorize(schedPct), equals('Needs Review'));
    });
  });

  group('UX Phase 2 — NotesQuizScreen PageView Gestures Widget Tests', () {
    testWidgets('Renders PageView and tab pills for Notes, Mind Map & Quiz', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs, null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: NotesQuizScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the 3 top tab pills are present
      expect(find.text('Structured Notes'), findsOneWidget);
      expect(find.text('Visual Mind Map'), findsOneWidget);
      expect(find.text('AI Quiz'), findsOneWidget);

      // Verify PageView is present
      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
