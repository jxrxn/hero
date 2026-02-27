import 'package:equatable/equatable.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.hydrated,
    required this.step,
    required this.analyticsEnabled,
    required this.crashlyticsEnabled,
    required this.complete,
  });

  final bool hydrated;
  final int step;
  final bool analyticsEnabled;
  final bool crashlyticsEnabled;
  final bool complete;

  factory OnboardingState.initial() {
    return const OnboardingState(
      hydrated: false,
      step: 0,
      analyticsEnabled: false,
      crashlyticsEnabled: false,
      complete: false,
    );
  }

  OnboardingState copyWith({
    bool? hydrated,
    int? step,
    bool? analyticsEnabled,
    bool? crashlyticsEnabled,
    bool? complete,
  }) {
    return OnboardingState(
      hydrated: hydrated ?? this.hydrated,
      step: step ?? this.step,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashlyticsEnabled: crashlyticsEnabled ?? this.crashlyticsEnabled,
      complete: complete ?? this.complete,
    );
  }

  @override
  List<Object> get props => [
        hydrated,
        step,
        analyticsEnabled,
        crashlyticsEnabled,
        complete,
      ];
}