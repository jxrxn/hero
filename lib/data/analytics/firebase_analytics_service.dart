import 'package:firebase_analytics/firebase_analytics.dart';

import '../../domain/analytics/analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  @override
  Future<void> logLogin({required bool success}) {
    return _analytics.logEvent(
      name: 'login',
      parameters: {'success': success},
    );
  }

  @override
  Future<void> logLogout({required bool success}) {
    return _analytics.logEvent(
      name: 'logout',
      parameters: {'success': success},
    );
  }

  @override
  Future<void> logSignUp({required bool success}) {
    return _analytics.logEvent(
      name: 'sign_up',
      parameters: {'success': success},
    );
  }
}