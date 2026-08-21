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
    // TEMP(1.0.1+3): enable debug/info in release for internal testing — revert to kDebugMode ? debug : warning after fix.
    level: Level.debug,
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
