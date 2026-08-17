import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ad_model.dart';

class UserAdRepository {
  final Dio _dio;

  UserAdRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<List<AdModel>> fetchMyAds() async {
    try {
      final response = await _dio.get('${ApiEndpoints.ads}/../user/ads');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final list = data?['ads'] as List<dynamic>? ?? [];
        return list.map((e) => AdModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Invalid user ads payload');
    } catch (e) {
      AppLogger.w('UserAdRepository.fetchMyAds failed: $e');
      rethrow;
    }
  }

  Future<AdModel> fetchAdForEdit(int id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.ads}/../user/ads/$id');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final adJson = data?['ad'] as Map<String, dynamic>?;
        if (adJson != null) return AdModel.fromJson(adJson);
      }
      throw Exception('Ad not found');
    } catch (e) {
      AppLogger.w('UserAdRepository.fetchAdForEdit failed: $e');
      rethrow;
    }
  }

  Future<AdModel> saveAd({
    int? id,
    required String title,
    required double rentPerSeat,
    double? rentTotal,
    required int seatsAvailable,
    int? roomCapacity,
    required String roomType,
    String? city,
    String? area,
    String? location,
    String? description,
    String? contactPhone,
    String? contactWhatsapp,
    bool hideAddress = false,
    List<String>? amenities,
    List<String>? newImagePaths,
    List<int>? removeImageIds,
  }) async {
    try {
      final map = <String, dynamic>{
        'title': title,
        'rent_per_seat': rentPerSeat,
        'rent_total':? rentTotal,
        'seats_available': seatsAvailable,
        'room_capacity':? roomCapacity,
        'room_type': roomType,
        'city': city ?? 'Dhaka',
        'area':? area,
        'location':? location,
        'hide_address': hideAddress ? 1 : 0,
        'description':? description,
        'contact_phone':? contactPhone,
        'contact_whatsapp':? contactWhatsapp,
      };

      if (amenities != null && amenities.isNotEmpty) {
        for (var i = 0; i < amenities.length; i++) {
          map['amenities[$i]'] = amenities[i];
        }
      }

      if (removeImageIds != null && removeImageIds.isNotEmpty) {
        for (var i = 0; i < removeImageIds.length; i++) {
          map['remove_image_ids[$i]'] = removeImageIds[i];
        }
      }

      if (newImagePaths != null && newImagePaths.isNotEmpty) {
        final files = <MultipartFile>[];
        for (final path in newImagePaths) {
          files.add(await MultipartFile.fromFile(path, filename: path.split('/').last));
        }
        map['images[]'] = files;
      }

      final formData = FormData.fromMap(map);
      final url = id != null
          ? '${ApiEndpoints.ads}/../user/ads/$id'
          : '${ApiEndpoints.ads}/../user/ads';

      final response = await _dio.post(url, data: formData);

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final adJson = data?['ad'] as Map<String, dynamic>?;
        if (adJson != null) return AdModel.fromJson(adJson);
      }
      throw Exception('Failed to save ad');
    } catch (e) {
      AppLogger.w('UserAdRepository.saveAd failed: $e');
      rethrow;
    }
  }

  Future<void> deleteAd(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.ads}/../user/ads/$id');
      if (response.statusCode == 200 || response.data?['success'] == true) {
        return;
      }
      throw Exception('Delete failed');
    } catch (e) {
      AppLogger.w('UserAdRepository.deleteAd failed: $e');
      rethrow;
    }
  }
}
