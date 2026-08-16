import 'package:dio/dio.dart';

/// Attaches the auth token to outgoing requests once login lands.
///
/// Kept wired in from day one so adding auth later is a one-line change.
class AuthInterceptor extends Interceptor {
  // TODO(mvp): read token from secure storage after login is implemented.
  String? accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}
