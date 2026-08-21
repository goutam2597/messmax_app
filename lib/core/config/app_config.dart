import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment-agnostic app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'MessMax';
  static const String appTagline = 'Universal mess meal counter & seat locator';
  static const String baseDomain = 'messmax.net';

  /// Backend origin base URL loaded directly from .env.
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Client API Security Key loaded directly from .env.
  static String get xApiKey => dotenv.env['X_API_KEY'] ?? '';

  /// Ensure image URLs pointing to localhost or 10.0.2.2 map to host domain.
  static String? sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return url
        .replaceAll('http://localhost', 'https://$baseDomain')
        .replaceAll('http://127.0.0.1', 'https://$baseDomain')
        .replaceAll('http://10.0.2.2', 'https://$baseDomain');
  }

  /// API request timeout.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
