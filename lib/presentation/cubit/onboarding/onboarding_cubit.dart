import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/local/consent_storage.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required ConsentStorage consentStorage,
    required FirebaseAnalytics analytics,
    required FirebaseCrashlytics crashlytics,
  })  : _storage = consentStorage,
        _analytics = analytics,
        _crashlytics = crashlytics,
        super(OnboardingState.initial());

  final ConsentStorage _storage;
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  bool _hydrating = false;
  static const int _maxStep = 2; // 0=intro, 1=analytics, 2=crashlytics

  /// Kallas vid appstart (du gör ..hydrate()).
  /// Tål att kallas flera gånger utan att förstöra state.
  Future<void> hydrate() async {
    if (state.hydrated || _hydrating) return;
    _hydrating = true;

    try {
      final consent = await _storage.read();

      emit(
        state.copyWith(
          hydrated: true,
          step: 0,
          analyticsEnabled: consent.analyticsEnabled,
          crashlyticsEnabled: consent.crashlyticsEnabled,
          complete: consent.onboardingComplete,
        ),
      );
    } catch (_) {
      // Aldrig krascha: fall tillbaka till defaults
      emit(
        state.copyWith(
          hydrated: true,
          step: 0,
          analyticsEnabled: false,
          crashlyticsEnabled: false,
          complete: false,
        ),
      );
    } finally {
      _hydrating = false;
    }
  }

  void next() {
    final nextStep = (state.step + 1).clamp(0, _maxStep);
    emit(state.copyWith(step: nextStep));
  }

  void back() {
    final prevStep = (state.step - 1).clamp(0, _maxStep);
    emit(state.copyWith(step: prevStep));
  }

  Future<void> setAnalytics(bool enabled) async {
    // Optimistic UI
    emit(state.copyWith(analyticsEnabled: enabled));

    try {
      await _storage.writeAnalytics(enabled);
    } catch (_) {
      // Storage fail → backa UI
      emit(state.copyWith(analyticsEnabled: !enabled));
      return;
    }

    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {
      // Toggle fail ska inte krascha appen
    }
  }

  Future<void> setCrashlytics(bool enabled) async {
    emit(state.copyWith(crashlyticsEnabled: enabled));

    try {
      await _storage.writeCrashlytics(enabled);
    } catch (_) {
      emit(state.copyWith(crashlyticsEnabled: !enabled));
      return;
    }

    if (!kIsWeb) {
      try {
        await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      } catch (_) {}
    }
  }

  Future<void> finish() async {
    // Skriv först → sen complete=true (så redirect inte springer före)
    try {
      await _storage.writeOnboardingComplete(true);
    } catch (_) {
      return;
    }

    emit(state.copyWith(complete: true));
  }

  /// För test i Settings: nollställ val + visa onboarding igen vid nästa start.
  Future<void> resetAll() async {
    try {
      await _storage.clearAll();
    } catch (_) {
      return;
    }

    emit(
      state.copyWith(
        hydrated: true,
        step: 0,
        analyticsEnabled: false,
        crashlyticsEnabled: false,
        complete: false,
      ),
    );

    // Respektera "om nej -> av"
    try {
      await _analytics.setAnalyticsCollectionEnabled(false);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
      } catch (_) {}
    }
  }
}