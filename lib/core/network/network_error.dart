import 'package:dio/dio.dart';

/// Classifies network failures so the UI can react appropriately:
///
/// - Server unreachable (timeout / no connection): the caller may surface
///   the FULL backend/dio message (e.g. on the home screen).
/// - Any other network/backend problem: callers should keep messaging
///   SUBTLE instead of dumping raw exception text in the user's face.
class NetworkError {
  NetworkError._();

  /// Stable machine-friendly code for each failure kind so the UI can show
  /// something like "ERR-NET-1001" instead of raw exception text.
  static String codeFor(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'ERR-NET-1001';
        case DioExceptionType.connectionError:
          return 'ERR-NET-1002';
        case DioExceptionType.sendTimeout:
          return 'ERR-NET-1003';
        case DioExceptionType.receiveTimeout:
          return 'ERR-NET-1004';
        case DioExceptionType.badCertificate:
          return 'ERR-TLS-2001';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode ?? 0;
          return status >= 500 ? 'ERR-SRV-$status' : 'ERR-API-$status';
        case DioExceptionType.cancel:
          return 'ERR-NET-0009';
        default:
          break;
      }
    }
    return 'ERR-NET-0000';
  }

  static bool isServerUnreachable(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  /// Full raw message (DioException detail, backend response body, etc.)
  /// — only for prominent display when the whole backend is unreachable.
  static String fullMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return e.message != null
          ? '${_typeLabel(e.type)}: ${e.message}'
          : _typeLabel(e.type);
    }
    return e.toString();
  }

  /// Short, calm one-liner for everyday network/backend hiccups.
  static String subtleMessage(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode ?? 0;
          if (status >= 500) return 'Server issue, please try again shortly.';
          return 'Something went wrong. Please try again.';
        case DioExceptionType.badCertificate:
          return 'Secure connection failed. Please try again.';
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        default:
          break;
      }
    }
    return 'Network problem. Please check your connection.';
  }

  static String _typeLabel(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.badResponse:
        return 'Bad response';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error';
      default:
        return 'Network error';
    }
  }
}
