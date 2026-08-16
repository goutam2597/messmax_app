// Splash cubit behavior — boot work always lands on the welcome destination.
//
// (Widget-tree smoke tests would need font/network stubbing for
// google_fonts, so the MVP keeps tests on pure logic.)

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messmax_app/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:messmax_app/features/splash/presentation/cubit/splash_state.dart';

void main() {
  group('SplashCubit', () {
    test('starts in loading state', () {
      expect(SplashCubit().state, isA<SplashLoading>());
    });

    blocTest<SplashCubit, SplashState>(
      'start() emits SplashReady with welcome destination',
      build: SplashCubit.new,
      act: (cubit) => cubit.start(),
      expect: () => [
        const SplashReady(destination: SplashDestination.welcome),
      ],
    );
  });
}
