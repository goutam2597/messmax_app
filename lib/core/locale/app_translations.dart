import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import 'remote_translation_service.dart';

/// Translation registry — 100% API-driven via RemoteTranslationService.
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
      AppLogger.i('Loaded $locale from API: ${remote.length} keys');
    } else {
      AppLogger.w('No translations for $locale — showing raw keys');
      _current = {};
    }
    _notifier.value++;
  }

  static String t(String key, {String? fallback}) {
    return _current[key] ?? fallback ?? key;
  }

  static Future<void> preloadAll() async {}
}

extension AppTranslateX on String {
  String get tr2 => AppTranslations.t(this);
}
