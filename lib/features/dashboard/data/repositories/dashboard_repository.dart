import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final Dio _dio;
  static final Map<String, DashboardModel> _cache = {};

  DashboardRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  static void clearCache() => _cache.clear();

  DashboardModel? getCached({int? messId}) => _cache['${messId ?? 0}'];

  Future<DashboardModel> fetchDashboard({
    int? messId,
    bool forceRefresh = false,
  }) async {
    final key = '${messId ?? 0}';
    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key]!;
    }
    try {
      final response = await _dio.get(
        ApiEndpoints.dashboard,
        queryParameters: messId != null ? {'mess_id': messId} : null,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        final model = DashboardModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        _cache[key] = model;
        return model;
      }
      throw Exception('Invalid dashboard API payload');
    } catch (e) {
      if (_cache.containsKey(key)) {
        return _cache[key]!;
      }
      AppLogger.w('DashboardRepository.fetchDashboard failed: $e');
      rethrow;
    }
  }
}
