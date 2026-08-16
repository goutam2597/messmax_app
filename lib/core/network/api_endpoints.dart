/// Central registry of backend API paths.
class ApiEndpoints {
  ApiEndpoints._();

  // home & ads
  static const String home = '/v1/home';
  static const String ads = '/v1/ads';

  // auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // messes
  static const String messes = '/messes';
}
