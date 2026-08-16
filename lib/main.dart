import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/logger/app_logger.dart';

void main() {
  // Pretty bloc transition logs alongside the app logger.
  Bloc.observer = AppBlocObserver();

  AppLogger.i('MessMax starting');

  runApp(const MessMaxApp());
}

/// Logs every bloc/cubit event, transition and error through [AppLogger].
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    AppLogger.d('bloc+ ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    AppLogger.d(
      'bloc~ ${bloc.runtimeType}: ${change.currentState} → '
      '${change.nextState}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppLogger.e('bloc! ${bloc.runtimeType}', error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    AppLogger.d('bloc- ${bloc.runtimeType}');
  }
}
