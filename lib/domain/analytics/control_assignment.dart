/// Maximum-cardinality, minimum-cost assignment with unique baseline windows.
/// Stable sorted identifiers break ties without using health measurements.
Map<String, DateTime> assignControlWindows(
  Map<String, Map<DateTime, int>> candidates,
) {
  final events = candidates.keys.toList()..sort();
  final windows = candidates.values.expand((row) => row.keys).toSet().toList()
    ..sort();
  final sink = 1 + events.length + windows.length;
  final graph = List.generate(sink + 1, (_) => <_Edge>[]);
  void connect(int from, int to, int cost) {
    graph[from].add(_Edge(to, graph[to].length, 1, cost));
    graph[to].add(_Edge(from, graph[from].length - 1, 0, -cost));
  }

  for (var index = 0; index < events.length; index++) {
    final node = index + 1;
    connect(0, node, 0);
    for (var window = 0; window < windows.length; window++) {
      final cost = candidates[events[index]]![windows[window]];
      if (cost != null) connect(node, 1 + events.length + window, cost);
    }
  }
  for (var window = 0; window < windows.length; window++) {
    connect(1 + events.length + window, sink, 0);
  }
  while (true) {
    final distance = List<int?>.filled(graph.length, null)..[0] = 0;
    final previousNode = List<int>.filled(graph.length, -1);
    final previousEdge = List<int>.filled(graph.length, -1);
    // Residual reverse edges have negative costs. Bellman-Ford is sufficient
    // for the bounded 30-day personal timeline and permits reassignment.
    for (var pass = 0; pass < graph.length - 1; pass++) {
      var changed = false;
      for (var from = 0; from < graph.length; from++) {
        if (distance[from] == null) continue;
        for (var edgeIndex = 0; edgeIndex < graph[from].length; edgeIndex++) {
          final edge = graph[from][edgeIndex];
          if (edge.capacity == 0) continue;
          final proposed = distance[from]! + edge.cost;
          if (distance[edge.to] == null || proposed < distance[edge.to]!) {
            distance[edge.to] = proposed;
            previousNode[edge.to] = from;
            previousEdge[edge.to] = edgeIndex;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }
    if (distance[sink] == null) break;
    for (var node = sink; node != 0; node = previousNode[node]) {
      final from = previousNode[node];
      final edge = graph[from][previousEdge[node]];
      edge.capacity--;
      graph[node][edge.reverse].capacity++;
    }
  }
  return {
    for (var index = 0; index < events.length; index++)
      for (final edge in graph[index + 1])
        if (edge.to > events.length && edge.to < sink && edge.capacity == 0)
          events[index]: windows[edge.to - events.length - 1],
  };
}

final class _Edge {
  _Edge(this.to, this.reverse, this.capacity, this.cost);
  final int to;
  final int reverse;
  int capacity;
  final int cost;
}
