import 'package:flutter_test/flutter_test.dart';
import 'package:hero/core/utils/alignment_utils.dart';

void main() {
  group('normalizeAlign', () {
    test('returns good when string contains good', () {
      expect(normalizeAlign('good'), 'good');
      expect(normalizeAlign('very good hero'), 'good');
    });

    test('returns bad when string contains bad or evil', () {
      expect(normalizeAlign('bad'), 'bad');
      expect(normalizeAlign('evil mastermind'), 'bad');
    });

    test('returns neutral otherwise', () {
      expect(normalizeAlign('unknown'), 'neutral');
      expect(normalizeAlign(''), 'neutral');
    });
  });
}