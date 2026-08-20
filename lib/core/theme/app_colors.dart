import 'package:flutter/material.dart';

/// Brand palette — mirrors the MessMax web console with premium mobile accents.
abstract final class AppColors {
  // brand
  static const Color brand = Color(0xFF081E2E);
  static const Color brandDark = Color(0xFF081E2E);
  static const Color brandDeep = Color(0xFF04101A);
  static const Color brandSoft = Color(0xFFE1E7ED);

  // accent (vibrant warm orange from logo)
  static const Color accent = Color(0xFFF82603);
  static const Color accentDark = Color(0xFFE73302);
  static const Color accentSoft = Color(0xFFFFE3DD);

  // ink
  static const Color ink = Color(0xFF081E2E);
  static const Color inkSoft = Color(0xFF383C43);
  static const Color inkFaded = Color(0xFF676E79);

  // paper
  static const Color paper = Color(0xFFF7F7F5);
  static const Color paperRaised = Color(0xFFFFFFFF);
  static const Color paperLine = Color(0xFFE6E3DC);

  // status accents
  static const Color emerald = Color(0xFF0F9F59);
  static const Color emeraldSoft = Color(0xFFE6F4EA);
  static const Color amber = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);

  // splash & hero gradient
  static const Color splashTop = Color(0xFFFFFFFF);
  static const Color splashBottom = Color(0xFFEBF0F3);
}
