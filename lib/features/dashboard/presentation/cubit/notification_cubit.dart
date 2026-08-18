import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription<RemoteMessage>? _fcmSub;

  NotificationCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(NotificationInitial()) {
    // Auto-refresh list whenever a foreground FCM message arrives
    _fcmSub = PushNotificationService.onForegroundMessage.listen((_) {
      loadNotifications(
        filter: state is NotificationLoaded
            ? (state as NotificationLoaded).activeFilter
            : 'all',
        silent: true,
      );
    });
  }

  @override
  Future<void> close() {
    _fcmSub?.cancel();
    return super.close();
  }

  Future<void> loadNotifications({
    String filter = 'all',
    bool silent = false,
  }) async {
    if (!silent) {
      if (state is! NotificationLoaded) {
        emit(NotificationLoading());
      } else {
        emit((state as NotificationLoaded)
            .copyWith(isRefreshing: true, activeFilter: filter));
      }
    }

    try {
      final res = await _repository.fetchNotifications(type: filter);
      emit(NotificationLoaded(
        notifications: res['items'],
        unreadCount: res['unread_count'],
        activeFilter: filter,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> changeFilter(String filter) async {
    await loadNotifications(filter: filter);
  }

  Future<void> markAsRead(int notificationId) async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;

    final updated = current.notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();

    final newUnread = (current.unreadCount - 1).clamp(0, 999);
    emit(current.copyWith(notifications: updated, unreadCount: newUnread));

    try {
      await _repository.markAsRead(notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;

    final updated =
        current.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(current.copyWith(notifications: updated, unreadCount: 0));

    try {
      await _repository.markAllAsRead();
    } catch (_) {}
  }

  Future<bool> handleAction(int notificationId, String action) async {
    try {
      final ok = await _repository.handleAction(notificationId, action);
      if (ok) {
        await loadNotifications(
          filter: state is NotificationLoaded
              ? (state as NotificationLoaded).activeFilter
              : 'all',
          silent: true,
        );
      }
      return ok;
    } catch (e) {
      return false;
    }
  }
}
