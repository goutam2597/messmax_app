import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _kLocaleCode = 'app_locale_code';

  // Supported: en, bn (matches backend config/app.php supported_locales)
  static const supportedLocales = [Locale('en'), Locale('bn')];

  static String get supportedCodes =>
      supportedLocales.map((l) => l.languageCode).join(', ');

  static Locale resolveLocale(String code) {
    if (code == 'bn') return const Locale('bn');
    return const Locale('en');
  }

  static Future<String?> readCode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLocaleCode);
  }

  static Future<void> writeCode(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocaleCode, code);
  }

  static Future<Locale> loadInitialLocale() async {
    final code = await readCode();
    if (code != null) return resolveLocale(code);
    // Fallback to device locale if supported, else en
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    if (device.languageCode == 'bn') return const Locale('bn');
    return const Locale('en');
  }
}
