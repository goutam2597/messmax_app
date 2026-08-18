import 'package:equatable/equatable.dart';

class AppNotificationModel extends Equatable {
  final int id;
  final int? messId;
  final String? messName;
  final String type; // meal_off, guest_meal, deposit, bazar_duty, member_join, announcement, system
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final String timeAgo;

  const AppNotificationModel({
    required this.id,
    this.messId,
    this.messName,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.actionUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.timeAgo,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      messId: (json['mess_id'] as num?)?.toInt(),
      messName: json['mess_name'] as String?,
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      actionUrl: json['action_url'] as String?,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? '',
    );
  }

  AppNotificationModel copyWith({
    bool? isRead,
    String? readAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotificationModel(
      id: id,
      messId: messId,
      messName: messName,
      type: type,
      title: title,
      body: body,
      data: data ?? this.data,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      timeAgo: timeAgo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        messId,
        messName,
        type,
        title,
        body,
        data,
        actionUrl,
        isRead,
        readAt,
        createdAt,
        timeAgo,
      ];
}
