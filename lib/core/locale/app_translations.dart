import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logger/app_logger.dart';
import 'remote_translation_service.dart';

/// Simple translation registry backed by API + SharedPreferences cache.
/// No bundled JSON — 100% API-driven.
class AppTranslations {
  static Map<String, String> _current = {};
  static String _locale = 'en';
  static final ValueNotifier<int> _notifier = ValueNotifier(0);

  static ValueNotifier<int> get notifier => _notifier;
  static String get locale => _locale;
  static bool get isLoaded => _current.isNotEmpty;

  static Future<void> load(String locale) async {
    _locale = locale;
    final remote = await RemoteTranslationService.fetchLocale(locale);
    if (remote.isNotEmpty) {
      _current = remote;
      _notifier.value++;
      return;
    }
    // No API response — try stale cache for same locale
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('remote_translations_$locale');
      if (cached != null && cached.isNotEmpty) {
        AppLogger.w('API unavailable for $locale, using stale cache');
        _notifier.value++;
        return;
      }
    } catch (_) {}
    AppLogger.w('No translations for $locale, keys will show as-is');
    _current = {};
    _notifier.value++;
  }

  static String t(String key, {String? fallback}) {
    return _current[key] ?? fallback ?? key;
  }

  static Future<void> preloadAll() async {
    for (final loc in ['en', 'bn']) {
      try {
        await RemoteTranslationService.fetchLocale(loc);
      } catch (_) {}
    }
  }
}

extension AppTranslateX on String {
  String get tr2 => AppTranslations.t(this);
}
