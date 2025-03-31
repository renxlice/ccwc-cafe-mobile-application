import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _enabled = true;
  bool get enabled => _enabled;

  AnalyticsService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('analytics_enabled') ?? true;
    await _analytics.setAnalyticsCollectionEnabled(_enabled);
  }

  Future<void> toggleAnalytics(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', enabled);
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: name, parameters: params);
  }
}