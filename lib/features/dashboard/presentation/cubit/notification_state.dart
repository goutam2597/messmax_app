import 'package:equatable/equatable.dart';
import '../../data/models/app_notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotificationModel> notifications;
  final int unreadCount;
  final String activeFilter;
  final bool isRefreshing;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.activeFilter = 'all',
    this.isRefreshing = false,
  });

  NotificationLoaded copyWith({
    List<AppNotificationModel>? notifications,
    int? unreadCount,
    String? activeFilter,
    bool? isRefreshing,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      activeFilter: activeFilter ?? this.activeFilter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        activeFilter,
        isRefreshing,
      ];
}

class NotificationError extends NotificationState {
  final String message;
  final String code;

  const NotificationError(this.message, {this.code = 'ERR-NET-0000'});

  @override
  List<Object?> get props => [message, code];
}
