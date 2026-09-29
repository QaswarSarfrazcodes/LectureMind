import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/network/groq_client.dart';
import 'package:lecturemind/core/network/gemini_client.dart';

void main() {
  group('Multi-turn Conversation Memory & Sliding Window', () {
    test('GroqClient validates API key format and fallback handling', () async {
      final groq = GroqClient(apiKeyProvider: () => 'gsk_test1234567890abcdef1234567890');
      final isValid = await groq.validateKey('gsk_test1234567890abcdef1234567890');
      expect(isValid, isTrue);
    });

    test('GroqClient generates rich fallback when offline or unauthenticated', () async {
      final groq = GroqClient(apiKeyProvider: () => '');
      final result = await groq.postChatCompletion(
        systemPrompt: 'You are an academic tutor.',
        userContent: 'Hello tutor!',
        history: [
          {'role': 'user', 'content': 'What is CPU?'},
          {'role': 'assistant', 'content': 'CPU is the central processing unit.'},
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotEmpty);
    });

    test('GeminiClient returns AuthFailure when API key is empty', () async {
      final gemini = GeminiClient(apiKeyProvider: () => '');
      final result = await gemini.generateContent(
        prompt: 'Explain Operating Systems',
        history: [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello! How can I help you today?'},
        ],
      );

      expect(result.isFailure, isTrue);
      expect(result.failure?.message, contains('API key is not configured'));
    });
  });
}
