import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _kPush = 'push_notifications';
  static const _kDark = 'dark_mode';
  static const _kLocation = 'location_tracking';
  static const _kSound = 'sound_alerts';

  bool _pushNotifications = true;
  bool _darkMode = true;
  bool _locationTracking = true;
  bool _soundAlerts = false;

  bool get pushNotifications => _pushNotifications;
  bool get darkMode => _darkMode;
  bool get locationTracking => _locationTracking;
  bool get soundAlerts => _soundAlerts;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_kPush) ?? true;
    _darkMode = prefs.getBool(_kDark) ?? true;
    _locationTracking = prefs.getBool(_kLocation) ?? true;
    _soundAlerts = prefs.getBool(_kSound) ?? false;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool v) async {
    _pushNotifications = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPush, v);
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, v);
  }

  Future<void> setLocationTracking(bool v) async {
    _locationTracking = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLocation, v);
  }

  Future<void> setSoundAlerts(bool v) async {
    _soundAlerts = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, v);
  }
}