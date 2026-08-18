import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/home_data_model.dart';

class HomeRepository {
  final Dio _dioClient;
  static HomeDataModel? _cache;

  HomeRepository({Dio? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  static HomeDataModel? getCached() => _cache;

  static void clearCache() {
    _cache = null;
  }

  Future<HomeDataModel> getHomeData({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }
    try {
      final response = await _dioClient.get(ApiEndpoints.home);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final homeData = HomeDataModel.fromJson(data);
      _cache = homeData;
      return homeData;
    } catch (e, stack) {
      AppLogger.e('HomeRepository: failed to fetch home data', e, stack);
      if (_cache != null && !forceRefresh) {
        return _cache!;
      }
      rethrow;
    }
  }
}
