import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_lock_app/models/todo.dart';
import 'package:todo_lock_app/services/hive_service.dart';

class NotificationService {
  static const int _ongoingNotificationId = 1;

  static const String _ongoingChannelId = 'todo_ongoing_channel_v2';
  static const String _ongoingChannelName = '할일 고정 알림';
  static const String _ongoingChannelDesc = '잠금화면에 할일 목록을 표시합니다';

  static const String _reminderChannelId = 'todo_reminder_channel';
  static const String _reminderChannelName = '할일 리마인더';
  static const String _reminderChannelDesc = '예약된 시간에 할일을 알려줍니다';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Called from main() after runApp — never blocks the UI
  Future<void> initInBackground(HiveService hiveService) async {
    try {
      await init();
      await requestPermissions();
      final incomplete = hiveService.getIncompleteTodos();
      await updateOngoingNotification(incomplete);
    } catch (_) {}
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    // 이전 채널 삭제 (importance 변경 반영을 위해)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.deleteNotificationChannel(channelId: 'todo_ongoing_channel');
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    final notifGranted =
        await android.requestNotificationsPermission() ?? false;
    await android.requestExactAlarmsPermission();
    return notifGranted;
  }

  // --- Ongoing (lock screen) notification ---

  static const int _maxSummaryChars = 80;
  static const String _separator = ', ';

  String _buildSummaryText(List<Todo> todos) {
    final n = todos.length;
    final totalSepLen = (n - 1) * _separator.length;
    final available = _maxSummaryChars - totalSepLen;
    final baseAlloc = available ~/ n;

    // 짧은 할일에서 남는 글자수를 긴 할일에 재분배
    var surplus = 0;
    var longCount = 0;
    for (final t in todos) {
      if (t.title.length <= baseAlloc) {
        surplus += baseAlloc - t.title.length;
      } else {
        longCount++;
      }
    }

    final alloc = longCount > 0 ? baseAlloc + surplus ~/ longCount : baseAlloc;

    final parts = todos.map((t) {
      if (t.title.length <= alloc) return t.title;
      if (alloc <= 1) return '…';
      return '${t.title.substring(0, alloc - 1)}…';
    });

    return parts.join(_separator);
  }

  Future<void> updateOngoingNotification(List<Todo> incompleteTodos) async {
    if (!_initialized) return;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    if (incompleteTodos.isEmpty) {
      await androidPlugin.stopForegroundService();
      return;
    }

    final lines = incompleteTodos.map((t) => '• ${t.title}').toList();
    final summaryText = _buildSummaryText(incompleteTodos);

    final inboxStyle = InboxStyleInformation(
      lines,
      contentTitle: '할일 목록',
      summaryText: summaryText,
    );

    final androidDetails = AndroidNotificationDetails(
      _ongoingChannelId,
      _ongoingChannelName,
      channelDescription: _ongoingChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      silent: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      styleInformation: inboxStyle,
      icon: '@drawable/ic_notification',
    );

    await androidPlugin.startForegroundService(
      id: _ongoingNotificationId,
      title: '할일 목록',
      body: summaryText,
      notificationDetails: androidDetails,
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
      },
    );
  }

  // --- Scheduled reminder notification ---

  int generateNotificationId() {
    return Random().nextInt(0x7FFFFFFF - 1) + 1;
  }

  Future<void> scheduleReminder({
    required int notificationId,
    required String title,
    String? description,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) return;
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: '@drawable/ic_notification',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: '할일 리마인더',
      body: title,
      scheduledDate: tzTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  Future<void> cancelAllReminders() async {
    // Cancel all except the ongoing notification
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id != _ongoingNotificationId) {
        await _plugin.cancel(id: p.id);
      }
    }
  }
}
