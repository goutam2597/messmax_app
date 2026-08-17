import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      // refresh cached user
      AuthStorage.setUserInMemory(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      AppLogger.w('AuthCubit.checkAuth failed — clearing: $e');
      await AuthStorage.clear();
      DioClient.clearAuthToken();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading(AuthLoadingType.email));
    try {
      final res = await _repo.login(email: email, password: password);
      emit(AuthAuthenticated(res.user));
    } catch (e) {
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
    try {
      final res = await _repo.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        accountType: accountType,
      );
      emit(AuthAuthenticated(res.user));
    } catch (e) {
      emit(AuthError(_extractMessage(e) ?? 'Registration failed'));
    }
  }

  /// Google sign-in: obtain Firebase idToken then exchange for Sanctum token.
  /// If accountType is null and user is new, backend defaults to 'individual'.
  Future<bool?> loginWithGoogle({String? accountType}) async {
    emit(const AuthLoading(AuthLoadingType.google));
    try {
      final auth = FirebaseAuth.instance;
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      UserCredential cred;
      try {
        cred = await auth.signInWithPopup(provider);
      } on UnimplementedError {
        cred = await auth.signInWithProvider(provider);
      }
      // For now this path matches web build; mobile will use GoogleSignIn native flow via same idToken exchange.
      final idToken = await cred.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) throw Exception('No ID token from Google');
      final res = await _repo.loginWithFirebase(idToken: idToken, accountType: accountType);
      emit(AuthAuthenticated(res.user));
      return true;
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Google sign-in failed'));
      return false;
    } catch (e) {
      emit(AuthError(_extractMessage(e) ?? 'Google sign-in failed'));
      return false;
    }
  }

  /// For mobile native Google flow: caller provides idToken directly
  Future<void> loginWithIdToken({required String idToken, String? accountType}) async {
    emit(const AuthLoading(AuthLoadingType.google));
    try {
      final res = await _repo.loginWithFirebase(idToken: idToken, accountType: accountType);
      emit(AuthAuthenticated(res.user));
    } catch (e) {
      emit(AuthError(_extractMessage(e) ?? 'Google sign-in failed'));
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } finally {
      emit(const AuthUnauthenticated());
    }
  }
}
