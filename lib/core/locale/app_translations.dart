import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import 'bundled_translations.dart';
import 'remote_translation_service.dart';

/// Translation registry backed by bundled zero-network fallback + API + SharedPreferences cache.
class AppTranslations {
  static Map<String, String> _current = BundledTranslations.get('en');
  static String _locale = 'en';
  static final ValueNotifier<int> _notifier = ValueNotifier(0);

  static ValueNotifier<int> get notifier => _notifier;
  static String get locale => _locale;
  static bool get isLoaded => _current.isNotEmpty;

  static Future<void> load(String locale) async {
    _locale = locale;
    // Set bundled fallback synchronously first so no raw keys flash
    _current = Map<String, String>.from(BundledTranslations.get(locale));
    _notifier.value++;

    // Fetch fresh translations from API (with SharedPreferences cache fallback)
    final remote = await RemoteTranslationService.fetchLocale(locale);
    if (remote.isNotEmpty) {
      _current = {..._current, ...remote};
      _notifier.value++;
      return;
    }

    AppLogger.i('Using bundled translations for $locale (${_current.length} keys)');
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
