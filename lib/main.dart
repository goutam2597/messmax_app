import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'core/locale/app_translations.dart';
import 'core/locale/locale_service.dart';
import 'core/logger/app_logger.dart';
import 'core/network/dio_client.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    AppLogger.w('dotenv load warning: $e');
  }
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
    AppLogger.i('Firebase initialized successfully');
  } catch (e, st) {
    AppLogger.e('Firebase initialization failed: missing google-services.json or firebase_options.dart', e, st);
  }

  // Initialize GoogleSignIn once at app boot so the Android
  // Pigeon channel (getGoogleServicesJsonServerClientId) is bound
  // before any button tap. serverClientId is passed explicitly so
  // the plugin does NOT need to read the string resource over the
  // channel (avoids channel-error on hot-restart).
  if (!kIsWeb) {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '1069180546995-u7cik408g6uj08rctf798be1133n5fib.apps.googleusercontent.com',
      );
      AppLogger.i('GoogleSignIn initialized (native Credential Manager ready)');
    } catch (e, st) {
      AppLogger.w('GoogleSignIn initialize deferred/failed: \$e');
      AppLogger.e('GoogleSignIn init error', e, st);
    }
  }

  await DioClient.hydrateAuth();
  await PushNotificationService.initialize();
  final initialLocale = await LocaleService.loadInitialLocale();
  // Preload API translations for initial locale (SharedPreferences cache fallback if offline)
  await AppTranslations.load(initialLocale.languageCode);
  // Warm cache for other locale in background
  AppTranslations.preloadAll();
  runApp(MessMaxApp(initialLocale: initialLocale));
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
