import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/cubit/splash_cubit.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

/// Root widget — theme + splash entry point.
class MessMaxApp extends StatelessWidget {
  const MessMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: BlocProvider(
        create: (_) => SplashCubit(),
        child: const SplashScreen(),
      ),
    );
  }
}
