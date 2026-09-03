import 'package:flutter/material.dart';

/// HelpFourU design-system palette.
///
/// `green` + `blue` pair as the signature gradient used across hero
/// surfaces, primary CTAs and avatars.
class AppColors {
  static const green = Color(0xFF0BA360);
  static const greenDark = Color(0xFF08794A);
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const ink = Color(0xFF12243B);
  static const muted = Color(0xFF708096);

  // Semantic tokens for statuses, badges and promotional surfaces.
  static const success = Color(0xFF10B981);
  static const purple = Color(0xFF7C3AED);
  static const bg = Color(0xFFEEF3F7);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8EF);
  static const danger = Color(0xFFEF5B68);
  static const warning = Color(0xFFF59E0B);

  // Tints used repeatedly across the prototype.
  static const mint = Color(0xFFE6F7EF);
  static const mintBorder = Color(0xFFC5EBD8);
  static const iceBlue = Color(0xFFEAF1FE);
  static const screenBg = Color(0xFFF6F9FB);
  static const homeBg = Color(0xFFF5F8FB);
  static const authBg = Color(0xFFF8FBFD);
  static const star = Color(0xFFE89A21);
}

/// The gradients the prototype leans on for hero surfaces and CTAs.
class AppGradients {
  static const primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.green, AppColors.blue],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.greenDark, AppColors.green, AppColors.blue],
    stops: [0.0, 0.47, 1.0],
  );

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.green, AppColors.blue],
  );

  static const banner = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.greenDark, AppColors.blue],
  );

  static const onboardBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAFFF5), Color(0xFFEDF4FF)],
  );

  static const avatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.green, AppColors.blue],
  );

  static const purpleBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, AppColors.blueDark],
  );

  static const providerAvatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F8F2), Color(0xFFEAF0FA)],
  );
}

class AppTheme {
  /// Primary family is Latin-only; Devanagari glyphs (Hindi copy, names,
  /// addresses) fall back to the matching Noto weight automatically so
  /// mixed-script text never falls back to the OS default font.
  static const _fontFamily = 'NotoSans';
  static const _fontFamilyFallback = ['NotoSansDevanagari'];

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.screenBg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.green,
        secondary: AppColors.blue,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
            fontFamily: _fontFamily,
          )
          .copyWith(
            displayLarge: base.textTheme.displayLarge?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            displayMedium: base.textTheme.displayMedium?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            displaySmall: base.textTheme.displaySmall?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            headlineLarge: base.textTheme.headlineLarge?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            titleSmall: base.textTheme.titleSmall?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            bodyLarge: base.textTheme.bodyLarge?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            labelLarge: base.textTheme.labelLarge?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            labelMedium: base.textTheme.labelMedium?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
            labelSmall: base.textTheme.labelSmall?.copyWith(
              fontFamilyFallback: _fontFamilyFallback,
            ),
          ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
