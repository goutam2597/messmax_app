import 'package:flutter/material.dart';

/// Brand palette — mirrors the MessMax web console.
///
/// brand = signature orange, ink = near-black text/panels,
/// paper = warm off-white surfaces.
abstract final class AppColors {
  // brand
  static const Color brand = Color(0xFF1B303B);
  static const Color brandDark = Color(0xFF13232B);
  static const Color brandDeep = Color(0xFF0C161B);
  static const Color brandSoft = Color(0xFFE4E9EB);

  // ink
  static const Color ink = Color(0xFF17191D);
  static const Color inkSoft = Color(0xFF3A3E45);
  static const Color inkFaded = Color(0xFF6B7078);

  // paper
  static const Color paper = Color(0xFFFAF9F6);
  static const Color paperRaised = Color(0xFFFFFFFF);
  static const Color paperLine = Color(0xFFE7E4DD);

  // accents
  static const Color success = Color(0xFF1D7A4F);
  static const Color danger = Color(0xFFB3362B);

  // splash gradient (light paper → soft brand tint)
  static const Color splashTop = Color(0xFFFFFFFF);
  static const Color splashBottom = Color(0xFFE4E9EB);
}
