import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  /// Get saved language code (default: 'en')
  static Future<String> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'en';
    } catch (e) {
      return 'en';
    }
  }
  
  /// Save language code
  static Future<bool> saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      return false;
    }
  }
}
