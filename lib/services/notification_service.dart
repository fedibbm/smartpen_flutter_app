import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification channel IDs
  static const String _readingChannelId = 'reading_session';
  static const String _progressChannelId = 'daily_progress';
  static const String _reminderChannelId = 'reading_reminder';

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _readingChannelId,
        'Reading Session',
        description: 'Notifications about your reading sessions',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _progressChannelId,
        'Progress Reports',
        description: 'Daily and weekly reading progress updates',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Reading Reminders',
        description: 'Reminders to keep up with your reading',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  Future<void> showSessionInterrupted({
    required int id,
    required String childName,
  }) async {
    await _showNotification(
      id: id,
      channelId: _readingChannelId,
      title: 'Session Interrupted',
      body: '$childName has interrupted their reading session.',
    );
  }

  Future<void> showReadingComplete({
    required int id,
    required String textPreview,
  }) async {
    await _showNotification(
      id: id,
      channelId: _readingChannelId,
      title: 'Reading Complete',
      body: 'Scanned: ${textPreview.length > 80 ? '${textPreview.substring(0, 80)}...' : textPreview}',
    );
  }

  Future<void> showDailyProgress({
    required int id,
    required int scansToday,
  }) async {
    await _showNotification(
      id: id,
      channelId: _progressChannelId,
      title: 'Daily Reading Summary',
      body: scansToday > 0
          ? 'Great job! You completed $scansToday scan${scansToday > 1 ? 's' : ''} today.'
          : 'You haven\'t done any reading today. Pick up your pen and start!',
    );
  }

  Future<void> showWeeklySummary({
    required int id,
    required int scansThisWeek,
  }) async {
    await _showNotification(
      id: id,
      channelId: _progressChannelId,
      title: 'Weekly Progress Report',
      body: 'This week: $scansThisWeek scan${scansThisWeek > 1 ? 's' : ''}. Keep it up!',
    );
  }

  Future<void> showMilestoneReached({
    required int id,
    required int totalScans,
  }) async {
    final milestones = [10, 25, 50, 100, 250, 500, 1000];
    String milestoneStr = 'Read milestone';
    for (final m in milestones) {
      if (totalScans >= m) milestoneStr = '$m scans completed!';
    }

    await _showNotification(
      id: id,
      channelId: _progressChannelId,
      title: 'Milestone Achievement!',
      body: 'Congratulations! You\'ve reached: $milestoneStr',
    );
  }

  Future<void> showLowEngagement() async {
    await _showNotification(
      id: 9999,
      channelId: _reminderChannelId,
      title: 'Miss You!',
      body: 'It\'s been a while since your last reading session. Come back and practice!',
    );
  }

  Future<void> showScanComplete({
    required int id,
    required String textSnippet,
  }) async {
    await _showNotification(
      id: id,
      channelId: _readingChannelId,
      title: 'Text Recognized',
      body: textSnippet.length > 100
          ? '${textSnippet.substring(0, 100)}...'
          : textSnippet,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _readingChannelId
          ? 'Reading Session'
          : channelId == _progressChannelId
              ? 'Progress Reports'
              : 'Reading Reminders',
      channelDescription: '',
      importance: channelId == _readingChannelId
          ? Importance.high
          : channelId == _progressChannelId
              ? Importance.defaultImportance
              : Importance.low,
      priority: channelId == _readingChannelId
          ? Priority.high
          : channelId == _progressChannelId
              ? Priority.defaultPriority
              : Priority.low,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
