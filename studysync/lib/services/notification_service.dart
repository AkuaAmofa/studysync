import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studysync/core/constants/app_constants.dart';

// Top-level handler required by FCM for background/terminated messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService._showLocalNotification(
    title: message.notification?.title ?? 'StudySync',
    body: message.notification?.body ?? '',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'studysync_channel',
    'StudySync',
    description: 'StudySync group notifications',
    importance: Importance.high,
  );

  /// Call once from main() before runApp.
  static Future<void> init() async {
    // 1 — Local notifications plugin setup.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 2 — FCM background handler (must be registered before any other FCM call).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3 — Request notification permission (Android 13+, iOS).
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 4 — Fetch device token and persist it to the backend.
    final token = await messaging.getToken();
    if (token != null) await _saveFcmTokenToBackend(token);

    // Refresh token when it rotates.
    messaging.onTokenRefresh.listen(_saveFcmTokenToBackend);

    // 5 — Foreground messages → show local notification.
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'StudySync',
        body: message.notification?.body ?? '',
      );
    });
  }

  static Future<void> _saveFcmTokenToBackend(String token) async {
    try {
      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'token');
      if (jwt == null) return;
      await Dio().patch(
        '${AppConstants.apiBaseUrl}/auth/fcm-token',
        data: {'fcm_token': token},
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );
    } catch (_) {
      // Best-effort; fails silently if user is not yet logged in.
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      title.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Show an immediate local notification (callable externally if needed).
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) =>
      _showLocalNotification(title: title, body: body, payload: payload);
}
