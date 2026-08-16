import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Single configured [Dio] instance for the whole app.
///
/// Features receive this through their repositories; nobody constructs
/// their own Dio. Add headers / retry logic here, once, for everyone.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static final AuthInterceptor _authInterceptor = AuthInterceptor();

  static Dio get instance => _instance ??= create();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    )
      ..interceptors.addAll([
        _authInterceptor,
        LoggingInterceptor(),
      ]);

    return dio;
  }
}
