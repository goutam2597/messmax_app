import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'auth_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Single configured [Dio] instance for the whole app.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static final AuthInterceptor _authInterceptor = AuthInterceptor();

  static AuthInterceptor get authInterceptor => _authInterceptor;

  static Dio get instance => _instance ??= create();

  static void setAuthToken(String? token) {
    _authInterceptor.setToken(token);
  }

  static void clearAuthToken() {
    _authInterceptor.clearToken();
  }

  /// Call once at startup so the interceptor has the persisted token.
  static Future<void> hydrateAuth() => AuthStorage.hydrate();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    )
      ..interceptors.addAll([
        _authInterceptor,
        LoggingInterceptor(),
      ]);

    // Allow Laragon local development self-signed certificates
    if (!kIsWeb) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    return dio;
  }
}
