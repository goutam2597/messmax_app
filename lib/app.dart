import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/locale/app_translations.dart';
import 'core/locale/locale_cubit.dart';
import 'core/locale/locale_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/dashboard/presentation/cubit/notification_cubit.dart';
import 'features/splash/presentation/cubit/splash_cubit.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

/// Root widget — theme + splash entry point.
/// Translations are 100% API-driven via AppTranslations (no bundled JSON).
class MessMaxApp extends StatelessWidget {
  final Locale initialLocale;
  const MessMaxApp({super.key, this.initialLocale = const Locale('en')});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkAuth()),
        BlocProvider(create: (_) => SplashCubit()),
        BlocProvider(create: (_) => NotificationCubit()..loadNotifications()),
        BlocProvider(create: (_) => LocaleCubit(initialLocale)),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return ValueListenableBuilder<int>(
            valueListenable: AppTranslations.notifier,
            builder: (context, _, _) {
              return MaterialApp(
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                locale: locale,
                supportedLocales: LocaleService.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
