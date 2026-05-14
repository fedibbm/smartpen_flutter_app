import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  String _locale = 'en';

  String get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_localeKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (!['en', 'fr', 'ar'].contains(locale)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
    notifyListeners();
  }
}
