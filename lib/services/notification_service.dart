import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/medication.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(initializationSettings);
  }

  static Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<void> scheduleMedicationReminder(Medication medication) async {
    if (!medication.isActive) return;

    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final hour = medication.reminderTimes[i];
      final notificationId =
          medication.id * 100 + i; // Unique ID for each reminder

      // Calculate next occurrence of this time
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour);

      // If the time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            channelDescription: 'Reminders to take your medications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        'Medication Reminder',
        'Time to take ${medication.name} (${medication.dosage})',
        details,
      );
    }
  }

  static Future<void> cancelMedicationReminders(int medicationId) async {
    // Cancel all reminders for this medication
    for (int i = 0; i < 10; i++) {
      // Assuming max 10 reminders per medication
      final notificationId = medicationId * 100 + i;
      await _notifications.cancel(notificationId);
    }
  }

  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Immediate notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
