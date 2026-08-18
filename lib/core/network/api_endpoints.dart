/// Central registry of backend API paths.
class ApiEndpoints {
  ApiEndpoints._();

  // home & ads
  static const String home = '/v1/home';
  static const String ads = '/v1/ads';
  static const String areas = '/v1/areas';
  static const String cities = '/v1/cities';
  static const String blogs = '/v1/blogs';

  // auth (Sanctum Bearer)
  static const String authRegister = '/v1/auth/register';
  static const String authLogin = '/v1/auth/login';
  static const String authFirebase = '/v1/auth/firebase';
  static const String authLogout = '/v1/auth/logout';
  static const String me = '/v1/me';
  static const String dashboard = '/v1/dashboard';
  static const String account = '/v1/account';
  static const String accountPassword = '/v1/account/password';
  static const String members = '/v1/members';
  static const String messes = '/v1/messes';
  static const String publicNotifications = '/v1/public-notifications';
}
