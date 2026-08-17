import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/auth_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'splash_state.dart';

/// Runs boot-time work behind the splash screen.
class SplashCubit extends Cubit<SplashState> {
  final AuthRepository _authRepo;
  SplashCubit({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepository(),
        super(const SplashLoading());

  static const Duration _minSplashTime = Duration(milliseconds: 2200);

  Future<void> start() async {
    AppLogger.i('Splash: booting ${DateTime.now()}');
    final sw = Stopwatch()..start();

    SplashDestination dest = SplashDestination.welcome;
    try {
      final token = await AuthStorage.readToken();
      if (token != null && token.isNotEmpty) {
        DioClient.setAuthToken(token);
        try {
          await _authRepo.fetchMe();
          dest = SplashDestination.home;
        } catch (_) {
          await AuthStorage.clear();
          DioClient.clearAuthToken();
          dest = SplashDestination.welcome;
        }
      }
    } catch (e) {
      AppLogger.w('Splash auth check failed: $e');
    }

    final remaining = _minSplashTime - sw.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    AppLogger.d('Splash: boot finished in ${sw.elapsedMilliseconds}ms -> $dest');
    emit(SplashReady(destination: dest));
  }
}
