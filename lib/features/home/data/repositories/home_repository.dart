import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/home_data_model.dart';

class HomeRepository {
  final Dio _dioClient;

  HomeRepository({Dio? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  Future<HomeDataModel> getHomeData() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.home);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return HomeDataModel.fromJson(data);
    } catch (e, stack) {
      AppLogger.e('HomeRepository: failed to fetch home data', e, stack);
      rethrow;
    }
  }
}
