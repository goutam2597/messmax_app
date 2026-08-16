import 'package:flutter/material.dart';

/// Brand palette — mirrors the MessMax web console with premium mobile accents.
abstract final class AppColors {
  // brand
  static const Color brand = Color(0xFF1B303B);
  static const Color brandDark = Color(0xFF13232B);
  static const Color brandDeep = Color(0xFF0C161B);
  static const Color brandSoft = Color(0xFFEBF0F3);

  // accent (vibrant warm coral/orange for badges & seat highlights)
  static const Color accent = Color(0xFFE85D04);
  static const Color accentDark = Color(0xFFDC2F02);
  static const Color accentSoft = Color(0xFFFFE8D6);

  // ink
  static const Color ink = Color(0xFF14171A);
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
