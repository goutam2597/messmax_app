import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/auth_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  AuthCubit({AuthRepository? repo})
      : _repo = repo ?? AuthRepository(),
        super(const AuthInitial());

  String? _extractMessage(Object e) {
    if (e is DioException) {
      final resp = e.response;
      if (resp?.data is Map) {
        final m = resp?.data as Map;
        final msg = m['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
        final errors = m['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
      return e.error?.toString() ?? e.message ?? 'Request failed';
    }
    return e.toString();
  }

  Future<void> checkAuth() async {
    emit(const AuthLoading(AuthLoadingType.general));
    try {
      await AuthStorage.hydrate();
      DioClient.setAuthToken(AuthStorage.cachedToken);
      final token = AuthStorage.cachedToken;
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }
      final user = await _repo.fetchMe();
      AuthStorage.setUserInMemory(user);
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      AppLogger.e('AuthCubit.checkAuth failed — clearing', e, st);
      await AuthStorage.clear();
      DioClient.clearAuthToken();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading(AuthLoadingType.email));
    AppLogger.i('Email login attempt email=$email');
    try {
      final res = await _repo.login(email: email, password: password);
      AppLogger.i('Email login success user=${res.user.id}');
      emit(AuthAuthenticated(res.user));
    } catch (e, st) {
      AppLogger.e('Email login failed', e, st);
      emit(AuthError(_extractMessage(e) ?? 'Login failed'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String accountType,
  }) async {
    emit(const AuthLoading(AuthLoadingType.email));
    AppLogger.i('Register attempt email=$email type=$accountType');
    try {
      final res = await _repo.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        accountType: accountType,
      );
      AppLogger.i('Register success user=${res.user.id}');
      emit(AuthAuthenticated(res.user));
    } catch (e, st) {
      AppLogger.e('Register failed', e, st);
      emit(AuthError(_extractMessage(e) ?? 'Registration failed'));
    }
  }

  /// Google sign-in — native in-app popup (Android Credential Manager
  /// bottom-sheet), never Chrome / url_launcher.
  /// Always resets the button: cancel -> AuthUnauthenticated so spinner stops.
  Future<bool?> loginWithGoogle({String? accountType}) async {
    emit(const AuthLoading(AuthLoadingType.google));
    AppLogger.i('Google sign-in tapped (accountType=$accountType)');
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.e('Google sign-in: Firebase not initialized');
        throw Exception(
          'Firebase is not initialized. Place google-services.json in android/app/ and restart.',
        );
      }

      String? idToken;

      if (kIsWeb) {
        AppLogger.d('Google sign-in: web popup flow');
        final auth = FirebaseAuth.instance;
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final cred = await auth.signInWithPopup(provider);
        idToken = await cred.user?.getIdToken();
        AppLogger.i('Web popup: idToken present=${idToken != null && idToken.isNotEmpty}');
      } else {
        // Re-init with explicit serverClientId so the plugin does NOT
        // call Pigeon getGoogleServicesJsonServerClientId (which throws
        // channel-error on hot-restart). Idempotent — ignore AlreadyInitialized.
        try {
          await GoogleSignIn.instance.initialize(
            serverClientId:
                '66639149544-53t28igfqu0ll8ts5a4na0t49kvlr88f.apps.googleusercontent.com',
          );
          AppLogger.d('GoogleSignIn initialized at tap');
        } catch (e) {
          AppLogger.d('GoogleSignIn tap re-init ignored: $e');
        }

        AppLogger.i('Google sign-in: native authenticate() — in-app sheet');
        final googleUser = await GoogleSignIn.instance.authenticate();
        AppLogger.i('Native account email=${googleUser.email} id=${googleUser.id}');
        final googleAuth = googleUser.authentication;
        idToken = googleAuth.idToken;
        AppLogger.d('Native idToken len=${idToken?.length ?? 0}');

        if (idToken != null && idToken.isNotEmpty) {
          AppLogger.d('Firebase signInWithCredential ...');
          final credential = GoogleAuthProvider.credential(idToken: idToken);
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          final refreshed = await userCredential.user?.getIdToken();
          AppLogger.i('Firebase OK uid=${userCredential.user?.uid} refreshed=${refreshed != null}');
          idToken = refreshed ?? idToken;
        }
      }

      if (idToken == null || idToken.isEmpty) {
        AppLogger.e('Google sign-in: no idToken obtained');
        throw Exception('Could not obtain ID token from Google');
      }

      AppLogger.i('Exchanging Firebase idToken -> Sanctum ...');
      final res = await _repo.loginWithFirebase(
        idToken: idToken,
        accountType: accountType,
      );
      AppLogger.i('Sanctum success user=${res.user.id} email=${res.user.email}');
      emit(AuthAuthenticated(res.user));
      return true;
    } on GoogleSignInException catch (e, st) {
      AppLogger.e('GoogleSignInException code=${e.code} desc=${e.description}', e, st);
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        AppLogger.i('Google sign-in cancelled/dismissed -> idle (spinner off)');
        emit(const AuthUnauthenticated());
        return false;
      }
      final lower = (e.description ?? '').toLowerCase();
      if (lower.contains('channel-error') ||
          lower.contains('getgoogleservicesjsonserverclientid')) {
        AppLogger.e('Pigeon channel-error: stale binding. Fix: flutter clean, uninstall app, flutter run. No Chrome involved.', e, st);
        emit(const AuthError(
            'Google Sign-In not ready. Run: flutter clean, uninstall the app from the device, then flutter run.'));
        return false;
      }
      emit(AuthError(e.description ?? 'Google sign-in failed'));
      return false;
    } on FirebaseAuthException catch (e, st) {
      AppLogger.e('FirebaseAuthException code=${e.code} msg=${e.message}', e, st);
      if (e.code == 'user-cancelled' ||
          e.code == 'canceled' ||
          e.code == 'web-context-cancelled' ||
          e.code == 'popup-closed-by-user') {
        AppLogger.i('Firebase sign-in cancelled -> idle');
        emit(const AuthUnauthenticated());
        return false;
      }
      emit(AuthError(e.message ?? 'Google sign-in failed'));
      return false;
    } on MissingPluginException catch (e, st) {
      AppLogger.e('MissingPluginException — hot-restart stale channel (popup never opened)', e, st);
      emit(const AuthError(
          'Google Sign-In not ready (hot-restart). Stop and run again — do not hot-restart.'));
      return false;
    } on PlatformException catch (e, st) {
      // The Pigeon channel-error surfaces as PlatformException(channel-error, ...)
      AppLogger.e('PlatformException code=${e.code} msg=${e.message}', e, st);
      final msg = '${e.code} ${e.message}'.toLowerCase();
      if (msg.contains('channel-error') ||
          msg.contains('getgoogleservicesjsonserverclientid')) {
        AppLogger.e('Pigeon channel-error on PlatformException — stale binding', e, st);
        emit(const AuthError(
            'Google Sign-In not ready. Run: flutter clean, uninstall the app from the device, then flutter run.'));
        return false;
      }
      if (msg.contains('cancel')) {
        emit(const AuthUnauthenticated());
        return false;
      }
      emit(AuthError(e.message ?? 'Google sign-in failed'));
      return false;
    } catch (e, st) {
      AppLogger.e('Google sign-in unexpected error', e, st);
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('channel-error') ||
          errStr.contains('getgoogleservicesjsonserverclientid')) {
        emit(const AuthError(
            'Google Sign-In not ready. Run: flutter clean, uninstall app, then flutter run.'));
        return false;
      }
      if (errStr.contains('cancel') ||
          errStr.contains('sign_in_canceled') ||
          errStr.contains('popup-closed')) {
        AppLogger.i('Google sign-in cancelled (catch-all) -> idle');
        emit(const AuthUnauthenticated());
        return false;
      }
      final friendly = _extractMessage(e);
      emit(AuthError(friendly ?? 'Google sign-in failed'));
      return false;
    }
  }

  /// For mobile native Google flow: caller provides idToken directly
  Future<void> loginWithIdToken({required String idToken, String? accountType}) async {
    emit(const AuthLoading(AuthLoadingType.google));
    AppLogger.i('loginWithIdToken called');
    try {
      final res = await _repo.loginWithFirebase(idToken: idToken, accountType: accountType);
      AppLogger.i('loginWithIdToken success user=${res.user.id}');
      emit(AuthAuthenticated(res.user));
    } catch (e, st) {
      AppLogger.e('loginWithIdToken failed', e, st);
      emit(AuthError(_extractMessage(e) ?? 'Google sign-in failed'));
    }
  }

  Future<void> logout() async {
    AppLogger.i('Logout requested');
    try {
      await _repo.logout();
      AppLogger.i('Logout: server clear done, signing out Firebase/Google');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        AppLogger.w('Firebase signOut ignored: $e');
      }
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
          AppLogger.d('GoogleSignIn signOut done');
        } catch (e) {
          AppLogger.w('GoogleSignIn signOut ignored: $e');
        }
      }
    } catch (e, st) {
      AppLogger.e('Logout error', e, st);
    } finally {
      emit(const AuthUnauthenticated());
      AppLogger.i('Logout -> AuthUnauthenticated');
    }
  }
}
