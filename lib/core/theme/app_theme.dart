import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light-only theme for the MVP, built on the MessMax brand palette.
///
/// Uses bundled system fonts — no runtime font download, so no
/// `google_fonts` AOT crash. Add a self-hosted font later if needed.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      surface: AppColors.paperRaised,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.ink, width: 1.4),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
      ),
    );
  }
}
