import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/utils/bidi_text_helper.dart';
import 'package:lecturemind/core/utils/app_haptics.dart';
import 'package:lecturemind/features/record_process/presentation/widgets/live_soundwave_visualizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX Phase 1 — BidiTextHelper Engine Tests', () {
    test('Identifies English text as LTR and Latin line height', () {
      const englishText = 'Operating Systems manage CPU scheduling and virtual memory allocation.';
      expect(BidiTextHelper.isUrduDominant(englishText), isFalse);
      expect(BidiTextHelper.directionOf(englishText), equals(TextDirection.ltr));
      expect(BidiTextHelper.alignOf(englishText), equals(TextAlign.start));
      expect(BidiTextHelper.lineHeightOf(englishText), equals(BidiTextHelper.latinLineHeight));
    });

    test('Identifies pure Urdu Nastaliq text as RTL with Nastaliq height (1.95)', () {
      const urduText = 'آپریٹنگ سسٹم کمپیوٹر کے بنیادی وسائل جیسے میموری اور پروسیسر کا انتظام کرتا ہے۔';
      expect(BidiTextHelper.isUrduDominant(urduText), isTrue);
      expect(BidiTextHelper.directionOf(urduText), equals(TextDirection.rtl));
      expect(BidiTextHelper.alignOf(urduText), equals(TextAlign.right));
      expect(BidiTextHelper.lineHeightOf(urduText), equals(BidiTextHelper.nastaliqLineHeight));
      expect(BidiTextHelper.nastaliqLineHeight, equals(1.95));
    });

    test('Correctly handles code-switched bilingual lecture sentences (Urdu + English terms)', () {
      // Code-switched sentence with >30% Urdu characters
      const codeSwitchText = 'آج کے لیکچر میں ہم نے CPU Scheduling اور Virtual Memory کا تصور سمجھا۔';
      expect(BidiTextHelper.isUrduDominant(codeSwitchText), isTrue);
      expect(BidiTextHelper.directionOf(codeSwitchText), equals(TextDirection.rtl));
      expect(BidiTextHelper.alignOf(codeSwitchText), equals(TextAlign.right));
      expect(BidiTextHelper.lineHeightOf(codeSwitchText), equals(1.95));
    });

    test('Returns false for empty or whitespace-only text', () {
      expect(BidiTextHelper.isUrduDominant(''), isFalse);
      expect(BidiTextHelper.isUrduDominant('   \n\t  '), isFalse);
      expect(BidiTextHelper.directionOf(''), equals(TextDirection.ltr));
    });

    testWidgets('BidiTextHelper.autoText renders Directionality widget correctly', (tester) async {
      const urduText = 'یہ ایک آزمائشی جملہ ہے';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BidiTextHelper.autoText(urduText),
          ),
        ),
      );

      final directionalityFinder = find.byType(Directionality);
      expect(directionalityFinder, findsWidgets);

      final directionalityWidget = tester.widget<Directionality>(
        find.descendant(of: find.byType(Scaffold), matching: find.byType(Directionality)).first,
      );
      expect(directionalityWidget.textDirection, equals(TextDirection.rtl));
    });
  });

  group('UX Phase 1 — AppHaptics Sensory Engine Tests', () {
    test('AppHaptics triggers gracefully without unhandled exceptions', () async {
      await expectLater(AppHaptics.selection(), completes);
      await expectLater(AppHaptics.light(), completes);
      await expectLater(AppHaptics.medium(), completes);
      await expectLater(AppHaptics.heavy(), completes);
      await expectLater(AppHaptics.warning(), completes);
      await expectLater(AppHaptics.celebrate(), completes);
    });
  });

  group('UX Phase 1 — LiveSoundwaveVisualizer Widget Tests', () {
    testWidgets('Renders idle waveform when isRecording is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveSoundwaveVisualizer(isRecording: false),
          ),
        ),
      );

      expect(find.byType(LiveSoundwaveVisualizer), findsOneWidget);
      expect(find.text('STANDBY'), findsOneWidget);
      expect(find.text('Mic Ready • High Fidelity'), findsOneWidget);
    });

    testWidgets('Renders active animated waveform and dBFS when isRecording is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveSoundwaveVisualizer(isRecording: true),
          ),
        ),
      );

      expect(find.byType(LiveSoundwaveVisualizer), findsOneWidget);
      expect(find.textContaining('dBFS'), findsOneWidget);

      // Advance frames to ensure animations run smoothly
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
