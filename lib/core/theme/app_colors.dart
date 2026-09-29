import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_dimens.dart';

/// LectureMind Brand Design System — Dark Navy Blue × Vibrant Crimson Red × Pure White.
/// Complete redesign: deep navy backgrounds, vivid red accents, crisp white typography.
/// Only this file may reference ThemeData directly — screens always read via Theme.of(context).
class AppColors {
  const AppColors._();

  // ── Brand Core ───────────────────────────────────────────────────────────
  static const Color pureWhite    = Color(0xFFFFFFFF);
  static const Color offWhite     = Color(0xFFE2EBF8);  // Crisp ice white
  static const Color jetBlack     = Color(0xFF070B14);  // Deepest shadow
  static const Color crimsonRed   = Color(0xFFE8192C);  // Vibrant LectureMind Red
  static const Color deepCrimson  = Color(0xFFBF1122);  // Hover / pressed red
  static const Color brightRed    = Color(0xFFFF2E44);  // Bright accent red

  // ── Dark Navy Blue Palette (Neumorphic) ───────────────────────────────────
  static const Color navyDeep     = Color(0xFF090E1A);  // Sunken base
  static const Color navyDark     = Color(0xFF0F172A);  // Main canvas background
  static const Color navyMid      = Color(0xFF131D33);  // Card / surface
  static const Color navyLight    = Color(0xFF16223B);  // Elevated card / dialog
  static const Color navyBorder   = Color(0x2E4D7EC7);  // Soft rim highlight / border
  static const Color navyAccent   = Color(0xFF2A4A7F);  // Subtle nav highlights

  // ── Legacy surface names → mapped to new navy palette ────────────────────
  static const Color darkBackground    = navyDark;
  static const Color darkSurface       = navyMid;
  static const Color darkBorder        = navyBorder;
  static const Color darkTextPrimary   = pureWhite;
  static const Color darkTextSecondary = Color(0xFF8FA8CC);  // Cool blue-grey

  // ── Light theme (for day mode fallback) ──────────────────────────────────
  static const Color lightBackground    = Color(0xFFE9EEF5);
  static const Color lightSurface       = Color(0xFFE9EEF5);
  static const Color lightBorder        = Color(0x33A0AEC0);
  static const Color lightTextPrimary   = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF4A5568);

  // ── Misc tokens ──────────────────────────────────────────────────────────
  static const Color darkCharcoal = navyLight;
  static const Color slateBorder  = navyBorder;
  static const Color surfaceMist  = lightBackground;
  static const Color mutedSlate   = darkTextSecondary;

  // ── Semantic / Functional ─────────────────────────────────────────────────
  static const Color success  = Color(0xFF22C55E);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = crimsonRed;
  static const Color amberBg  = Color(0xFF1A160A);
  static const Color lightCard = lightSurface;
  static const Color darkCard  = navyMid;

  // ── Scoring ring (Bolna Trainer) ──────────────────────────────────────────
  static const Color scoreCorrect = Color(0xFF22C55E);
  static const Color scoreClose   = Color(0xFFF59E0B);
  static const Color scoreMissed  = crimsonRed;

  // ── Legacy aliases ────────────────────────────────────────────────────────
  static const Color sabaqGreen      = crimsonRed;
  static const Color sabaqGreenDark  = deepCrimson;
  static const Color sabaqGreenLight = Color(0xFF1A0A0E);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Phase 2 — Midnight Velvet & Crimson Neon Design Tokens
// Standard: Apple Design Award Winner × Linear × ChatGPT Plus × Duolingo
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AppVelvetTokens {
  const AppVelvetTokens._();

  // ── Midnight Velvet Background Layers ──────────────────────────────────────
  /// Obsidian base — deepest layer under everything
  static const Color obsidianBase    = Color(0xFF090E1A);
  /// Velvet void — main canvas / scaffold
  static const Color velvetCanvas    = Color(0xFF0C1122);
  /// Surface glass — card / message bubble back-panel
  static const Color glassPanel      = Color(0xFF111827);
  /// Elevated glass — modals, dialogs
  static const Color glassElevated   = Color(0xFF16223B);

  // ── Crimson Neon Accents ──────────────────────────────────────────────────
  /// Primary neon crimson — main brand accent
  static const Color neonCrimson     = Color(0xFFE8192C);
  /// Hot crimson — hover / active glow
  static const Color hotCrimson      = Color(0xFFFF2E44);
  /// Ember — dimmer accent for secondary elements
  static const Color ember           = Color(0xFFBF1122);
  /// Neon crimson with 15% opacity — subtle glass tint
  static Color neonCrimsonTint       = neonCrimson.withValues(alpha: 0.15);
  /// Neon crimson glow for box shadows
  static Color neonGlow              = neonCrimson.withValues(alpha: 0.35);

  // ── Frosted Glass Values ──────────────────────────────────────────────────
  static const double frostedBlur    = 22.0;   // blur sigma for BackdropFilter
  static const double glassOpacity   = 0.07;   // fill opacity for frost panels
  static const double rimOpacity     = 0.12;   // border opacity for glass rim
  static const double borderWidth    = 0.8;    // glass rim border width

  // ── Shimmer Colors (streaming AI response) ───────────────────────────────
  static const Color shimmerBase     = Color(0xFF1A2540);
  static const Color shimmerHighlight= Color(0xFF2A3F6A);
  static const Color shimmerAccent   = Color(0xFF334155);

  // ── Bioluminescent Orb Palette ────────────────────────────────────────────
  static const Color bioIdle         = Color(0xFF4B5563);
  static const Color bioListening    = Color(0xFF00FFCC);  // teal mint
  static const Color bioThinking     = Color(0xFF38BDF8);  // sky blue
  static const Color bioSpeaking     = Color(0xFFE8192C);  // crimson neon
  static const Color bioError        = Color(0xFFFF6B6B);

  // ── Neon Glow Box Shadow helper ───────────────────────────────────────────
  static List<BoxShadow> neonGlowShadow(Color color, {double blur = 20, double spread = 2}) => [
    BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: blur, spreadRadius: spread),
    BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: blur * 2, spreadRadius: 0),
  ];

  // ── Frosted Glass Decoration helper ──────────────────────────────────────
  static BoxDecoration frostedDecoration({
    Color? borderColor,
    double radius = 16,
    Color? glowColor,
    double glowBlur = 0,
  }) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: glassOpacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: rimOpacity),
          width: borderWidth,
        ),
        boxShadow: glowColor != null
            ? neonGlowShadow(glowColor, blur: glowBlur)
            : const [],
      );
}


class AppTheme {
  const AppTheme._();

  // ────────────────────────────────────────────────────────────────────────
  // Light Theme (blue-tinted light mode fallback)
  // ────────────────────────────────────────────────────────────────────────
  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        border: AppColors.lightBorder,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
      );

  // ────────────────────────────────────────────────────────────────────────
  // Dark Theme — primary: Deep Navy Blue × Crimson Red × Pure White
  // ────────────────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.navyDark,
        surface: AppColors.navyMid,
        border: AppColors.navyBorder,
        textPrimary: AppColors.pureWhite,
        textSecondary: AppColors.darkTextSecondary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    const primary = AppColors.crimsonRed;
    const onPrimary = AppColors.pureWhite;
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: AppColors.deepCrimson,
      onPrimaryContainer: onPrimary,
      secondary: isDark ? AppColors.navyAccent : AppColors.navyLight,
      onSecondary: onPrimary,
      secondaryContainer: isDark ? AppColors.navyLight : AppColors.lightBorder,
      onSecondaryContainer: isDark ? AppColors.pureWhite : AppColors.navyDark,
      tertiary: AppColors.navyAccent,
      onTertiary: onPrimary,
      tertiaryContainer: isDark ? AppColors.navyLight : AppColors.lightBackground,
      onTertiaryContainer: isDark ? AppColors.offWhite : AppColors.navyDark,
      error: AppColors.deepCrimson,
      onError: onPrimary,
      errorContainer: isDark ? const Color(0xFF3A0A12) : const Color(0xFFFFECED),
      onErrorContainer: isDark ? const Color(0xFFFF8A95) : AppColors.deepCrimson,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      inverseSurface: isDark ? AppColors.pureWhite : AppColors.navyDark,
      onInverseSurface: isDark ? AppColors.navyDark : onPrimary,
      inversePrimary: AppColors.brightRed,
      surfaceContainerHighest: isDark ? AppColors.navyLight : AppColors.lightBackground,
      scrim: AppColors.navyDeep,
    );

    // Selected indicator tint: dark navy-red / light rose-blue
    final selectedTint = isDark
        ? AppColors.crimsonRed.withValues(alpha: 0.18)
        : AppColors.crimsonRed.withValues(alpha: 0.10);

    // Nav bar background — slightly lighter than scaffold in dark mode
    final navBarBg = isDark ? AppColors.navyMid : AppColors.pureWhite;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark ? AppColors.navyDeep : Colors.black12,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.navyDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(AppDimens.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.deepCrimson.withValues(alpha: 0.30);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.brightRed.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.pureWhite : AppColors.navyDark,
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.navyLight : AppColors.lightBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.deepCrimson, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.deepCrimson, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBg,
        indicatorColor: selectedTint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 22);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.navyLight : AppColors.lightBackground,
        selectedColor: selectedTint,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: GoogleFonts.outfit(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return selectedTint;
            }
            return surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return textSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide(color: border)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.mutedSlate;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.crimsonRed.withValues(alpha: 0.25);
          }
          return border;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.navyLight : AppColors.navyDark,
        contentTextStyle: GoogleFonts.outfit(color: AppColors.pureWhite, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.navyLight : AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        shadowColor: AppColors.navyDeep,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.navyMid : AppColors.pureWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 16,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.navyLight : AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 12,
        shadowColor: AppColors.navyDeep,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.navyAccent : AppColors.navyDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.outfit(color: AppColors.pureWhite, fontSize: 12),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: textSecondary,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 13),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
    );
  }
}

