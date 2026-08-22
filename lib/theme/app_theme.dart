import 'package:flutter/material.dart';

/// Palette lifted from the HelpFourU web prototype (`css/style.css` :root).
class AppColors {
  static const green = Color(0xFF08A66C);
  static const greenDark = Color(0xFF087E70);
  static const blue = Color(0xFF24518F);
  static const blueDark = Color(0xFF173E73);
  static const ink = Color(0xFF12243B);
  static const muted = Color(0xFF708096);
  static const bg = Color(0xFFEEF3F7);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8EF);
  static const danger = Color(0xFFEF5B68);
  static const warning = Color(0xFFF6A73A);

  // Tints used repeatedly across the prototype.
  static const mint = Color(0xFFE7F8F1);
  static const mintBorder = Color(0xFFCCEEE0);
  static const iceBlue = Color(0xFFEDF4FB);
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

  static const providerAvatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F8F2), Color(0xFFEAF0FA)],
  );
}

class AppTheme {
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
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
