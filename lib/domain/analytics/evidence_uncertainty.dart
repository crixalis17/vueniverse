import 'dart:math' as math;

/// Research diagnostics, not clinical validation or production promotion gates.
({int positive, int negative, int ties, double pValue}) pairedSignTest(
  List<double> differences,
) {
  if (differences.any((value) => !value.isFinite)) {
    throw ArgumentError('Differences must be finite');
  }
  final positive = differences.where((value) => value > 0).length;
  final negative = differences.where((value) => value < 0).length;
  final n = positive + negative;
  if (n > 200) throw ArgumentError('Exact diagnostic supports up to 200 pairs');
  final smaller = math.min(positive, negative);
  var probability = math.pow(0.5, n).toDouble();
  var tail = probability;
  for (var count = 1; count <= smaller; count++) {
    probability *= (n - count + 1) / count;
    tail += probability;
  }
  return (
    positive: positive,
    negative: negative,
    ties: differences.length - n,
    pValue: math.min(1, 2 * tail),
  );
}

/// Holm family-wise adjustment for a predeclared family of tested hypotheses.
Map<String, double> holmAdjustedPValues(Map<String, double> values) {
  if (values.values.any((p) => !p.isFinite || p < 0 || p > 1)) {
    throw ArgumentError('P-values must be finite and within [0, 1]');
  }
  final sorted = values.entries.toList()
    ..sort((a, b) {
      final p = a.value.compareTo(b.value);
      return p != 0 ? p : a.key.compareTo(b.key);
    });
  final adjusted = <String, double>{};
  var previous = 0.0;
  for (var rank = 0; rank < sorted.length; rank++) {
    previous = math.max(
      previous,
      math.min(1, sorted[rank].value * (sorted.length - rank)),
    );
    adjusted[sorted[rank].key] = previous;
  }
  return adjusted;
}
