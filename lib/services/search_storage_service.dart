import 'package:shared_preferences/shared_preferences.dart';

class SearchStorageService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryLength = 10;

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    
    // Remove if exists to move it to the top
    history.remove(query);
    
    // Add to beginning
    history.insert(0, query);
    
    // Limit length
    if (history.length > _maxHistoryLength) {
      history = history.sublist(0, _maxHistoryLength);
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  Future<void> removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    
    history.remove(query);
    
    await prefs.setStringList(_historyKey, history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
