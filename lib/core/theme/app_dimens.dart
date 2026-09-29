/// Spacing, radius, and sizing tokens. Keeps every screen on the same
/// rhythm instead of ad-hoc magic numbers scattered through widget files.
class AppDimens {
  const AppDimens._();

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusPill = 999;

  /// Generous tap target for tactile neumorphic feel
  static const double minTapTarget = 52;

  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static const double micButtonSize = 108;
  static const double scoreRingSize = 80;
}
