import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_translations.dart';
import 'locale_service.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(super.initial);

  Future<void> setLocale(String code) async {
    final locale = LocaleService.resolveLocale(code);
    // Load API translations before emitting so UI rebuilds with new strings
    await AppTranslations.load(locale.languageCode);
    emit(locale);
    await LocaleService.writeCode(locale.languageCode);
  }

  bool get isBengali => state.languageCode == 'bn';
}
