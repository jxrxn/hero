import 'package:flutter_test/flutter_test.dart';
import 'package:hero/core/combat/combat_calculator.dart';

void main() {
  group('PowerStats.safeStat', () {
    test('returns 0 for null', () {
      expect(PowerStats.safeStat(null), 0);
    });

    test('parses valid integers', () {
      expect(PowerStats.safeStat('42'), 42);
      expect(PowerStats.safeStat(99), 99);
    });

    test('returns 0 for invalid values', () {
      expect(PowerStats.safeStat('abc'), 0);
      expect(PowerStats.safeStat(''), 0);
    });

    test('clamps values to max', () {
      expect(PowerStats.safeStat(1500, max: 100), 100);
      expect(PowerStats.safeStat(-10), 0);
    });
  });
}