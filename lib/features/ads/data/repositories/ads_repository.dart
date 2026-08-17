import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ad_model.dart';
import '../models/ads_response_model.dart';

class AdsRepository {
  final Dio _dioClient;

  AdsRepository({Dio? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  Future<AdsResponseModel> getAds({
    String? search,
    String? city,
    String? area,
    String? roomType,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['q'] = search.trim();
      }
      if (city != null && city.trim().isNotEmpty) {
        queryParams['city'] = city.trim();
      }
      if (area != null && area.trim().isNotEmpty) {
        queryParams['area'] = area.trim();
      }
      if (roomType != null && roomType.trim().isNotEmpty) {
        queryParams['room_type'] = roomType.trim();
      }

      final response = await _dioClient.get(
        ApiEndpoints.ads,
        queryParameters: queryParams,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return AdsResponseModel.fromJson(data);
    } catch (e, stack) {
      AppLogger.e('AdsRepository: failed to fetch ads', e, stack);
      rethrow;
    }
  }

  Future<({AdModel ad, List<AdModel> relatedAds})> getAdDetail(String slug) async {
    try {
      final response = await _dioClient.get('${ApiEndpoints.ads}/$slug');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final adJson = data['ad'] as Map<String, dynamic>;
      final relatedJson = (data['related_ads'] as List<dynamic>?)
              ?.map((e) => AdModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AdModel>[];
      return (
        ad: AdModel.fromJson(adJson),
        relatedAds: relatedJson,
      );
    } catch (e, stack) {
      AppLogger.e('AdsRepository: failed to fetch ad detail for slug: $slug', e, stack);
      rethrow;
    }
  }

  /// Searchable + paginated list of cities for the filter dropdown.
  Future<({List<String> items, bool hasMore})> fetchCities({
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['q'] = search.trim();
      }
      final response = await _dioClient.get(
        ApiEndpoints.cities,
        queryParameters: queryParams,
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final pagination =
          data['pagination'] as Map<String, dynamic>? ?? const {};
      final items = (data['cities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      return (
        items: items,
        hasMore: pagination['has_more'] as bool? ?? false,
      );
    } catch (e, stack) {
      AppLogger.e('AdsRepository: failed to fetch cities', e, stack);
      rethrow;
    }
  }

  /// Searchable + paginated list of areas for the filter dropdown.
  /// Pass a city to scope areas under that city; omit for all areas.
  Future<({List<String> items, bool hasMore})> fetchAreas({
    String? city,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (city != null && city.trim().isNotEmpty) {
        queryParams['city'] = city.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['q'] = search.trim();
      }
      final response = await _dioClient.get(
        ApiEndpoints.areas,
        queryParameters: queryParams,
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final pagination =
          data['pagination'] as Map<String, dynamic>? ?? const {};
      final items = (data['areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      return (
        items: items,
        hasMore: pagination['has_more'] as bool? ?? false,
      );
    } catch (e, stack) {
      AppLogger.e('AdsRepository: failed to fetch areas', e, stack);
      rethrow;
    }
  }
}
