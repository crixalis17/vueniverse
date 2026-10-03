import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/analytics/evidence_uncertainty.dart';

void main() {
  test(
    'four consistent observations still have a two-sided p-value of .125',
    () {
      expect(pairedSignTest([8, 10, 12, 14]).pValue, .125);
      expect(pairedSignTest([-8, -10, -12, -14]).pValue, .125);
    },
  );
  test(
    'ties carry no directional evidence and balanced signs are uncertain',
    () {
      final result = pairedSignTest([0, 0, 1, -1]);
      expect(result.ties, 2);
      expect(result.pValue, 1);
      expect(pairedSignTest([]).pValue, 1);
      expect(pairedSignTest([0, 0]).pValue, 1);
    },
  );
  test(
    'six positive and two negative observations are not strong sign evidence',
    () {
      expect(pairedSignTest([8, 10, 12, 13, 14, 14, -2, -1]).pValue, .2890625);
    },
  );
  test('Holm adjusts the whole predeclared family monotonically', () {
    final result = holmAdjustedPValues({'a': .01, 'b': .03, 'c': .2});
    expect(result['a'], closeTo(.03, 1e-12));
    expect(result['b'], closeTo(.06, 1e-12));
    expect(result['c'], closeTo(.2, 1e-12));
    expect(holmAdjustedPValues({'c': .2, 'a': .01, 'b': .03}), result);
    expect(holmAdjustedPValues({'a': .6, 'b': .7}), {'a': 1, 'b': 1});
  });
  test('invalid observations and probabilities fail explicitly', () {
    expect(() => pairedSignTest([double.nan]), throwsArgumentError);
    expect(() => holmAdjustedPValues({'a': -.1}), throwsArgumentError);
  });
}
