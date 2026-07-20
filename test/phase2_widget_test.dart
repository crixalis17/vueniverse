import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/data/demo/demo_content.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/main.dart';

void main() {
  testWidgets('switching Demo to Live clears Demo insight and experiments', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const VueniverseApp(initialMode: AppMode.demo, initialOnboarded: true),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
      findsOneWidget,
    );

    final state = VueniverseScope.of(tester.element(find.text('Today').first));
    state.setMode(AppMode.live);
    await tester.pumpAndSettle();

    expect(state.observeDashboard.isDemo, isFalse);
    expect(state.finding, isNull);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('What stands out'), findsNothing);
    expect(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
      findsNothing,
    );
    expect(
      find.text('What Vueniverse needs before it can compare'),
      findsOneWidget,
    );

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    expect(find.text('Review proposed test'), findsNothing);
    expect(find.text('What-if Lab'), findsNothing);
    expect(
      find.text('What Vueniverse needs before it can compare'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Live mode never presents Demo findings experiments or receipts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        VueniverseApp(
          initialMode: AppMode.live,
          initialOnboarded: true,
          initialSources: _liveSources(),
          initialCheckIns: const [],
          initialObserveDashboard: seedObserveDashboard,
          initialFinding: _supportedFinding(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What stands out'), findsNothing);
      expect(find.text('No Live finding yet'), findsNothing);
      expect(find.text('View source data'), findsNothing);
      expect(find.text('No check-ins yet'), findsNothing);
      expect(find.text('Add a check-in'), findsOneWidget);
      expect(
        find.text(
          'Your heart rate was usually higher before your recurring 1:1.',
        ),
        findsNothing,
      );

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No Live history yet'), findsOneWidget);
      expect(find.text('Snapshot scenario library'), findsNothing);

      await tester.tap(find.text('Experiments'));
      await tester.pumpAndSettle();
      expect(
        find.text('What Vueniverse needs before it can compare'),
        findsOneWidget,
      );
      expect(find.text('Usable repeats'), findsOneWidget);
      expect(find.text('0 of 4'), findsNWidgets(2));
      expect(find.text('0% of 75%'), findsOneWidget);
      expect(find.text('No experiment is ready'), findsNothing);
      expect(find.text('Review proposed test'), findsNothing);
      expect(find.text('How results are described'), findsNothing);
      expect(find.text('What-if Lab'), findsNothing);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proof & exports'));
      await tester.pumpAndSettle();
      expect(find.text('NO LIVE RECEIPT'), findsOneWidget);
      expect(find.text('Recurring 1:1 evidence receipt'), findsNothing);
    },
  );

  testWidgets('Live readiness shows actual progress without forcing insight', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialSources: _liveSources(),
        initialCheckIns: const [],
        initialObserveDashboard: _liveDashboardWithInputs(),
        initialFinding: _developingFinding(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What stands out'), findsNothing);
    expect(find.text('More comparable data is needed'), findsOneWidget);
    expect(find.text('2 of 4'), findsOneWidget);
    expect(find.text('3 of 4'), findsOneWidget);
    expect(find.text('60% of 75%'), findsOneWidget);

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    expect(find.text('More comparable data is needed'), findsOneWidget);
    expect(find.text('Review proposed test'), findsNothing);
    expect(find.text('What-if Lab'), findsNothing);
  });

  testWidgets('Live refresh reveals insight only after data and inference', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var resumed = false;
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialSources: _liveSources(),
        initialCheckIns: const [],
        onAppResumed: () async => resumed = true,
        onObserveReload: () async => _liveDashboardWithInputs(),
        onFindingReload: () async => _supportedFinding(),
      ),
    );
    await tester.pumpAndSettle();

    expect(resumed, isTrue);
    expect(find.text('What stands out'), findsOneWidget);
    expect(
      find.text('What Vueniverse needs before it can compare'),
      findsNothing,
    );

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    expect(find.text('Review proposed test'), findsOneWidget);
  });

  testWidgets('source details expose a single action for the current state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var connectRequested = false;
    var sources = _liveSources();
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialSources: sources,
        initialCheckIns: const [],
        onSourceAction: (id, action) async {
          if (id == 'health' && action == SourceAction.connect) {
            connectRequested = true;
            sources = [
              for (final source in sources)
                source.id == 'health'
                    ? source.copyWith(status: SourceStatus.syncing)
                    : source,
            ];
          }
        },
        onSourcesReload: () async => sources,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage sources'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health Connect'));
    await tester.pumpAndSettle();
    expect(find.text('PERMISSION REQUIRED'), findsOneWidget);
    expect(find.text('Connect Health Connect'), findsOneWidget);
    await tester.tap(find.text('Connect Health Connect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(connectRequested, isTrue);
    expect(find.text('SYNCING'), findsOneWidget);
  });

  testWidgets('Calendar review categorizes transient titles before saving', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Map<String, String>? saved;
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialSources: _liveSources(),
        initialCheckIns: const [],
        onCalendarDiscovery: () async => const [
          CalendarSeriesData(
            transientId: 'raw-series-id',
            title: 'Private weekly title',
            recurrenceRule: 'FREQ=WEEKLY',
            timeZone: 'Asia/Kolkata',
          ),
        ],
        onCalendarReview: (reviewed) async => saved = reviewed,
        onSourcesReload: () async => _liveSources(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage sources'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review recurring series'));
    await tester.pumpAndSettle();
    expect(find.text('Private weekly title'), findsOneWidget);
    expect(find.textContaining('title only on this screen'), findsOneWidget);

    await tester.tap(find.byTooltip('Choose category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recurring 1:1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save 1 reviewed series'));
    await tester.pumpAndSettle();
    expect(saved, {'raw-series-id': 'recurring_one_to_one'});
  });

  testWidgets('Manual Check-ins can be edited and deleted', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CheckInData? saved;
    String? deleted;
    final checkIn = CheckInData(
      id: 'checkin-1',
      when: DateTime(2026, 7, 16, 8),
      context: 'Caffeine check-in',
      detail: 'One coffee',
      icon: Icons.coffee_outlined,
      category: 'caffeine',
    );
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialSources: _liveSources(),
        initialCheckIns: [checkIn],
        onCheckInSaved: (value) async => saved = value,
        onCheckInDeleted: (id) async => deleted = id,
      ),
    );
    await tester.pumpAndSettle();

    final checkInRow = find.text('Caffeine check-in');
    await tester.scrollUntilVisible(
      checkInRow,
      280,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(checkInRow);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Two coffees');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved?.detail, 'Two coffees');

    await tester.scrollUntilVisible(
      checkInRow,
      280,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(checkInRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete check-in'));
    await tester.pumpAndSettle();
    expect(deleted, 'checkin-1');
    expect(find.text('Caffeine check-in'), findsNothing);
  });
}

List<SourceData> _liveSources() => [
  seedSources[0].copyWith(
    status: SourceStatus.permissionRequired,
    recordCount: 0,
    permissionsGranted: 0,
    permissionsTotal: 6,
  ),
  seedSources[1].copyWith(
    status: SourceStatus.permissionRequired,
    recordCount: 0,
    permissionsGranted: 0,
    permissionsTotal: 1,
  ),
  seedSources[2].copyWith(status: SourceStatus.connectedEmpty, recordCount: 0),
  seedSources[3].copyWith(status: SourceStatus.available),
];

FindingData _supportedFinding() => FindingData(
  status: 'supported',
  title: 'Previously supported result',
  evidenceHash: 'old-live-evidence',
  evidenceVersion: 'old-live-v1',
  candidateCount: 8,
  includedCount: 6,
  controlsCount: 8,
  positiveCount: 5,
  counterevidenceCount: 1,
  medianDifferenceBpm: 7,
  effectLowerBpm: 4,
  effectUpperBpm: 10,
  completeness: .9,
  recoveryDurationMinutes: 30,
  unresolvedInfluenceCount: 1,
  createdAt: DateTime.utc(2026, 7, 17),
);

FindingData _developingFinding() => FindingData(
  status: 'developing',
  title: 'Developing result',
  evidenceHash: 'developing-live-evidence',
  evidenceVersion: 'developing-live-v1',
  candidateCount: 5,
  includedCount: 2,
  controlsCount: 3,
  positiveCount: 2,
  counterevidenceCount: 0,
  medianDifferenceBpm: 6,
  effectLowerBpm: 5,
  effectUpperBpm: 7,
  completeness: .6,
  recoveryDurationMinutes: 25,
  unresolvedInfluenceCount: 1,
  createdAt: DateTime.utc(2026, 7, 17),
);

ObserveDashboardData _liveDashboardWithInputs() {
  final rangeEnd = DateTime(2026, 7, 17);
  final rangeStart = rangeEnd.subtract(const Duration(days: 29));
  return ObserveDashboardData(
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    asOf: DateTime(2026, 7, 17, 12),
    isDemo: false,
    days: List.unmodifiable([
      for (var index = 0; index < 30; index++)
        ObserveDayData(
          day: rangeStart.add(Duration(days: index)),
          heartRateMedianBpm: index >= 25 ? 72 : null,
          sleepMinutes: null,
          steps: null,
          eventCount: index >= 25 ? 1 : 0,
          checkInCount: 0,
          recordCount: index >= 25 ? 2 : 0,
        ),
    ]),
    recentActivity: const [],
    heartRateRecords: 120,
    hrvRecords: 0,
    stepRecords: 0,
    sleepRecords: 0,
    workoutRecords: 0,
    activityRecords: 0,
    eventRecords: 5,
    checkInRecords: 0,
  );
}
