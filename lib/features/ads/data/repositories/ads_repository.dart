import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ad_model.dart';
import '../models/ads_response_model.dart';

class AdsRepository {
  final Dio _dioClient;
  static AdsResponseModel? _defaultAdsCache;
  static final Map<String, ({AdModel ad, List<AdModel> relatedAds})> _detailCache = {};

  AdsRepository({Dio? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  static AdsResponseModel? getDefaultCached() => _defaultAdsCache;

  static void clearCache() {
    _defaultAdsCache = null;
    _detailCache.clear();
  }

  Future<AdsResponseModel> getAds({
    String? search,
    String? city,
    String? area,
    String? roomType,
    int page = 1,
    int perPage = 12,
    bool forceRefresh = false,
  }) async {
    final isDefault = page == 1 &&
        (search == null || search.trim().isEmpty) &&
        (city == null || city.trim().isEmpty) &&
        (area == null || area.trim().isEmpty) &&
        (roomType == null || roomType.trim().isEmpty);

    if (isDefault && !forceRefresh && _defaultAdsCache != null) {
      return _defaultAdsCache!;
    }

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
      final result = AdsResponseModel.fromJson(data);
      if (isDefault) {
        _defaultAdsCache = result;
      }
      return result;
    } catch (e, stack) {
      AppLogger.e('AdsRepository: failed to fetch ads', e, stack);
      if (isDefault && _defaultAdsCache != null && !forceRefresh) {
        return _defaultAdsCache!;
      }
      rethrow;
    }
  }

  static ({AdModel ad, List<AdModel> relatedAds})? getDetailCached(String slug) =>
      _detailCache[slug];

  Future<({AdModel ad, List<AdModel> relatedAds})> getAdDetail(
    String slug, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _detailCache.containsKey(slug)) {
      return _detailCache[slug]!;
    }
    try {
      final response = await _dioClient.get('${ApiEndpoints.ads}/$slug');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final adJson = data['ad'] as Map<String, dynamic>;
      final relatedJson = (data['related_ads'] as List<dynamic>?)
              ?.map((e) => AdModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AdModel>[];
      final result = (
        ad: AdModel.fromJson(adJson),
        relatedAds: relatedJson,
      );
      _detailCache[slug] = result;
      return result;
    } catch (e, stack) {
      AppLogger.e('AdsRepository: failed to fetch ad detail for slug: $slug', e, stack);
      if (_detailCache.containsKey(slug) && !forceRefresh) {
        return _detailCache[slug]!;
      }
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
