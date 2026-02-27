import 'package:shared_preferences/shared_preferences.dart';

class Consent {
  const Consent({
    required this.onboardingComplete,
    required this.analyticsEnabled,
    required this.crashlyticsEnabled,
  });

  final bool onboardingComplete;
  final bool analyticsEnabled;
  final bool crashlyticsEnabled;

  Consent copyWith({
    bool? onboardingComplete,
    bool? analyticsEnabled,
    bool? crashlyticsEnabled,
  }) {
    return Consent(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashlyticsEnabled: crashlyticsEnabled ?? this.crashlyticsEnabled,
    );
  }

  static const defaults = Consent(
    onboardingComplete: false,
    analyticsEnabled: false,
    crashlyticsEnabled: false,
  );
}

class ConsentStorage {
  ConsentStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingComplete = 'consent_onboarding_complete';
  static const _kAnalyticsEnabled = 'consent_analytics_enabled';
  static const _kCrashlyticsEnabled = 'consent_crashlytics_enabled';

  /// Async (säkert vid start)
  Future<Consent> read() async {
    return Consent(
      onboardingComplete: _prefs.getBool(_kOnboardingComplete) ?? Consent.defaults.onboardingComplete,
      analyticsEnabled: _prefs.getBool(_kAnalyticsEnabled) ?? Consent.defaults.analyticsEnabled,
      crashlyticsEnabled: _prefs.getBool(_kCrashlyticsEnabled) ?? Consent.defaults.crashlyticsEnabled,
    );
  }

  /// Sync-variant om du vill läsa direkt (du använde den tidigare ibland)
  Consent readSync() {
    return Consent(
      onboardingComplete: _prefs.getBool(_kOnboardingComplete) ?? false,
      analyticsEnabled: _prefs.getBool(_kAnalyticsEnabled) ?? false,
      crashlyticsEnabled: _prefs.getBool(_kCrashlyticsEnabled) ?? false,
    );
  }

  Future<void> writeAnalytics(bool enabled) async {
    await _prefs.setBool(_kAnalyticsEnabled, enabled);
  }

  Future<void> writeCrashlytics(bool enabled) async {
    await _prefs.setBool(_kCrashlyticsEnabled, enabled);
  }

  Future<void> writeOnboardingComplete(bool complete) async {
    await _prefs.setBool(_kOnboardingComplete, complete);
  }

  /// (valfritt) om du vill kunna nollställa onboarding vid test
  Future<void> clearAll() async {
    await _prefs.remove(_kOnboardingComplete);
    await _prefs.remove(_kAnalyticsEnabled);
    await _prefs.remove(_kCrashlyticsEnabled);
  }
}