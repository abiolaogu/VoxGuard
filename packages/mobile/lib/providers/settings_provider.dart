import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _criticalAlertsOnly = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _refreshInterval = 30; // seconds
  String _apiUrl = 'http://localhost:5001';

  bool get notificationsEnabled => _notificationsEnabled;
  bool get criticalAlertsOnly => _criticalAlertsOnly;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get refreshInterval => _refreshInterval;
  String get apiUrl => _apiUrl;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _criticalAlertsOnly = prefs.getBool('critical_alerts_only') ?? false;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _refreshInterval = prefs.getInt('refresh_interval') ?? 30;
    _apiUrl = prefs.getString('api_url') ?? 'http://localhost:5001';
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setCriticalAlertsOnly(bool value) async {
    _criticalAlertsOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('critical_alerts_only', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int seconds) async {
    _refreshInterval = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refresh_interval', seconds);
    notifyListeners();
  }

  Future<void> setApiUrl(String url) async {
    _apiUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _notificationsEnabled = true;
    _criticalAlertsOnly = false;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _refreshInterval = 30;
    _apiUrl = 'http://localhost:5001';
    notifyListeners();
  }
}
