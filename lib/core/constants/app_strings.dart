import '../locale/app_translations.dart';

/// User-facing copy — now API-driven. Keep constants only for non-translated fallbacks.
abstract final class AppStrings {
  static const String appName = 'MessMax';
  static String get tagline => 'ui.splash_tagline'.tr2;

  // welcome — API keys (ui.welcome_*)
  static String get welcomeTitle => 'ui.welcome_title'.tr2;
  static String get welcomeSubtitle => 'ui.welcome_subtitle'.tr2;
  static String get findMesses => 'ui.welcome_find_messes'.tr2;
  static String get createMess => 'ui.welcome_create_mess'.tr2;
  static String get alreadyHaveAccount => 'ui.welcome_already_account'.tr2;
  static String get login => 'ui.welcome_login'.tr2;

  // feature highlights
  static String get featureMealCount => 'ui.welcome_feature_meal'.tr2;
  static String get featureBazarLedger => 'ui.welcome_feature_bazar'.tr2;
  static String get featureDeposits => 'ui.welcome_feature_deposits'.tr2;
  static String get featurePostMessAds => 'ui.welcome_feature_ads'.tr2;
  static String get featureFindMess => 'ui.welcome_feature_find'.tr2;
  static String get featureSmartReports => 'ui.welcome_feature_reports'.tr2;
}
