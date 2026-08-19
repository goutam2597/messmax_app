import '../locale/app_translations.dart';

/// Localized number formatting — mirrors backend helpers numfmt / bn_digits.
String bnDigits(Object? value) {
  final str = value?.toString() ?? '';
  if (AppTranslations.locale != 'bn') return str;
  const map = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };
  return str.split('').map((c) => map[c] ?? c).join();
}

String numFmt(num? number, {int decimals = 0}) {
  number ??= 0;
  final formatted = number.toStringAsFixed(decimals);
  // Add thousands separator like backend number_format
  final parts = formatted.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  final withDec = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  if (AppTranslations.locale != 'bn') return withDec;
  return bnDigits(withDec);
}
