import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages Firebase Cloud Messaging and local notifications.
/// TODO: Wire up FCM token registration with the backend at /api/notifications/register.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call once from main() before runApp.
  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // TODO: Request FCM permission and obtain token
    // TODO: Subscribe to group-specific FCM topics on join/leave
  }

  /// Shows an immediate local notification.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'studysync_channel',
      'StudySync',
      channelDescription: 'StudySync group notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, title, body, notificationDetails,
        payload: payload);
  }
}
