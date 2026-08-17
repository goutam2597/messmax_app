import 'package:dio/dio.dart';

import '../auth_storage.dart';

/// Attaches the Bearer token to outgoing requests.
class AuthInterceptor extends Interceptor {
  String? _overrideToken;

  void setToken(String? token) {
    _overrideToken = token;
    AuthStorage.setTokenInMemory(token);
  }

  void clearToken() {
    _overrideToken = null;
    AuthStorage.setTokenInMemory(null);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _overrideToken ?? AuthStorage.cachedToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
