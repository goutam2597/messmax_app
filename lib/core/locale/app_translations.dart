import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import 'bundled_translations.dart';
import 'remote_translation_service.dart';

/// Translation registry backed by English zero-network fallback + API + SharedPreferences cache.
class AppTranslations {
  // Always initialize with English fallback so no raw keys are ever shown
  static Map<String, String> _current = Map<String, String>.from(BundledTranslations.en);
  static Map<String, String> _enFallback = Map<String, String>.from(BundledTranslations.en);
  static String _locale = 'en';
  static final ValueNotifier<int> _notifier = ValueNotifier(0);

  static ValueNotifier<int> get notifier => _notifier;
  static String get locale => _locale;
  static bool get isLoaded => _current.isNotEmpty;

  static Future<void> load(String locale) async {
    _locale = locale;

    // 1. Ensure we always have English fallback loaded
    if (_enFallback.isEmpty) {
      _enFallback = Map<String, String>.from(BundledTranslations.en);
    }
    // Also fetch fresh English from API if not loaded
    final remoteEn = await RemoteTranslationService.fetchLocale('en');
    if (remoteEn.isNotEmpty) {
      _enFallback = {..._enFallback, ...remoteEn};
    }

    // 2. If target locale is 'en', set _current to _enFallback
    if (locale == 'en') {
      _current = Map<String, String>.from(_enFallback);
      _notifier.value++;
      return;
    }

    // 3. For any non-English locale (e.g. 'bn', or future dynamic locales):
    // Start with English fallback so missing keys render in English, NOT raw keys.
    _current = Map<String, String>.from(_enFallback);

    // 4. Fetch target locale from API (with SharedPreferences cache fallback)
    final remote = await RemoteTranslationService.fetchLocale(locale);
    if (remote.isNotEmpty) {
      _current = {..._current, ...remote};
      AppLogger.i('Loaded $locale translations from API/cache (${remote.length} keys merged over English fallback)');
    } else {
      AppLogger.w('API/cache unavailable for $locale; using English fallback');
    }

    _notifier.value++;
  }

  /// Resolve key:
  /// 1. Check current locale map (_current)
  /// 2. Check English fallback (_enFallback)
  /// 3. Return explicit fallback parameter or key
  static String t(String key, {String? fallback}) {
    return _current[key] ?? _enFallback[key] ?? fallback ?? key;
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
