import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences
class UserPreferencesService {
  static const String _keyParentEmail = 'parent_email';
  static const String _keyChildName = 'child_name';
  static const String _keyEmailNotificationsEnabled = 'email_notifications_enabled';

  /// Save parent email address
  Future<void> saveParentEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParentEmail, email);
  }

  /// Get parent email address
  Future<String?> getParentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyParentEmail);
  }

  /// Save child name
  Future<void> saveChildName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChildName, name);
  }

  /// Get child name
  Future<String?> getChildName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyChildName);
  }

  /// Enable/disable email notifications
  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEmailNotificationsEnabled, enabled);
  }

  /// Check if email notifications are enabled
  Future<bool> areEmailNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEmailNotificationsEnabled) ?? true; // Default: enabled
  }

  /// Save user profile data
  Future<void> saveUserProfile({
    required String parentEmail,
    required String childName,
    bool emailNotifications = true,
  }) async {
    await saveParentEmail(parentEmail);
    await saveChildName(childName);
    await setEmailNotificationsEnabled(emailNotifications);
  }

  /// Check if user profile is complete
  Future<bool> isProfileComplete() async {
    final parentEmail = await getParentEmail();
    final childName = await getChildName();
    return parentEmail != null && childName != null && 
           parentEmail.isNotEmpty && childName.isNotEmpty;
  }

  /// Clear all user preferences
  Future<void> clearUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyParentEmail);
    await prefs.remove(_keyChildName);
    await prefs.remove(_keyEmailNotificationsEnabled);
  }
}
