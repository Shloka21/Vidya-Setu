import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Create notification channels
    const studyChannel = AndroidNotificationChannel(
      'study_reminders',
      'Study Reminders',
      description: 'Notifications for upcoming study sessions',
      importance: Importance.high,
      playSound: true,
    );

    const alarmChannel = AndroidNotificationChannel(
      'alarm_reminders',
      'Alarm Reminders',
      description: 'Alarm-style notifications for exams and important events',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(studyChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);

    // Request notification permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Schedule study session notification (15 min before)
  Future<void> scheduleStudyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final notifTime = scheduledTime.subtract(const Duration(minutes: 15));
    if (notifTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '📚 $title',
      body,
      tz.TZDateTime.from(notifTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders',
          'Study Reminders',
          channelDescription: 'Notifications for upcoming study sessions',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule reminder alarm with "remind before" intervals
  Future<void> scheduleReminderAlarm({
    required String reminderId,
    required String title,
    required String body,
    required DateTime eventTime,
    required List<int> reminderMinutesBefore,
    required String repeatType,
  }) async {
    // Cancel existing for this reminder
    final baseId = reminderId.hashCode.abs() % 100000;

    for (int i = 0; i < reminderMinutesBefore.length; i++) {
      final notifTime = eventTime.subtract(Duration(minutes: reminderMinutesBefore[i]));
      if (notifTime.isBefore(DateTime.now())) continue;

      final label = _formatMinutesBefore(reminderMinutesBefore[i]);

      if (repeatType == 'once') {
        await _plugin.zonedSchedule(
          baseId + i,
          '⏰ $title',
          '$body ($label before)',
          tz.TZDateTime.from(notifTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'alarm_reminders',
              'Alarm Reminders',
              channelDescription: 'Alarm-style notifications',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              fullScreenIntent: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else if (repeatType == 'daily') {
        await _plugin.zonedSchedule(
          baseId + i,
          '⏰ $title',
          '$body ($label before)',
          tz.TZDateTime.from(notifTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'alarm_reminders',
              'Alarm Reminders',
              channelDescription: 'Alarm-style notifications',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else if (repeatType == 'weekly') {
        await _plugin.zonedSchedule(
          baseId + i,
          '⏰ $title',
          '$body ($label before)',
          tz.TZDateTime.from(notifTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'alarm_reminders',
              'Alarm Reminders',
              channelDescription: 'Alarm-style notifications',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelByReminderId(String reminderId, int count) async {
    final baseId = reminderId.hashCode.abs() % 100000;
    for (int i = 0; i < count; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _formatMinutesBefore(int minutes) {
    if (minutes >= 1440) return '${minutes ~/ 1440} day${minutes ~/ 1440 > 1 ? 's' : ''}';
    if (minutes >= 60) return '${minutes ~/ 60} hour${minutes ~/ 60 > 1 ? 's' : ''}';
    return '$minutes min';
  }
}
