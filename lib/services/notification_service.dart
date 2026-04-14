import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../app/routes.dart';
import '../app/theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    // Initialize TTS
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      initialResponse = details?.notificationResponse;
    }

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
      description: 'Alarm-style full-screen notifications for exams and important events',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const callChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Incoming video call alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'New message notifications from mentors and students',
      importance: Importance.high,
      playSound: true,
    );

    const feedbackChannel = AndroidNotificationChannel(
      'mentor_feedback',
      'Mentor Feedback',
      description: 'Notifications when your mentor sends feedback',
      importance: Importance.high,
      playSound: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(studyChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(callChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(feedbackChannel);

    // Request notification permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();
    
    // Exact alarms are required for reliable reminders on a schedule
    try {
      final hasExactPerm = await androidPlugin?.canScheduleExactNotifications() ?? false;
      if (!hasExactPerm) {
        await androidPlugin?.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }

    _initialized = true;
  }

  // ─── Notification Tap Handler ─────────────────────────────────────
  NotificationResponse? initialResponse;

  void _onNotificationTap(NotificationResponse response, {bool launchedFromColdStart = false, BuildContext? overrideContext}) {
    final navContext = overrideContext ?? _navigatorKey?.currentState?.context;
    if (response.payload == null || navContext == null) return;
    final navigator = Navigator.of(navContext);

    try {
      final data = jsonDecode(response.payload!);
      final type = data['type'] as String? ?? '';

      if (type == 'alarm' || type == 'reminder') {
        final args = {
          'title': data['title'] ?? 'Reminder',
          'description': data['description'] ?? '',
          'time': data['time'] ?? '',
          'priority': data['priority'] ?? 'high',
          'notificationId': data['notificationId'] ?? 0,
          'voice': data['voice'] ?? false,
          'launchedFromColdStart': launchedFromColdStart,
        };

        if (launchedFromColdStart) {
          navigator.pushReplacementNamed(AppRoutes.alarmScreen, arguments: args);
        } else {
          navigator.pushNamed(AppRoutes.alarmScreen, arguments: args);
        }
      } else if (type == 'chat') {
        final args = {
          'roomId': data['roomId'],
          'otherUserName': data['senderName'],
          'otherUserId': data['senderId'],
        };
        if (launchedFromColdStart) {
          navigator.pushReplacementNamed(AppRoutes.chatConversation, arguments: args);
        } else {
          navigator.pushNamed(AppRoutes.chatConversation, arguments: args);
        }
      } else if (type == 'feedback') {
        if (launchedFromColdStart) {
          navigator.pushReplacementNamed(AppRoutes.studentProfile);
        } else {
          navigator.pushNamed(AppRoutes.studentProfile);
        }
      }
    } catch (e) {
      debugPrint('Notification tap error: $e');
    }
  }

  void handleInitialNotification([BuildContext? context]) {
    if (initialResponse != null) {
      if (_navigatorKey?.currentState != null || context != null) {
        _onNotificationTap(initialResponse!, launchedFromColdStart: true, overrideContext: context);
        initialResponse = null;
      }
    }
  }

  // ─── Study Session Notification (15 min before) ───────────────────
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
      payload: jsonEncode({'type': 'study', 'title': title, 'description': body}),
    );
  }

  // ─── Bulk Study Plan Notifications ────────────────────────────────
  /// Schedule notifications for all sessions in a study plan.
  /// Fires 15 min before and at session start time.
  Future<void> scheduleStudyPlanNotifications({
    required List<Map<String, dynamic>> sessions,
  }) async {
    int idCounter = 70000;
    for (final session in sessions) {
      final startTime = DateTime.tryParse(session['startTime'] ?? '');
      if (startTime == null || startTime.isBefore(DateTime.now())) continue;

      final subject = session['subject'] ?? 'Study';
      final topic = session['topic'] ?? '';
      final durationMin = session['durationMinutes'] ?? 50;

      // 15 min before
      final preTime = startTime.subtract(const Duration(minutes: 15));
      if (preTime.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          idCounter++,
          '📚 $subject in 15 min',
          topic.isNotEmpty ? 'Topic: $topic' : 'Get ready for your study session!',
          tz.TZDateTime.from(preTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'study_reminders',
              'Study Reminders',
              channelDescription: 'Study session reminders',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // At start time
      await _plugin.zonedSchedule(
        idCounter++,
        '📖 Time to study $subject!',
        topic.isNotEmpty ? topic : '$durationMin min session starting now',
        tz.TZDateTime.from(startTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders',
            'Study Reminders',
            channelDescription: 'Study session reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Limit to first 100 sessions to avoid flooding
      if (idCounter > 70200) break;
    }
  }

  // ─── Full-Screen Alarm (priority-based) ───────────────────────────
  Future<void> scheduleReminderAlarm({
    required String reminderId,
    required String title,
    required String body,
    required DateTime eventTime,
    required List<int> reminderMinutesBefore,
    required String repeatType,
    String priority = 'high',
    bool voiceNotification = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check master toggles
    final sysEnabled = prefs.getBool('pref_system_notif') ?? true;
    final soundChoice = prefs.getString('pref_ringtone') ?? 'nokia_classic';
    
    // If system notifications are disabled and it's not a max-priority alarm, we could block it.
    // However, alarms are usually exempt from general notification silences:
    if (!sysEnabled && priority != 'high') return;

    final baseId = reminderId.hashCode.abs() % 100000;

    for (int i = 0; i < reminderMinutesBefore.length; i++) {
      final notifTime = eventTime.subtract(Duration(minutes: reminderMinutesBefore[i]));
      if (notifTime.isBefore(DateTime.now())) continue;

      final label = _formatMinutesBefore(reminderMinutesBefore[i]);
      final notifBody = reminderMinutesBefore[i] == 0
          ? '$body — Starting NOW!'
          : '$body ($label before)';

      final payload = jsonEncode({
        'type': 'alarm',
        'title': title,
        'description': body,
        'time': '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}',
        'priority': priority,
        'notificationId': baseId + i,
        'voice': voiceNotification,
      });

      // Choose channel + importance based on priority
      final isHighPriority = priority == 'high';
      final isMedium = priority == 'medium';
      
      // All reminders use the alarm channel with custom ringtone sound
      final channelId = 'vsetu_alarm_v1_$soundChoice';
      final channelName = 'VidyaSetu Alarms';
      // ALARMS MUST HAVE MAX IMPORTANCE/PRIORITY TO BYPASS LOCK SCREEN
      final importance = Importance.max;
      final notifPriority = Priority.max;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Alarm-style notifications',
          importance: importance,
          priority: notifPriority,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: false,
          ongoing: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundChoice),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          color: AppTheme.accentBlue,
          ledColor: AppTheme.accentBlue,
          ledOnMs: 1000,
          ledOffMs: 500,
          ticker: 'Reminder: $title',
        ),
      );

      if (repeatType == 'once') {
        await _plugin.zonedSchedule(
          baseId + i,
          isHighPriority ? '⏰ $title' : '📅 $title',
          notifBody,
          tz.TZDateTime.from(notifTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else if (repeatType == 'daily') {
        await _plugin.zonedSchedule(
          baseId + i,
          '⏰ $title',
          notifBody,
          tz.TZDateTime.from(notifTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else if (repeatType == 'weekly') {
        await _plugin.zonedSchedule(
          baseId + i,
          '⏰ $title',
          notifBody,
          tz.TZDateTime.from(notifTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
    }
  }

  // ─── Pre-Notifications (motivation messages before exams/events) ──
  Future<void> schedulePreNotifications({
    required String reminderId,
    required String title,
    required DateTime eventTime,
  }) async {
    final baseId = (reminderId.hashCode.abs() % 100000) + 50000;

    final preIntervals = <int, String>{
      7200:  '🎯 Your "$title" session starts in 5 days. Plan ahead and stay consistent!',
      1440:  '📖 "$title" is tomorrow! Review your notes tonight for a head start.',
      30:    '🚀 "$title" starts in 30 minutes. Grab your materials and get ready!',
      0:     '⏰ "$title" is starting NOW! Let\'s go! 💪',
    };

    int idx = 0;
    for (final entry in preIntervals.entries) {
      final notifTime = eventTime.subtract(Duration(minutes: entry.key));
      if (notifTime.isBefore(DateTime.now())) {
        idx++;
        continue;
      }

      await _plugin.zonedSchedule(
        baseId + idx,
        entry.key == 0 ? '⏰ $title — NOW!' : '📅 Upcoming: $title',
        entry.value,
        tz.TZDateTime.from(notifTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            entry.key == 0 ? 'alarm_reminders' : 'study_reminders',
            entry.key == 0 ? 'Alarm Reminders' : 'Study Reminders',
            channelDescription: entry.key == 0 ? 'Alarm-style notifications' : 'Study session notifications',
            importance: entry.key == 0 ? Importance.max : Importance.high,
            priority: entry.key == 0 ? Priority.max : Priority.high,
            icon: '@mipmap/ic_launcher',
            fullScreenIntent: entry.key == 0,
          ),
        ),
        androidScheduleMode: entry.key == 0
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      idx++;
    }
  }

  // ─── Instant Notifications (Alerts/Blockers) ──────────────────────
  Future<void> showInstantNotification(String title, String body, {String? payload}) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_reminders',
          'Alarm Reminders',
          channelDescription: 'High priority alerts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  // ─── Chat Message Notification ────────────────────────────────────
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String roomId,
    required String senderId,
  }) async {
    final id = roomId.hashCode.abs() % 100000 + 30000;

    await _plugin.show(
      id,
      '💬 $senderName',
      message.length > 80 ? '${message.substring(0, 80)}...' : message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'New chat messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.message,
        ),
      ),
      payload: jsonEncode({
        'type': 'chat',
        'roomId': roomId,
        'senderName': senderName,
        'senderId': senderId,
      }),
    );
  }

  // ─── Mentor Feedback Notification ─────────────────────────────────
  Future<void> showFeedbackNotification({
    required String mentorName,
    required String feedbackTitle,
    required String feedbackPreview,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000 + 40000;

    await _plugin.show(
      id,
      '📝 Feedback from $mentorName',
      feedbackPreview.length > 100
          ? '${feedbackPreview.substring(0, 100)}...'
          : feedbackPreview,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mentor_feedback',
          'Mentor Feedback',
          channelDescription: 'Feedback notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode({'type': 'feedback'}),
    );
  }

  // ─── Voice TTS ────────────────────────────────────────────────────
  Future<void> speakReminder(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ─── Incoming Call Notification ────────────────────────────────────
  Future<void> showIncomingCallNotification({
    required int id,
    required String callerName,
  }) async {
    await _plugin.show(
      id,
      '📞 Incoming Call',
      '$callerName is calling you...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'incoming_calls',
          'Incoming Calls',
          channelDescription: 'Incoming video call alerts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          autoCancel: false,
          ongoing: true,
        ),
      ),
    );
  }

  // ─── Immediate Test Alarm (for debugging) ──────────────────────────
  Future<Map<String, dynamic>> showTestAlarm() async {
    if (!_initialized) await init();
    final prefs = await SharedPreferences.getInstance();
    final soundChoice = prefs.getString('pref_ringtone') ?? 'nokia_classic';

    final diagnostics = await checkPermissions();
    final fireTime = DateTime.now().add(const Duration(seconds: 15));

    final payload = jsonEncode({
      'type': 'alarm',
      'title': 'Test Alarm',
      'description': 'Full-screen intent alarm test! If you see this, notifications work. 🎉',
      'time': '${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}',
      'priority': 'high',
      'notificationId': 99999,
      'voice': false,
    });

    await _plugin.zonedSchedule(
      99999,
      '⏰ Test Alarm — VidyaSetu',
      'Full-screen intent alarm test! If you see this, notifications work. 🎉',
      tz.TZDateTime.from(fireTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'vsetu_alarm_v1_$soundChoice',
          'VidyaSetu Alarms',
          channelDescription: 'Alarm-style full-screen notifications',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundChoice),
          enableVibration: true,
          additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    return diagnostics;
  }

  /// Check all notification-related permissions and return diagnostic info.
  Future<Map<String, dynamic>> checkPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    bool? notifPermission;
    bool? exactAlarmPermission;
    
    try {
      notifPermission = await androidPlugin?.areNotificationsEnabled();
    } catch (_) {}
    
    try {
      exactAlarmPermission = await androidPlugin?.canScheduleExactNotifications();
    } catch (_) {}

    return {
      'notificationsEnabled': notifPermission,
      'exactAlarmsEnabled': exactAlarmPermission,
      'initialized': _initialized,
    };
  }

  // ─── Cancel helpers ────────────────────────────────────────────────
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelByReminderId(String reminderId, int count) async {
    final baseId = reminderId.hashCode.abs() % 100000;
    for (int i = 0; i < count; i++) {
      await _plugin.cancel(baseId + i);
    }
    // Also cancel pre-notifications
    final preBaseId = (reminderId.hashCode.abs() % 100000) + 50000;
    for (int i = 0; i < 4; i++) {
      await _plugin.cancel(preBaseId + i);
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
