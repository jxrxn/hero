abstract class AnalyticsService {
  Future<void> logLogin({required bool success});
  Future<void> logLogout({required bool success});
  Future<void> logSignUp({required bool success});
}