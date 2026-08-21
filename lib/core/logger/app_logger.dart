import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Single app-wide logger.
///
/// Every layer (UI, blocs, network, future repositories) logs through this
/// instead of `print`, so output stays pretty, leveled and easy to silence.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // Silent in release — only debug/info in debug builds.
    level: kDebugMode ? Level.debug : Level.warning,
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
