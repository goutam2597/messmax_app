import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<DashboardModel> fetchDashboard({int? messId}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.dashboard,
        queryParameters: messId != null ? {'mess_id': messId} : null,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return DashboardModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid dashboard API payload');
    } catch (e) {
      AppLogger.w('DashboardRepository.fetchDashboard failed: $e');
      rethrow;
    }
  }
}
