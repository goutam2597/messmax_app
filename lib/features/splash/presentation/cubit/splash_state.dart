import 'package:equatable/equatable.dart';

/// Where the splash flow should land once boot work finishes.
enum SplashDestination { welcome, dashboard }

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// Boot work (config, future session check) is running.
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// Boot finished — [destination] tells the screen where to navigate.
class SplashReady extends SplashState {
  const SplashReady({required this.destination});

  final SplashDestination destination;

  @override
  List<Object?> get props => [destination];
}
