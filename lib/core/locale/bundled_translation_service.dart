import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../logger/app_logger.dart';

/// Loads translation JSON files bundled with the app
/// (`assets/translations/{locale}.json`).
///
/// Used as the offline-safe fallback when neither the SharedPreferences
/// cache nor the backend has translations for the selected locale.
class BundledTranslationService {
  BundledTranslationService._();

  static final Map<String, Map<String, String>> _cache = {};

  /// Load bundled JSON for a locale. Returns empty map if asset missing.
  static Future<Map<String, String>> load(String locale) async {
    if (_cache.containsKey(locale)) return _cache[locale]!;
    try {
      final raw = await rootBundle.loadString('assets/translations/$locale.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = decoded.map((k, v) => MapEntry(k, v.toString()));
      _cache[locale] = map;
      AppLogger.i('Bundled translations loaded: $locale (${map.length} keys)');
      return map;
    } catch (e) {
      AppLogger.w('No bundled translations for $locale: $e');
      _cache[locale] = {};
      return _cache[locale]!;
    }
  }
}
