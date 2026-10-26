import 'package:shared_preferences/shared_preferences.dart';

class DistrictService {
  static const _key = 'selected_district';

  static String? _current;

  /// Currently selected district (in memory).
  static String? get current => _current;

  /// Load the saved district at app start.
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_key);
    return _current;
  }

  /// Save the district whenever the user picks one.
  static Future<void> set(String district) async {
    _current = district;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, district);
  }

  /// Clear it (used on logout or "change district").
  static Future<void> clear() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}