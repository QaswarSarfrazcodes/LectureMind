import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecturemind/core/services/ai_feedback_service.dart';
import 'package:lecturemind/core/services/subject_classifier_service.dart';
import 'package:lecturemind/core/utils/prompt_builder.dart';
import 'package:lecturemind/shared_models/ai_feedback_record.dart';

void main() {
  group('Phase 4 — Better AI Response Quality Loop & Adaptive Inference', () {
    late SharedPreferences prefs;
    late AiFeedbackService feedbackService;
    const classifier = SubjectClassifierService();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      feedbackService = AiFeedbackService(prefs);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4.1 User Feedback Collection & RLHF Dataset Generation
    // ─────────────────────────────────────────────────────────────────────────
    test('AiFeedbackService records positive and negative feedback and calculates satisfaction statistics', () async {
      expect(feedbackService.getAllFeedback(), isEmpty);
      expect(feedbackService.getStats().totalRatings, 0);

      final record1 = AiFeedbackRecord(
        id: 'fb_1',
        messageId: 'msg_101',
        lectureId: 'lec_os_01',
        userQuestion: 'What is a Semaphore?',
        aiResponse: 'A semaphore is a synchronization primitive...',
        rating: 'thumbsUp',
        taskType: 'chatQa',
        model: 'openai/gpt-oss-120b',
        timestamp: DateTime.now(),
        subjectFolder: 'Computer Science',
      );

      await feedbackService.recordFeedback(record1);

      var all = feedbackService.getAllFeedback();
      expect(all.length, 1);
      expect(all.first.isPositive, isTrue);

      var stats = feedbackService.getStats();
      expect(stats.totalRatings, 1);
      expect(stats.thumbsUpCount, 1);
      expect(stats.thumbsDownCount, 0);
      expect(stats.satisfactionPercentage, 100.0);

      // Add a thumbsDown feedback
      final record2 = AiFeedbackRecord(
        id: 'fb_2',
        messageId: 'msg_102',
        lectureId: 'lec_os_01',
        userQuestion: 'Explain deadlock handling',
        aiResponse: 'Just ignore it.',
        rating: 'thumbsDown',
        taskType: 'chatQa',
        model: 'openai/gpt-oss-120b',
        timestamp: DateTime.now(),
        subjectFolder: 'Computer Science',
      );

      await feedbackService.recordFeedback(record2);

      all = feedbackService.getAllFeedback();
      expect(all.length, 2);

      stats = feedbackService.getStats();
      expect(stats.totalRatings, 2);
      expect(stats.thumbsUpCount, 1);
      expect(stats.thumbsDownCount, 1);
      expect(stats.satisfactionPercentage, 50.0);

      // Export JSON verification
      final jsonExport = feedbackService.exportFeedbackJson();
      expect(jsonExport, contains('What is a Semaphore?'));
      expect(jsonExport, contains('thumbsDown'));

      // Clear feedback
      await feedbackService.clearAllFeedback();
      expect(feedbackService.getAllFeedback(), isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4.2 Dynamic Temperature Tuning
    // ─────────────────────────────────────────────────────────────────────────
    test('PromptBuilder.getAdaptiveTemperature tunes sampling based on query intent', () {
      // 1. Definition / Factual queries -> 0.12 (Ultra-low temperature for maximum precision)
      expect(PromptBuilder.getAdaptiveTemperature('What is round robin scheduling?', AiTaskType.chatQa), 0.12);
      expect(PromptBuilder.getAdaptiveTemperature('Define binary search tree', AiTaskType.chatQa), 0.12);
      expect(PromptBuilder.getAdaptiveTemperature('مائٹوسس کیا ہے؟', AiTaskType.chatQa), 0.12);
      expect(PromptBuilder.getAdaptiveTemperature('ڈیڈ لاک کی تعریف کریں', AiTaskType.chatQa), 0.12);

      // 2. Problem solving / How-to queries -> 0.20 (Deterministic logic)
      expect(PromptBuilder.getAdaptiveTemperature('How to solve Dijkstra shortest path?', AiTaskType.chatQa), 0.20);
      expect(PromptBuilder.getAdaptiveTemperature('Steps to compute the determinant of a 3x3 matrix', AiTaskType.chatQa), 0.20);
      expect(PromptBuilder.getAdaptiveTemperature('اس مسئلے کو کیسے حل کریں؟', AiTaskType.chatQa), 0.20);

      // 3. Creative analogies / Feynman explanations -> 0.55 (Expressive pedagogy)
      expect(PromptBuilder.getAdaptiveTemperature('Give me a vivid analogy for memory paging', AiTaskType.chatQa), 0.55);
      expect(PromptBuilder.getAdaptiveTemperature('Explain quantum entanglement like a story', AiTaskType.chatQa), 0.55);
      expect(PromptBuilder.getAdaptiveTemperature('کوئی آسان مثال دے کر سمجھائیں', AiTaskType.chatQa), 0.55);

      // 4. Task default fallbacks
      expect(PromptBuilder.getAdaptiveTemperature('General discussion', AiTaskType.notesGeneration), 0.15);
      expect(PromptBuilder.getAdaptiveTemperature('General discussion', AiTaskType.quizGeneration), 0.30);
      expect(PromptBuilder.getAdaptiveTemperature('General discussion', AiTaskType.eli10Simplify), 0.45);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4.3 Automatic Subject & Domain Classification Engine
    // ─────────────────────────────────────────────────────────────────────────
    test('SubjectClassifierService correctly identifies Computer Science and injects coding directives', () {
      const csText = 'Today we will discuss binary search tree algorithms, recursive pointers, and time complexity in Python.';
      final result = classifier.classify(csText);

      expect(result.domain, AcademicDomain.computerScience);
      expect(result.confidence, greaterThanOrEqualTo(0.80));
      expect(result.domainDirective, contains('ACADEMIC DOMAIN DIRECTIVE (Computer Science & Software):'));
      expect(result.domainDirective, contains('syntax-highlighted markdown code blocks'));
      expect(result.domainDirective, contains('Big-O notation'));
      expect(result.detectedKeywords, contains('algorithm'));
      expect(result.detectedKeywords, contains('tree'));
    });

    test('SubjectClassifierService correctly identifies Mathematics and injects proof directives', () {
      const mathText = 'We evaluate the differential equation using calculus, computing the derivative and matrix eigenvalues.';
      final result = classifier.classify(mathText);

      expect(result.domain, AcademicDomain.mathematics);
      expect(result.domainDirective, contains('ACADEMIC DOMAIN DIRECTIVE (Mathematics & Statistics):'));
      expect(result.domainDirective, contains('mathematical proofs and derivations step by step'));
      expect(result.detectedKeywords, contains('calculus'));
      expect(result.detectedKeywords, contains('derivative'));
    });

    test('SubjectClassifierService correctly identifies Medicine & Life Sciences', () {
      const medText = 'Mitosis in eukaryotic cells involves chromosome duplication, cellular metabolism, and ATP synthesis.';
      final result = classifier.classify(medText);

      expect(result.domain, AcademicDomain.medicine);
      expect(result.domainDirective, contains('ACADEMIC DOMAIN DIRECTIVE (Medicine & Life Sciences):'));
      expect(result.domainDirective, contains('DNA/RNA, ATP, PCR, Homeostasis'));
    });

    test('SubjectClassifierService correctly identifies Physics', () {
      const physText = 'Calculate the kinetic energy, momentum, and acceleration of the particle under gravitational force.';
      final result = classifier.classify(physText);

      expect(result.domain, AcademicDomain.physics);
      expect(result.domainDirective, contains('ACADEMIC DOMAIN DIRECTIVE (Physics & Physical Sciences):'));
      expect(result.domainDirective, contains('governing physical laws, conservation principles'));
    });

    test('SubjectClassifierService correctly identifies Economics', () {
      const econText = 'The central bank adjusted interest rate policy to combat inflation, shifting consumer demand and market equilibrium.';
      final result = classifier.classify(econText);

      expect(result.domain, AcademicDomain.economics);
      expect(result.domainDirective, contains('ACADEMIC DOMAIN DIRECTIVE (Economics & Business):'));
      expect(result.domainDirective, contains('supply-demand dynamics, opportunity costs'));
    });

    test('SubjectClassifierService falls back to General Academic for non-specialized text', () {
      const genericText = 'Welcome to today’s orientation session where we will go over the syllabus and semester guidelines.';
      final result = classifier.classify(genericText);

      expect(result.domain, AcademicDomain.generalAcademic);
      expect(result.domainDirective, contains('ACADEMIC DOMAIN DIRECTIVE (General Academic):'));
      expect(result.domainDirective, contains('Feynman technique'));
    });
  });
}
