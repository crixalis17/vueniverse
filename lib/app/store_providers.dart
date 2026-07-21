import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vueniverse/data/store/store_coordinator.dart';
import 'package:vueniverse/domain/store_kind.dart';

final storeCoordinatorProvider = Provider<StoreCoordinator>((ref) {
  throw StateError(
    'StoreCoordinator must be overridden at application startup.',
  );
});

final storeSessionProvider =
    AsyncNotifierProvider<StoreSessionNotifier, RepositoryGraph>(
      StoreSessionNotifier.new,
    );

final class StoreSessionNotifier extends AsyncNotifier<RepositoryGraph> {
  bool _operationInProgress = false;

  StoreCoordinator get _coordinator => ref.read(storeCoordinatorProvider);

  @override
  Future<RepositoryGraph> build() async {
    ref.onDispose(_coordinator.dispose);
    return _coordinator.initialize();
  }

  Future<void> switchTo(StoreKind kind) async {
    await _run(() => _coordinator.switchTo(kind));
  }

  Future<void> resetDemo() async {
    await _run(_coordinator.resetDemo);
  }

  Future<void> recoverLiveByDeleting() async {
    await _run(() async {
      await _coordinator.deleteLive();
      return _coordinator.switchTo(StoreKind.live);
    });
  }

  Future<void> retry() async {
    await _run(_coordinator.initialize);
  }

  Future<void> _run(Future<RepositoryGraph> Function() operation) async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    try {
      state = AsyncData(await operation());
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _operationInProgress = false;
    }
  }
}
