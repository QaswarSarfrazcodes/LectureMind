/// The three generation/display languages LectureMind supports.
/// Feeds both UI copy (`AppStrings`) and the Groq system-prompt directive
/// from the same source of truth — see `architecture.md` §8.
enum Language {
  urdu,
  english,
  romanUrdu;

  String get label => switch (this) {
        Language.urdu => 'اردو',
        Language.english => 'English',
        Language.romanUrdu => 'Roman Urdu',
      };

  /// Urdu script content needs RTL + Nastaliq; the other two stay LTR + Inter.
  bool get isRtl => this == Language.urdu;
}
