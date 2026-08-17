import 'package:dio/dio.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String accountType, // hostel_owner | individual
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.authRegister,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'account_type': accountType,
        },
      );
      final body = res.data as Map<String, dynamic>;
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw _asDioException(res, body);
      }
      final ar = AuthResponse.fromJson(body);
      await AuthStorage.saveAuth(token: ar.token, user: ar.user);
      DioClient.setAuthToken(ar.token);
      return ar;
    } catch (e, st) {
      AppLogger.e('AuthRepository.register failed', e, st);
      rethrow;
    }
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.authLogin,
        data: {'email': email, 'password': password},
      );
      final body = res.data as Map<String, dynamic>;
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw _asDioException(res, body);
      }
      final ar = AuthResponse.fromJson(body);
      await AuthStorage.saveAuth(token: ar.token, user: ar.user);
      DioClient.setAuthToken(ar.token);
      return ar;
    } catch (e, st) {
      AppLogger.e('AuthRepository.login failed', e, st);
      rethrow;
    }
  }

  Future<AuthResponse> loginWithFirebase({
    required String idToken,
    String? accountType,
  }) async {
    try {
      final data = <String, dynamic>{'idToken': idToken};
      if (accountType != null) data['account_type'] = accountType;
      final res = await _dio.post(ApiEndpoints.authFirebase, data: data);
      final body = res.data as Map<String, dynamic>;
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw _asDioException(res, body);
      }
      final ar = AuthResponse.fromJson(body);
      await AuthStorage.saveAuth(token: ar.token, user: ar.user);
      DioClient.setAuthToken(ar.token);
      return ar;
    } catch (e, st) {
      AppLogger.e('AuthRepository.loginWithFirebase failed', e, st);
      rethrow;
    }
  }

  Future<UserModel> fetchMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    final body = res.data as Map<String, dynamic>;
    if (res.statusCode == 401 || (body['success'] == false && res.statusCode == 401)) {
      throw DioException(requestOptions: res.requestOptions, response: res, type: DioExceptionType.badResponse);
    }
    if (body['success'] == false) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: body['message'],
      );
    }
    final data = body['data'] as Map<String, dynamic>;
    // API returns {user, messes_count, ...} — unwrap
    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userMap);
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.authLogout);
    } catch (_) {
      // ignore server error — still clear local
    }
    await AuthStorage.clear();
    DioClient.clearAuthToken();
  }

  DioException _asDioException(Response res, Map<String, dynamic> body) {
    final msg = (body['message'] as String?) ??
        (body['errors'] != null ? (body['errors'] as Map).values.expand((v) => (v as List)).join(' ') : null) ??
        'Request failed';
    return DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      error: msg,
    );
  }
}
