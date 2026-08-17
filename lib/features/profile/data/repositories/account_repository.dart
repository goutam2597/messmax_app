import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/account_response_model.dart';
import '../../../auth/data/models/user_model.dart';

class AccountRepository {
  final Dio _dio;
  static AccountResponseModel? _cachedAccount;

  AccountRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  static void clearCache() {
    _cachedAccount = null;
  }

  Future<AccountResponseModel> fetchAccountDetails({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAccount != null) {
      return _cachedAccount!;
    }
    try {
      final response = await _dio.get(ApiEndpoints.account);
      if (response.data != null && response.data is Map<String, dynamic>) {
        _cachedAccount = AccountResponseModel.fromJson(response.data as Map<String, dynamic>);
        return _cachedAccount!;
      }
      throw Exception('Invalid account API payload');
    } catch (e) {
      AppLogger.w('AccountRepository.fetchAccountDetails failed: $e');
      if (_cachedAccount != null) return _cachedAccount!;
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    required String email,
    String? avatarFilePath,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'name': name,
        'email': email,
      };

      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        formDataMap['avatar'] = await MultipartFile.fromFile(
          avatarFilePath,
          filename: avatarFilePath.split('/').last,
        );
      }

      final formData = FormData.fromMap(formDataMap);
      final response = await _dio.post(ApiEndpoints.account, data: formData);

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final userJson = data?['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          clearCache(); // Force fresh fetch on next load
          return UserModel.fromJson(userJson);
        }
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      AppLogger.w('AccountRepository.updateProfile failed: $e');
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.accountPassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
      );
      if (response.statusCode == 200 || response.data?['success'] == true) {
        return;
      }
      throw Exception(response.data?['message'] ?? 'Password update failed');
    } catch (e) {
      AppLogger.w('AccountRepository.updatePassword failed: $e');
      rethrow;
    }
  }
}
