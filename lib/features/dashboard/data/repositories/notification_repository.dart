import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<Map<String, dynamic>> fetchNotifications({
    String type = 'all',
    int page = 1,
    int? messId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': 25,
    };
    if (type != 'all') {
      queryParams['type'] = type;
    }
    if (messId != null) {
      queryParams['mess_id'] = messId;
    }

    final response = await _dio.get(
      '/api/v1/notifications',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final list = (data['items'] as List<dynamic>?) ?? [];
      final items = list
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
      return {
        'items': items,
        'unread_count': unreadCount,
      };
    }
    throw Exception('Failed to load notifications');
  }

  Future<int> fetchUnreadCount() async {
    final response = await _dio.get('/api/v1/notifications/unread-count');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['unread_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<bool> markAsRead(int notificationId) async {
    final response = await _dio.post('/api/v1/notifications/$notificationId/read');
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> markAllAsRead() async {
    final response = await _dio.post('/api/v1/notifications/read-all');
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> handleAction(int notificationId, String action) async {
    final response = await _dio.post(
      '/api/v1/notifications/$notificationId/action',
      data: {'action': action},
    );
    return response.statusCode == 200 && response.data['success'] == true;
  }
}
