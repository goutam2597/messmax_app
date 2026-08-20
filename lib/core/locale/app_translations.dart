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
      AppLogger.i('Loaded $locale: ${remote.length} keys');
    } else {
      AppLogger.w('No translations for $locale — using fallback');
      _current = {};
    }
    _notifier.value++;
  }

  static void updateCurrent(Map<String, String> newMap) {
    _current = newMap;
    _notifier.value++;
  }

  static String t(String key, {String? fallback}) {
    final val = _current[key] ?? fallback ?? key;
    return val.replaceAll(r'\n', '\n').replaceAll('\\n', '\n');
  }

  static Future<void> preloadAll() async {}
}

extension AppTranslateX on String {
  String get tr2 => AppTranslations.t(this);

  String toBnNum() {
    if (AppTranslations.locale != 'bn') return this;
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var res = this;
    for (var i = 0; i < en.length; i++) {
      res = res.replaceAll(en[i], bn[i]);
    }
    return res;
  }
}

extension AppIntTranslateX on int {
  String toBnNum() => toString().toBnNum();
}

extension AppDoubleTranslateX on double {
  String toBnNum([int fractionDigits = 2]) {
    final str = toStringAsFixed(fractionDigits).replaceAll(RegExp(r'\.?0+$'), '');
    return str.toBnNum();
  }
}
