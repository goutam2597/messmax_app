/// Environment-agnostic app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'MessMax';
  static const String appTagline = 'Universal mess meal counter & seat locator';

  /// Host LAN IP address for backend connection across physical mobile devices,
  /// emulators, and local development environments.
  static const String baseDomain = 'mess-max-7c0b977fb506.herokuapp.com';
  // static const String baseDomain = '192.168.0.173';

  /// Backend origin base URL using host IP.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    // return 'http://$baseDomain/messmax/backend/public/api';
    return 'http://$baseDomain/api';
  }

  /// Ensure image URLs pointing to localhost or 10.0.2.2 map to the host IP.
  static String? sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return url
        .replaceAll(
          'http://localhost',
          'http://$baseDomain/messmax/backend/public',
        )
        .replaceAll(
          'http://127.0.0.1',
          'http://$baseDomain/messmax/backend/public',
        )
        .replaceAll(
          'http://10.0.2.2',
          'http://$baseDomain/messmax/backend/public',
        );
  }

  /// API request timeout.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
