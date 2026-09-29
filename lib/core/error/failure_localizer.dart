import '../../shared_models/language.dart';
import 'failures.dart';

/// Translates technical failures into user-friendly bilingual messages.
class FailureLocalizer {
  const FailureLocalizer._();

  static String localize(Failure failure, Language language) {
    final isUrdu = language == Language.urdu;
    final isRoman = language == Language.romanUrdu;

    if (failure is NetworkFailure) {
      if (isUrdu) return 'انٹرنیٹ کنکشن دستیاب نہیں ہے۔ براہ کرم کنکشن چیک کریں۔';
      if (isRoman) return 'Internet connection dastiyab nahi hai. Please reconnect karein.';
      return 'No active internet connection. Please reconnect to continue.';
    }

    if (failure is AuthFailure) {
      if (isUrdu) return 'API کی درست نہیں ہے یا میعاد ختم ہو چکی ہے۔ سیٹنگز میں چیک کریں۔';
      if (isRoman) return 'API key ghalat hai ya expire ho chuki hai. Settings check karein.';
      return 'API key is invalid or expired. Please check Settings.';
    }

    if (failure is AssemblyAiFailure) {
      if (isUrdu) return 'تقریر کو متن میں تبدیل کرنے میں دشواری: ${failure.message}';
      if (isRoman) return 'Audio transcription mein masla aya: ${failure.message}';
      return 'Speech-to-text error: ${failure.message}';
    }

    if (failure is GroqFailure) {
      if (isUrdu) return 'AI تجزیہ کرنے میں ناکام رہا: ${failure.message}';
      if (isRoman) return 'AI response generate karne mein masla aya: ${failure.message}';
      return 'AI processing error: ${failure.message}';
    }

    if (failure is AudioFailure) {
      if (isUrdu) return 'مائیکروفون دستیاب نہیں ہے یا اجازت نہیں ملی۔';
      if (isRoman) return 'Microphone ki permission nahi mili.';
      return 'Microphone permission denied or recording failed.';
    }

    return failure.message;
  }
}
