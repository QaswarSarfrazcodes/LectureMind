import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/utils/prompt_builder.dart';
import 'package:lecturemind/core/services/web_speech/web_speech.dart';
import 'package:lecturemind/shared_models/language.dart';

void main() {
  group('Phase 2 — Voice Pipeline & Domain-Aware Intelligence Tests', () {
    test('buildSttRefinementPrompt without subjectHint returns base STT prompt', () {
      final prompt = PromptBuilder.buildSttRefinementPrompt(
        language: Language.english,
      );

      expect(prompt, contains('Neural Speech-to-Text Normalizer'));
      expect(prompt, contains('Acoustic & Phonetic Correction'));
      expect(prompt, isNot(contains('Target Field:')));
    });

    test('buildSttRefinementPrompt with CS subjectHint injects specialized CS dictionary', () {
      final prompt = PromptBuilder.buildSttRefinementPrompt(
        language: Language.english,
        subjectHint: 'Computer Science & Distributed Systems',
      );

      expect(prompt, contains('Target Field: Computer Science & Distributed Systems'));
      expect(prompt, contains('OOP -> Object-Oriented Programming'));
      expect(prompt, contains('SQL -> Structured Query Language'));
      expect(prompt, contains('recursion, concurrency, deadlock, semaphore'));
      expect(prompt, contains('Bilingual Pakistani Code-Switching'));
    });

    test('buildSttRefinementPrompt with Medical subjectHint injects medical dictionary', () {
      final prompt = PromptBuilder.buildSttRefinementPrompt(
        language: Language.english,
        subjectHint: 'Biochemistry & Molecular Biology',
      );

      expect(prompt, contains('Target Field: Biochemistry & Molecular Biology'));
      expect(prompt, contains('PCR -> Polymerase Chain Reaction'));
      expect(prompt, contains('ATP -> Adenosine Triphosphate'));
      expect(prompt, contains('mitosis, meiosis, homeostasis, pathogen'));
    });

    test('buildSttRefinementPrompt in Urdu preserves bilingual code-switching rules', () {
      final prompt = PromptBuilder.buildSttRefinementPrompt(
        language: Language.urdu,
        subjectHint: 'Physics',
      );

      expect(prompt, contains('Target Field: Physics'));
      expect(prompt, contains('x squared plus two x equals zero'));
      expect(prompt, contains('Do NOT translate between Urdu and English'));
    });

    test('WebSpeechBridge stub interface provides safe fallbacks on non-web platforms', () {
      // In unit test VM environment, stub is safely engaged
      expect(WebSpeechBridge.stop(), isA<String>());
      expect(WebSpeechBridge.getSpeechTranscript(), isA<String>());
      expect(WebSpeechBridge.downloadImage(base64Data: 'data', filename: 'test.png'), isFalse);
    });

    test('Voice Agent Oral Examiner prompt formats lecture context properly', () {
      const sampleLecture = 'Operating Systems lecture on Semaphores and Deadlocks.';
      const lectureSnippet = '\n\nACTIVE LECTURE MATERIAL TO TEST OR EXPLAIN:\n$sampleLecture\nAct as a Socratic oral examiner and tutor. Test the student or answer questions on this lecture.';

      const systemPrompt =
          'You are LectureMind Realtime Voice Agent, an intelligent bilingual '
          'voice companion powered by AssemblyAI, Groq, and Google Gemini. '
          'Keep answers concise, conversational, and direct (2 to 4 sentences) '
          'because your output is being spoken aloud. '
          'Use natural, warm conversational phrasing in English. '
          'Do not output markdown asterisks, bullet signs, or any formatting.'
          '$lectureSnippet';

      expect(systemPrompt, contains('ACTIVE LECTURE MATERIAL TO TEST OR EXPLAIN:'));
      expect(systemPrompt, contains('Operating Systems lecture on Semaphores and Deadlocks.'));
      expect(systemPrompt, contains('Act as a Socratic oral examiner and tutor'));
    });

    test('Spoken output cleaner removes markdown symbols for pristine TTS voice', () {
      const rawAiReply = '**Deadlock** occurs when two processes are *waiting* for resources held by each other. See [details](http://example.com).\n\nWhat condition must hold?';

      final cleanForSpeech = rawAiReply
          .replaceAll(RegExp(r'\*\*|__|[\*_#`~>]|---+'), '')
          .replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m[1] ?? '')
          .replaceAll(RegExp(r'\n+'), '. ')
          .trim();

      expect(cleanForSpeech, isNot(contains('**')));
      expect(cleanForSpeech, isNot(contains('*')));
      expect(cleanForSpeech, isNot(contains('[details]')));
      expect(cleanForSpeech, contains('Deadlock occurs when two processes are waiting'));
      expect(cleanForSpeech, contains('See details.'));
    });
  });
}
