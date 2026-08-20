import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../logger/app_logger.dart';
import '../network/dio_client.dart';

// ─── Background handler (must be top-level) ───────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('BG FCM: ${message.notification?.title}');
}

// ─── Service ──────────────────────────────────────────────────────────────────
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Android high-importance channels matching backend payload & default fallback
  /// Bump showBadge / enableVibration here would NOT affect already-created
  /// system channel — we force-recreate it on init (delete → create) to
  /// apply sound+vibration even if OS cached the channel as silent/muted.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'messmax_notifications',
    'MessMax Notifications',
    description: 'All MessMax push notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel _fallbackChannel =
      AndroidNotificationChannel(
        'messmax_high_importance',
        'MessMax High Importance',
        description: 'High priority MessMax notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

  // ── Public stream: broadcasts when a foreground FCM arrives ─────────────────
  // Listeners (e.g. NotificationCubit) subscribe to auto-refresh UI.
  static final Stream<RemoteMessage> onForegroundMessage =
      FirebaseMessaging.onMessage;

  // ── Initialize ──────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // ── Set up flutter_local_notifications ──────────────────────────────────
      if (!kIsWeb) {
        const initAndroid = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const initDarwin = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: initAndroid,
          iOS: initDarwin,
        );
        await _localNotif.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse r) {
            AppLogger.i('Local notif tapped: ${r.payload}');
          },
        );

        final androidImplementation = _localNotif
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        // Create high-importance channels on Android (must exist before show())
        // Force recreate so system channel picks up sound/vibration even if it
        // was previously cached as silent. createNotificationChannel is no-op
        // if the channel already exists, so delete first ensures updated sound.
        await androidImplementation?.deleteNotificationChannel(
          channelId: _channel.id,
        );
        await androidImplementation?.deleteNotificationChannel(
          channelId: _fallbackChannel.id,
        );
        await androidImplementation?.createNotificationChannel(_channel);
        await androidImplementation?.createNotificationChannel(
          _fallbackChannel,
        );

        // iOS: set foreground presentation options
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // ── Foreground message → show local notification ─────────────────────────
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i(
          'FCM Foreground: ${message.notification?.title ?? message.data['title']} id=${message.messageId}',
        );
        _showLocalNotification(message);
      });

      // ── Token refresh ────────────────────────────────────────────────────────
      _fcm.onTokenRefresh.listen((newToken) {
        AppLogger.i('FCM Token refreshed');
        _sendTokenToBackend(newToken);
      });

      // ── App opened from background notification ──────────────────────────────
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.i('FCM opened app: ${message.data}');
      });

      // ── App opened from terminated state ────────────────────────────────────
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.i('FCM initial message: ${initialMessage.data}');
      }
    } catch (e, st) {
      AppLogger.e('PushNotificationService init failed: $e', e, st);
    }
  }

  // ── Show local notification banner (foreground FCM → heads-up) ─────────────
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title'] ??
        message.data['subject'] ??
        'MessMax';
    final body =
        notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        '';

    if (title.isEmpty && body.isEmpty) {
      AppLogger.w('Local notif skipped: empty title/body data=${message.data}');
      return;
    }

    // Android 13+ needs POST_NOTIFICATIONS — check explicitly before show()
    if (Platform.isAndroid) {
      final androidImpl = _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidImpl?.areNotificationsEnabled() ?? true;
      if (granted == false) {
        AppLogger.w(
          'Local notif not shown: POST_NOTIFICATIONS denied (title=$title). User must allow notifications in system settings.',
        );
        return;
      }
    }

    try {
      // Foreground heads-up must vibrate + sound even if user had muted channel
      // (channel importance already Max; these ensure heads-up peek).
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      await _localNotif.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        payload: message.data['notification_id']?.toString(),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.message,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      AppLogger.i('Local notif shown: $title — $body');
    } catch (e, st) {
      AppLogger.e('Local notif show failed: $e', e, st);
    }
  }

  /// One-tap local test — bypasses FCM, proves plugin/channel/sound end-to-end.
  static Future<bool> showTestNotification() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final imp = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      final enabled = await imp?.areNotificationsEnabled() ?? true;
      if (enabled == false) {
        final granted = await imp?.requestNotificationsPermission() ?? false;
        if (granted != true) {
          AppLogger.w('Test notif: POST_NOTIFICATIONS still denied after request');
          return false;
        }
      }
    }
    try {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
      await _localNotif.show(
        id: 99999,
        title: 'MessMax test',
        body: 'Local notifications are working — sound + vibration OK',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.message,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      AppLogger.i('Test local notif shown');
      return true;
    } catch (e, st) {
      AppLogger.e('Test local notif failed: $e', e, st);
      return false;
    }
  }

  // ── Permission + token sync (called after splash) ───────────────────────────
  static Future<void> requestPermissionAndSync() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.i('Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await syncDeviceToken();
      }
    } catch (e) {
      AppLogger.w('Permission request failed: $e');
    }
  }

  // ── Sync FCM token to backend ────────────────────────────────────────────────
  static Future<void> syncDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        AppLogger.i('FCM token retrieved');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      AppLogger.w('Could not get FCM token: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final deviceType = kIsWeb
          ? 'web'
          : Platform.isIOS
          ? 'ios'
          : 'android';
      final res = await DioClient.instance.post(
        '/v1/notifications/device-token',
        data: {'token': token, 'device_type': deviceType},
      );
      if (res.statusCode == 200) {
        AppLogger.i('FCM token registered with backend');
      }
    } catch (e) {
      AppLogger.w('FCM token registration deferred: $e');
    }
  }

  // ── Unregister token on logout ───────────────────────────────────────────────
  static Future<void> unregisterDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await DioClient.instance.delete(
          '/v1/notifications/device-token',
          data: {'token': token},
        );
        AppLogger.i('FCM device token unregistered');
      }
    } catch (e) {
      AppLogger.w('Failed to unregister FCM token: $e');
    }
  }
}
