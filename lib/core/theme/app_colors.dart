import 'package:flutter/material.dart';

/// Brand palette — primary stack built around coral #FE5B56.
abstract final class AppColors {
  // brand (primary)
  static const Color brand = Color(0xFFFE5B56);
  static const Color brandDark = Color(0xFFE8433E);
  static const Color brandDeep = Color(0xFFC22F2B);
  static const Color brandSoft = Color(0xFFFFECEA);

  // accent (vibrant warm orange from SVG logo)
  static const Color accent = Color(0xFFF82603);
  static const Color accentDark = Color(0xFFE73302);
  static const Color accentSoft = Color(0xFFFFE3DD);

  // ink
  static const Color ink = Color(0xFF14171A);
  static const Color inkSoft = Color(0xFF3A4048);
  static const Color inkFaded = Color(0xFF707A86);

  // paper — clean, cool, airy light surfaces
  static const Color paper = Color(0xFFF6F8FA);
  static const Color paperRaised = Color(0xFFFEFEFE);
  static const Color paperLine = Color(0xFFE8EBEF);

  // status accents
  static const Color emerald = Color(0xFF0F9F59);
  static const Color emeraldSoft = Color(0xFFE6F4EA);
  static const Color amber = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);

  // extended card accents (muted, professional)
  static const Color blue = Color(0xFF3B82C4);
  static const Color blueSoft = Color(0xFFEDF4FB);
  static const Color violet = Color(0xFF7B6FC9);
  static const Color violetSoft = Color(0xFFF1EFFA);
  static const Color teal = Color(0xFF2E9E93);
  static const Color tealSoft = Color(0xFFE8F5F3);

  // splash & hero gradient
  static const Color splashTop = Color(0xFFFFFFFF);
  static const Color splashBottom = Color(0xFFEBF0F3);
}
