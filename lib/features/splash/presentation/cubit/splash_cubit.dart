import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import 'splash_state.dart';

/// Runs boot-time work behind the splash screen.
///
/// MVP: minimum display time + a session hook placeholder. When login
/// lands, the token check decides between [SplashDestination.home] and
/// [SplashDestination.welcome].
class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashLoading());

  static const Duration _minSplashTime = Duration(milliseconds: 2200);

  Future<void> start() async {
    AppLogger.i('Splash: booting ${DateTime.now()}');
    final sw = Stopwatch()..start();

    // TODO(mvp): check stored session via DioClient here.

    final remaining = _minSplashTime - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    AppLogger.d('Splash: boot finished in ${sw.elapsedMilliseconds}ms');
    emit(const SplashReady(destination: SplashDestination.welcome));
  }
}
