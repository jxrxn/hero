import 'package:flutter/material.dart';

@immutable
class TeamColors extends ThemeExtension<TeamColors> {
  const TeamColors({
    required this.heroes,
    required this.villains,
    required this.neutral,
  });

  final Color heroes;
  final Color villains;
  final Color neutral;

  @override
  TeamColors copyWith({
    Color? heroes,
    Color? villains,
    Color? neutral,
  }) {
    return TeamColors(
      heroes: heroes ?? this.heroes,
      villains: villains ?? this.villains,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  TeamColors lerp(ThemeExtension<TeamColors>? other, double t) {
    if (other is! TeamColors) return this;
    return TeamColors(
      heroes: Color.lerp(heroes, other.heroes, t) ?? heroes,
      villains: Color.lerp(villains, other.villains, t) ?? villains,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
    );
  }
}

extension TeamColorsX on BuildContext {
  TeamColors get teamColors =>
      Theme.of(this).extension<TeamColors>() ??
      (throw StateError('TeamColors is missing from ThemeData.extensions'));
}