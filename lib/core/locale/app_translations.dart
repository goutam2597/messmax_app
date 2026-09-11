import 'package:flutter/foundation.dart';

import '../logger/app_logger.dart';
import 'bundled_translation_service.dart';
import 'remote_translation_service.dart';

/// Translation registry.
///
/// Priority: bundled `en.json` (always) → cached/API translations for the
/// selected locale (merged on top). A missing key in the selected locale
/// falls back to its English value; raw keys are never shown.
class AppTranslations {
  static Map<String, String> _current = {};
  static Map<String, String> _english = {};
  static String _locale = 'en';
  static final ValueNotifier<int> _notifier = ValueNotifier(0);

  static ValueNotifier<int> get notifier => _notifier;
  static String get locale => _locale;
  static bool get isLoaded => _current.isNotEmpty;

  static Future<void> load(String locale) async {
    _locale = locale;
    // 1. Bundled English is always the offline-safe base layer.
    if (_english.isEmpty) {
      _english = await BundledTranslationService.load('en');
    }
    // 2. Cached translations load instantly (<1ms); API refresh happens
    //    in background and calls updateCurrent() when it succeeds.
    final remote = await RemoteTranslationService.fetchLocale(locale);
    _sanitize(remote);
    _current = {..._english, ...remote};
    AppLogger.i(
      'Loaded $locale: ${_current.length} keys '
      '(${remote.length} remote, ${_english.length} bundled en)',
    );
    _notifier.value++;
  }

  static void updateCurrent(Map<String, String> newMap) {
    _sanitize(newMap);
    // Keep English base underneath so missing keys never show as raw keys.
    _current = {..._english, ...newMap};
    _notifier.value++;
  }

  static void _sanitize(Map<String, String> map) {
    if (map['ui.sheet_save_entry'] == 'এন্ট্রি সংরক্ষণ করুন') {
      map['ui.sheet_save_entry'] = 'সেভ করুন';
    }
    if (map['ui.sheet_save'] == 'এন্ট্রি সংরক্ষণ করুন') {
      map['ui.sheet_save'] = 'সেভ করুন';
    }
  }

  static String t(String key, {String? fallback}) {
    final val = _current[key] ?? fallback ?? key;
    return val.replaceAll(r'\n', '\n').replaceAll('\\n', '\n');
  }

  /// Warm cache for other supported locales in background.
  static Future<void> preloadAll() async {
    for (final code in const ['en', 'bn']) {
      if (code == _locale) continue;
      try {
        await RemoteTranslationService.fetchLocale(code);
      } catch (_) {}
    }
  }
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
