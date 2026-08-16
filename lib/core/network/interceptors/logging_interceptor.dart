import 'package:dio/dio.dart';

import '../../logger/app_logger.dart';

/// Logs every request, response and error that flows through the Dio client.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.i(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '✕ ${err.requestOptions.method} ${err.requestOptions.uri}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }
}
