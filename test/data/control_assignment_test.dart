import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:vueniverse/domain/analytics/control_assignment.dart';

void main() {
  final first = DateTime.utc(2026, 9, 1);
  final second = DateTime.utc(2026, 9, 2);
  test('matches exhaustive optimum for bounded competing-baseline graphs', () {
    final random = Random(61703);
    for (var trial = 0; trial < 60; trial++) {
      final graph = {
        for (var event = 0; event < 4; event++)
          'event-$event': {
            for (var window = 0; window < 4; window++)
              if (random.nextBool())
                first.add(Duration(days: window)): random.nextInt(20),
          },
      };
      final events = graph.keys.toList();
      var bestCount = -1;
      var bestCost = 1 << 30;
      void search(int index, Set<DateTime> used, int count, int cost) {
        if (index == events.length) {
          if (count > bestCount || count == bestCount && cost < bestCost) {
            bestCount = count;
            bestCost = cost;
          }
          return;
        }
        search(index + 1, used, count, cost);
        for (final edge in graph[events[index]]!.entries) {
          if (used.contains(edge.key)) continue;
          search(index + 1, {...used, edge.key}, count + 1, cost + edge.value);
        }
      }

      search(0, {}, 0, 0);
      final result = assignControlWindows(graph);
      expect(result.length, bestCount, reason: 'trial $trial');
      expect(
        result.entries.fold<int>(
          0,
          (sum, entry) => sum + graph[entry.key]![entry.value]!,
        ),
        bestCost,
        reason: 'trial $trial',
      );
      expect(result.values.toSet().length, result.length);
    }
  });
  test('reassigns flexible occurrence to preserve constrained occurrence', () {
    final candidates = {
      'a': {first: 1, second: 2},
      'b': {first: 1},
    };
    expect(assignControlWindows(candidates), {'a': second, 'b': first});
    expect(
      assignControlWindows({'b': candidates['b']!, 'a': candidates['a']!}),
      {'a': second, 'b': first},
    );
  });
  test('minimizes total temporal mismatch, not first-event preference', () {
    expect(
      assignControlWindows({
        'a': {first: 1, second: 2},
        'b': {first: 2, second: 100},
      }),
      {'a': second, 'b': first},
    );
  });
  test('scarcity never duplicates a control and empty cohorts are safe', () {
    final matched = assignControlWindows({
      'a': {first: 1},
      'b': {first: 1},
    });
    expect(matched, hasLength(1));
    expect(matched.values.toSet(), hasLength(1));
    expect(assignControlWindows({'a': {}}), isEmpty);
  });
  test('equal-cost assignment is stable across event and resource order', () {
    expect(
      assignControlWindows({
        'a': {first: 1, second: 1},
        'b': {first: 1, second: 1},
      }),
      assignControlWindows({
        'b': {second: 1, first: 1},
        'a': {second: 1, first: 1},
      }),
    );
  });
}
