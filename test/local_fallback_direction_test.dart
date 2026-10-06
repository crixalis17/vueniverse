import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final delta in [-10.0, 10.0]) {
    test(
      'local backup preserves signed difference $delta without direction counts',
      () async {
        final state = VueniverseState(
          initialMode: AppMode.demo,
          initialOnboarded: true,
          initialFinding: FindingData(
            status: 'supported',
            title: 'Fixture repeated moment',
            evidenceHash: 'fixture-hash',
            evidenceVersion: 'fixture-version',
            candidateCount: 4,
            includedCount: 4,
            controlsCount: 4,
            positiveCount: delta > 0 ? 4 : 0,
            counterevidenceCount: 0,
            medianDifferenceBpm: delta,
            effectLowerBpm: delta.abs(),
            effectUpperBpm: delta.abs(),
            completeness: 1,
            recoveryDurationMinutes: 0,
            unresolvedInfluenceCount: 0,
            createdAt: DateTime.utc(2026, 9, 20),
          ),
        );
        addTearDown(state.dispose);
        await state.loadExplanation();
        final output = state.currentExplanation!;
        expect(output.deterministicFallback, isTrue);
        expect(
          output.summary,
          'Across 4 meetings we could fairly compare, the usual heart-rate difference was ${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)} beats per minute.',
        );
        expect(output.summary, isNot(contains('same pattern in')));
        expect(
          output.paragraphs.first.citations,
          isNot(contains('positive_count')),
        );
      },
    );
  }
}
