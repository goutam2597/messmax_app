import 'package:dio/dio.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/bazar_schedule_model.dart';

class BazarScheduleRepository {
  final Dio _dio;

  BazarScheduleRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<BazarScheduleResponseModel> fetchSchedule({
    int? messId,
    int? year,
    int? month,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (messId != null) query['mess_id'] = messId;
      if (year != null) query['year'] = year;
      if (month != null) query['month'] = month;

      final response = await _dio.get(
        '${ApiEndpoints.ads}/../bazar-schedule',
        queryParameters: query,
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        return BazarScheduleResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Invalid bazar schedule payload');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.fetchSchedule failed: $e');
      rethrow;
    }
  }

  Future<String> assignSchedule({
    required int messId,
    required int year,
    required int month,
    int? fromDay,
    int? toDay,
    List<int>? days,
    int? messMemberId,
    String? staffName,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'mess_id': messId,
        'year': year,
        'month': month,
        'from_day':? fromDay,
        'to_day':? toDay,
        if (days != null && days.isNotEmpty) 'days': days,
        'mess_member_id':? messMemberId,
        if (staffName != null && staffName.isNotEmpty) 'staff_name': staffName,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _dio.post(
        '${ApiEndpoints.ads}/../bazar-schedule/assign',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['message'] as String? ?? 'Assignment saved';
      }
      throw Exception(response.data?['message'] ?? 'Failed to save assignment');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.assignSchedule failed: $e');
      rethrow;
    }
  }

  Future<String> notifyAssignee({
    required int messId,
    required int year,
    required int month,
    required int day,
    String? notes,
    String? emailOverride,
  }) async {
    try {
      final payload = <String, dynamic>{
        'mess_id': messId,
        'year': year,
        'month': month,
        'day': day,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (emailOverride != null && emailOverride.isNotEmpty)
          'email_override': emailOverride,
      };

      final response = await _dio.post(
        '${ApiEndpoints.ads}/../bazar-schedule/notify',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['message'] as String? ?? 'Notification email sent';
      }
      throw Exception(response.data?['message'] ?? 'Notification email failed');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.notifyAssignee failed: $e');
      rethrow;
    }
  }

  Future<String> notifyBulk({
    required int messId,
    required int year,
    required int month,
    int? fromDay,
    int? toDay,
    List<int>? days,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'mess_id': messId,
        'year': year,
        'month': month,
        'from_day':? fromDay,
        'to_day':? toDay,
        if (days != null && days.isNotEmpty) 'days': days,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _dio.post(
        '${ApiEndpoints.ads}/../bazar-schedule/notify-bulk',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['message'] as String? ?? 'Notifications sent';
      }
      throw Exception(response.data?['message'] ?? 'Bulk notifications failed');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.notifyBulk failed: $e');
      rethrow;
    }
  }

  Future<String> broadcastAnnouncement({
    required int messId,
    required int year,
    required int month,
    String? subject,
    required String message,
  }) async {
    try {
      final payload = <String, dynamic>{
        'mess_id': messId,
        'year': year,
        'month': month,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'message': message,
      };

      final response = await _dio.post(
        '${ApiEndpoints.ads}/../bazar-schedule/announce',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['message'] as String? ?? 'Announcement sent';
      }
      throw Exception(response.data?['message'] ?? 'Announcement broadcast failed');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.broadcastAnnouncement failed: $e');
      rethrow;
    }
  }

  Future<void> deleteAssignment(int id) async {
    try {
      final response = await _dio.delete(
        '${ApiEndpoints.ads}/../bazar-schedule/$id',
      );

      if (response.data != null && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data?['message'] ?? 'Failed to delete assignment');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.deleteAssignment failed: $e');
      rethrow;
    }
  }

  Future<void> clearMonth({
    required int messId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.delete(
        '${ApiEndpoints.ads}/../bazar-schedule/clear-month',
        data: {
          'mess_id': messId,
          'year': year,
          'month': month,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data?['message'] ?? 'Failed to clear month');
    } catch (e) {
      AppLogger.w('BazarScheduleRepository.clearMonth failed: $e');
      rethrow;
    }
  }
}
