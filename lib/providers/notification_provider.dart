import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  int _notificationIdCounter = 100;

  // Preferences
  bool _sessionInterruptions = true;
  bool _dailyProgressReports = true;
  bool _weeklySummaries = true;
  bool _milestoneAchievements = false;
  bool _lowEngagementAlerts = false;

  // Tracking
  int _scansToday = 0;
  int _scansThisWeek = 0;
  int _totalScans = 0;
  String? _lastScanDate;
  DateTime? _lastEngagement;

  bool get sessionInterruptions => _sessionInterruptions;
  bool get dailyProgressReports => _dailyProgressReports;
  bool get weeklySummaries => _weeklySummaries;
  bool get milestoneAchievements => _milestoneAchievements;
  bool get lowEngagementAlerts => _lowEngagementAlerts;
  int get totalScans => _totalScans;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionInterruptions = prefs.getBool('notif_session_interruptions') ?? true;
    _dailyProgressReports = prefs.getBool('notif_daily_progress') ?? true;
    _weeklySummaries = prefs.getBool('notif_weekly_summaries') ?? true;
    _milestoneAchievements = prefs.getBool('notif_milestones') ?? false;
    _lowEngagementAlerts = prefs.getBool('notif_low_engagement') ?? false;
    _totalScans = prefs.getInt('notif_total_scans') ?? 0;
    _lastScanDate = prefs.getString('notif_last_scan_date');
    notifyListeners();
  }

  Future<void> setSessionInterruptions(bool value) async {
    _sessionInterruptions = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_session_interruptions', value);
    notifyListeners();
  }

  Future<void> setDailyProgressReports(bool value) async {
    _dailyProgressReports = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_daily_progress', value);
    notifyListeners();
  }

  Future<void> setWeeklySummaries(bool value) async {
    _weeklySummaries = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_weekly_summaries', value);
    notifyListeners();
  }

  Future<void> setMilestoneAchievements(bool value) async {
    _milestoneAchievements = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_milestones', value);
    notifyListeners();
  }

  Future<void> setLowEngagementAlerts(bool value) async {
    _lowEngagementAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_low_engagement', value);
    notifyListeners();
  }

  Future<void> onScanComplete(String textSnippet) async {
    final prefs = await SharedPreferences.getInstance();
    _totalScans = (prefs.getInt('notif_total_scans') ?? 0) + 1;
    await prefs.setInt('notif_total_scans', _totalScans);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final weekStart = _getWeekStart();

    if (_lastScanDate == today) {
      _scansToday = (prefs.getInt('notif_scans_today') ?? 0) + 1;
    } else {
      _scansToday = 1;
    }
    await prefs.setInt('notif_scans_today', _scansToday);
    await prefs.setString('notif_last_scan_date', today);

    final savedWeekStart = prefs.getString('notif_week_start') ?? '';
    if (savedWeekStart == weekStart) {
      _scansThisWeek = (prefs.getInt('notif_scans_this_week') ?? 0) + 1;
    } else {
      _scansThisWeek = 1;
      await prefs.setString('notif_week_start', weekStart);
    }
    await prefs.setInt('notif_scans_this_week', _scansThisWeek);

    _lastEngagement = DateTime.now();

    final id = _notificationIdCounter++;

    if (textSnippet.isNotEmpty) {
      await _notificationService.showScanComplete(id: id, textSnippet: textSnippet);
    }

    if (_milestoneAchievements) {
      await _checkMilestones();
    }
  }

  Future<void> onSessionInterrupted(String childName) async {
    if (!_sessionInterruptions) return;
    final id = _notificationIdCounter++;
    await _notificationService.showSessionInterrupted(
      id: id,
      childName: childName,
    );
  }

  Future<void> onAppForegrounded() async {
    _lastEngagement = DateTime.now();

    if (await _shouldShowDailyReport()) {
      if (_dailyProgressReports) {
        final id = _notificationIdCounter++;
        await _notificationService.showDailyProgress(
          id: id,
          scansToday: _scansToday,
        );
      }

      if (_weeklySummaries && _isWeekEnd()) {
        final id = _notificationIdCounter++;
        await _notificationService.showWeeklySummary(
          id: id,
          scansThisWeek: _scansThisWeek,
        );
      }
    }

    if (_lowEngagementAlerts && await _shouldShowEngagementAlert()) {
      await _notificationService.showLowEngagement();
    }
  }

  Future<bool> _shouldShowDailyReport() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReportDate = prefs.getString('notif_last_report_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastReportDate == today) return false;
    await prefs.setString('notif_last_report_date', today);
    return _dailyProgressReports || _weeklySummaries;
  }

  Future<bool> _shouldShowEngagementAlert() async {
    if (_lastEngagement == null) return false;
    final hoursSince = DateTime.now().difference(_lastEngagement!).inHours;
    if (hoursSince < 48) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastAlertDate = prefs.getString('notif_last_engagement_alert');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastAlertDate == today) return false;
    await prefs.setString('notif_last_engagement_alert', today);
    return true;
  }

  Future<void> _checkMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMilestone = prefs.getInt('notif_last_milestone') ?? 0;
    final milestones = [10, 25, 50, 100, 250, 500, 1000];

    int reachedMilestone = 0;
    for (final m in milestones) {
      if (_totalScans >= m) reachedMilestone = m;
    }

    if (reachedMilestone > lastMilestone) {
      await prefs.setInt('notif_last_milestone', reachedMilestone);
      final id = _notificationIdCounter++;
      await _notificationService.showMilestoneReached(
        id: id,
        totalScans: _totalScans,
      );
    }
  }

  bool _isWeekEnd() {
    return DateTime.now().weekday == DateTime.sunday;
  }

  String _getWeekStart() {
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - DateTime.monday;
    final monday = now.subtract(Duration(days: daysSinceMonday));
    return monday.toIso8601String().substring(0, 10);
  }
}
