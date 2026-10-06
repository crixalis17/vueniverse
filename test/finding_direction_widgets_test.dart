import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/features/vueniverse_screens.dart';

void main() {
  for (final delta in [-10.0, 10.0, 0.0]) {
    testWidgets('dynamic finding views faithfully present signed difference $delta', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final finding = _finding(delta);
      final state = VueniverseState(
        initialMode: AppMode.demo,
        initialOnboarded: true,
        initialFinding: finding,
      );
      addTearDown(state.dispose);
      Future<void> show(Widget page) async {
        await tester.pumpWidget(
          VueniverseScope(
            state: state,
            child: MaterialApp(home: page),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(
        Scaffold(
          body: PrimaryInsightCard(onTap: () {}, finding: finding),
        ),
      );
      final headline = delta == 0
          ? 'Your heart rate showed no usual difference before your recurring 1:1.'
          : 'Your heart rate was usually ${delta < 0 ? 'lower' : 'higher'} before your recurring 1:1.';
      expect(find.text(headline), findsOneWidget);
      expect(find.text('MEETINGS COMPARED'), findsOneWidget);
      expect(find.text('SHOWED PATTERN'), findsNothing);
      expect(find.textContaining('0 of 4 meetings'), findsNothing);

      await show(const MomentFingerprintScreen());
      final fingerprint = delta == 0
          ? 'In the 15 minutes before these meetings, heart rate showed no usual difference from similar times with no meeting.'
          : 'In the 15 minutes before these meetings, heart rate was usually ${delta < 0 ? 'lower' : 'higher'} than at similar times with no meeting.';
      expect(find.text(fingerprint), findsOneWidget);
      expect(find.text('MEETINGS COMPARED'), findsOneWidget);
      expect(find.textContaining('30 minutes before'), findsNothing);
      expect(find.textContaining('0 of the remaining'), findsNothing);

      await show(const EvidenceScreen());
      final rangeMeaning = delta == 0
          ? 'No range of larger differences in the usual direction is available'
          : 'Absolute differences of at least 5 bpm in the usual direction, not a confidence interval';
      await tester.scrollUntilVisible(find.text(rangeMeaning), 300);
      expect(find.text('MEETINGS COMPARED'), findsOneWidget);
      expect(find.text('MEETINGS SHOWING THE PATTERN'), findsNothing);
      expect(find.text(rangeMeaning), findsOneWidget);

      await show(const WeeklyDigestScreen());
      final signed = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}';
      expect(
        find.text(
          'Across 4 meetings we could fairly compare, the usual heart-rate difference was $signed beats per minute.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('0 of 4 meetings'), findsNothing);
    });
  }
  testWidgets('developing history does not invent a scarce-comparison reason', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FindingStatusScreen(
          item: HistoryItemData(
            id: 'context-blocked',
            title: 'Fixture unresolved caffeine context',
            subtitle: '4 complete comparisons remain tentative',
            date: 'September 20',
            status: 'Developing',
            icon: Icons.help_outline,
            accent: Colors.blue,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This comparison remains tentative while evidence or context checks are unresolved.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('more similar events are needed'), findsNothing);
  });
}

FindingData _finding(double delta) => FindingData(
  // Zero is a defensive rendering check, not an analytically promoted pattern.
  status: 'supported',
  title: 'Fixture recurring 1:1 and heart rate',
  evidenceHash: 'fixture-evidence-hash',
  evidenceVersion: 'fixture-finding-v1',
  candidateCount: 4,
  includedCount: 4,
  controlsCount: 4,
  positiveCount: delta > 0 ? 4 : 0,
  counterevidenceCount: delta == 0 ? 4 : 0,
  medianDifferenceBpm: delta,
  effectLowerBpm: delta.abs(),
  effectUpperBpm: delta.abs(),
  completeness: 1,
  recoveryDurationMinutes: 0,
  unresolvedInfluenceCount: 0,
  createdAt: DateTime.utc(2026, 9, 20),
);
