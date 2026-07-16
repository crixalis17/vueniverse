import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/demo/demo_content.dart';
import 'package:why_pulse/domain/models/app_models.dart';
import 'package:why_pulse/main.dart';

void main() {
  testWidgets(
    'Live mode never presents Demo findings experiments or receipts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        WhyPulseApp(
          initialMode: AppMode.live,
          initialOnboarded: true,
          initialSources: _liveSources(),
          initialCheckIns: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Live finding yet'), findsOneWidget);
      expect(
        find.text(
          'Your heart rate was usually higher before your recurring 1:1.',
        ),
        findsNothing,
      );

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No Live history yet'), findsOneWidget);
      expect(find.text('Demo evidence cases'), findsNothing);

      await tester.tap(find.text('Experiments'));
      await tester.pumpAndSettle();
      expect(find.text('No experiment is ready'), findsOneWidget);
      expect(find.text('Review proposed test'), findsNothing);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proof & exports'));
      await tester.pumpAndSettle();
      expect(find.text('NO LIVE RECEIPT'), findsOneWidget);
      expect(find.text('Recurring 1:1 evidence receipt'), findsNothing);
    },
  );

  testWidgets('source details expose a single action for the current state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var connectRequested = false;
    var sources = _liveSources();
    await tester.pumpWidget(
      WhyPulseApp(
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
      WhyPulseApp(
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
      WhyPulseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialSources: _liveSources(),
        initialCheckIns: [checkIn],
        onCheckInSaved: (value) async => saved = value,
        onCheckInDeleted: (id) async => deleted = id,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Caffeine check-in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Two coffees');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved?.detail, 'Two coffees');

    await tester.tap(find.text('Caffeine check-in'));
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
