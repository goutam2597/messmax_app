import 'package:flutter/foundation.dart';

/// Environment-agnostic app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'MessMax';
  static const String appTagline = 'Universal mess meal counter & seat locator';

  /// Host LAN IP address for backend connection across physical mobile devices,
  /// emulators, and local development environments.
  static const String hostIp = '192.168.0.173';

  /// Backend origin base URL using host IP.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    return 'http://$hostIp/messmax/backend/public/api';
  }

  /// API request timeout.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
