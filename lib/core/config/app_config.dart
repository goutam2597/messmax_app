import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Environment-agnostic app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'MessMax';
  static const String appTagline = 'Universal mess meal counter & seat locator';

  /// Backend origin base URL.
  /// Automatically uses 10.0.2.2 for Android emulator and localhost for Desktop/Web/iOS.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2/messmax/backend/public/api';
    }
    return 'http://localhost/messmax/backend/public/api';
  }

  /// API request timeout.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
