import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/member_model.dart';

class MemberRepository {
  final Dio _dio;
  static final Map<String, MemberResponseModel> _cache = {};

  MemberRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  static void clearCache() => _cache.clear();

  MemberResponseModel? getCached({int? messId}) => _cache['${messId ?? 0}'];

  Future<MemberResponseModel> fetchMembers({
    int? messId,
    bool forceRefresh = false,
  }) async {
    final key = '${messId ?? 0}';
    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key]!;
    }
    try {
      final response = await _dio.get(
        ApiEndpoints.members,
        queryParameters: messId != null ? {'mess_id': messId} : null,
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final model = MemberResponseModel.fromJson(data);
        _cache[key] = model;
        return model;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load members');
      }
    } on DioException catch (e) {
      if (_cache.containsKey(key)) return _cache[key]!;
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception(msg);
    }
  }

  Future<MemberModel> saveMember({
    int? id,
    required Map<String, dynamic> data,
    String? avatarPath,
  }) async {
    try {
      final map = Map<String, dynamic>.from(data);
      if (avatarPath != null && avatarPath.isNotEmpty) {
        map['avatar'] = await MultipartFile.fromFile(
          avatarPath,
          filename: avatarPath.split('/').last,
        );
      }

      final formData = FormData.fromMap(map);
      final url = id != null
          ? '${ApiEndpoints.members}/$id'
          : ApiEndpoints.members;

      final response = await _dio.post(url, data: formData);

      if (response.data is Map && response.data['success'] == true) {
        final memberJson = response.data['data'] as Map<String, dynamic>;
        return MemberModel.fromJson(memberJson);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save member');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception(msg);
    }
  }

  Future<void> deleteMember(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.members}/$id');
      if (response.data is Map && response.data['success'] == true) {
        return;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete member');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      throw Exception(msg);
    }
  }
}
