import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/logger/app_logger.dart';
import 'core/network/dio_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Android
      statusBarBrightness: Brightness.light, // iOS
    ),
  );
  // Pretty bloc transition logs alongside the app logger.
  Bloc.observer = AppBlocObserver();

  AppLogger.i('MessMax starting');
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // firebase_options.dart not yet generated — web Google still works, native waits for `flutterfire configure`
  }
  await DioClient.hydrateAuth();
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
