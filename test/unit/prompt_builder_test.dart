import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/utils/prompt_builder.dart';
import 'package:lecturemind/shared_models/language.dart';

void main() {
  group('PromptBuilder & RAG Templates', () {
    test('Chat system prompt contains strict grounding directive and refusal requirement', () {
      const lectureContext = 'This lecture is about Convolutional Neural Networks and Kernel filters.';
      final systemPrompt = PromptBuilder.buildChatSystemPrompt(
        lectureContext: lectureContext,
        language: Language.urdu,
      );

      expect(systemPrompt, contains('GROUNDING CONSTRAINT'));
      expect(systemPrompt, contains('REFUSAL INSTRUCTION'));
      expect(systemPrompt, contains(PromptBuilder.groundingRefusalUrdu));
      expect(systemPrompt, contains(lectureContext));
    });

    test('Chat English refusal directive is set when English is preferred', () {
      const lectureContext = 'Context data';
      final systemPrompt = PromptBuilder.buildChatSystemPrompt(
        lectureContext: lectureContext,
        language: Language.english,
      );

      expect(systemPrompt, contains(PromptBuilder.groundingRefusalEnglish));
    });

    test('Flashcard grading prompt specifies exact JSON keys', () {
      final prompt = PromptBuilder.buildFlashcardGradingPrompt(
        question: 'What is a neuron?',
        correctAnswer: 'A fundamental unit of computation in neural nets.',
        spokenAnswer: 'It is a computational unit.',
      );

      expect(prompt, contains('"quality"'));
      expect(prompt, contains('"semanticScore"'));
      expect(prompt, contains('"feedback"'));
    });

    test('Writing feedback prompt demands grammar rule and corrected Urdu', () {
      final prompt = PromptBuilder.buildWritingFeedbackPrompt(
        promptText: 'Write a sentence about study.',
        submission: 'میں پڑھتا ہے',
      );

      expect(prompt, contains('"correctedUrdu"'));
      expect(prompt, contains('"grammarRule"'));
      expect(prompt, contains('میں پڑھتا ہے'));
    });
  });
}
