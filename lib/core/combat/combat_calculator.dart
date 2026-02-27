// lib/core/combat/combat_calculator.dart

class PowerStats {
  final int strength, speed, power, combat, intelligence, durability;

  const PowerStats({
    required this.strength,
    required this.speed,
    required this.power,
    required this.combat,
    required this.intelligence,
    required this.durability,
  });

  static int safeStat(dynamic v, {int max = 999}) {
    if (v == null) return 0;
    final s = v.toString().trim().toLowerCase();
    final parsed = int.tryParse(s);
    if (parsed == null) return 0;
    return parsed.clamp(0, max);
  }

  factory PowerStats.fromJson(Map<String, dynamic> json, {int max = 999}) {
    return PowerStats(
      strength: safeStat(json['strength'], max: max),
      speed: safeStat(json['speed'], max: max),
      power: safeStat(json['power'], max: max),
      combat: safeStat(json['combat'], max: max),
      intelligence: safeStat(json['intelligence'], max: max),
      durability: safeStat(json['durability'], max: max),
    );
  }
}

class CombatRating {
  final int attack;
  final int defense;
  const CombatRating({required this.attack, required this.defense});
}

class CombatCalculator {
  static CombatRating calculate(PowerStats s) {
    final attack =
        (s.strength * 0.35) +
        (s.power * 0.35) +
        (s.combat * 0.20) +
        (s.speed * 0.10);

    final defense =
        (s.durability * 0.50) +
        (s.speed * 0.20) +
        (s.intelligence * 0.20) +
        (s.combat * 0.10);

    return CombatRating(
      attack: attack.round(),
      defense: defense.round(),
    );
  }
}