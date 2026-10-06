import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/features/vueniverse_screens.dart';
import 'package:vueniverse/main.dart';
import 'package:vueniverse/platform/generated/model_download_api.g.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

ModelDownloadStatus modelDownloadStatus(
  ModelDownloadState state, {
  int downloadedBytes = 0,
  double progress = 0,
  bool? retryable,
  String? detail,
}) => ModelDownloadStatus(
  state: state,
  downloadedBytes: downloadedBytes,
  totalBytes: 2489894976,
  progress: progress,
  retryable:
      retryable ??
      (state == ModelDownloadState.failed ||
          state == ModelDownloadState.cancelled),
  detail: detail,
);

ObserveDashboardData liveObserveDashboardWithEvidence() {
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
          heartRateMedianBpm: index >= 24 ? 72 : null,
          sleepMinutes: null,
          steps: null,
          eventCount: index >= 24 ? 1 : 0,
          checkInCount: 0,
          recordCount: index >= 24 ? 2 : 0,
        ),
    ]),
    recentActivity: const [],
    heartRateRecords: 240,
    hrvRecords: 0,
    stepRecords: 0,
    sleepRecords: 0,
    workoutRecords: 0,
    activityRecords: 0,
    eventRecords: 6,
    checkInRecords: 0,
  );
}

Future<void> enterDemo(WidgetTester tester) async {
  await tester.pumpWidget(const VueniverseApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('See how it works'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Explore Snapshot'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {});

  testWidgets('explanation shows truthful MedGemma inference progress', (
    tester,
  ) async {
    final completion = Completer<ExplanationData?>();
    final state = VueniverseState(
      initialOnboarded: true,
      onExplanationRequested: (intent, preferCache, onProgress) {
        onProgress(
          const InferenceProgress(
            stage: InferenceProgressStage.runningInference,
            runtime: InferenceRuntime.phoneMedGemma,
          ),
        );
        return completion.future;
      },
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: VueniverseScope(state: state, child: const ExplanationScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('MedGemma is thinking on this phone…'), findsOneWidget);
    expect(find.text('Run MedGemma privately on this phone'), findsOneWidget);
    expect(
      find.text(
        'This shows the processing steps, not private model reasoning.',
      ),
      findsOneWidget,
    );

    completion.complete(
      ExplanationData(
        summary: 'A checked model explanation.',
        paragraphs: const [
          ExplanationParagraphData(
            text: 'A checked model explanation.',
            citations: ['included_count'],
          ),
        ],
        uncertainty: 'This does not prove why the pattern happened.',
        runtimeLabel: 'Explained privately on this phone',
        deterministicFallback: false,
        fromCache: false,
        createdAt: DateTime.utc(2026, 7, 19),
        modelName: 'google/medgemma-1.5-4b-it-Q4_K_M',
        latencyMillis: 1420,
        nextObservation:
            'Test a 10-minute quiet buffer before the next three eligible recurring 1:1 meetings.',
        possibleContributorIds: const [
          'caffeine_timing',
          'recent_exercise',
          'unusual_stress',
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What happened'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Possible contributors — not proven causes'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Caffeine timing'), findsOneWidget);
    expect(find.text('Recent exercise'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Test this pattern'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Review full 3-meeting plan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('MedGemma 1.5 4B'),
      360,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('MedGemma 1.5 4B'), findsOneWidget);
    expect(find.text('1.4 seconds'), findsOneWidget);
    expect(find.text('Model answer matched the current data'), findsOneWidget);
  });

  testWidgets('onboarding enters the four-destination evidence experience', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await enterDemo(tester);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Experiments'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
      findsOneWidget,
    );
    expect(find.text('Snapshot is ready'), findsOneWidget);
    expect(find.text('30 days loaded · encrypted locally'), findsOneWidget);
  });

  testWidgets('Demo exposes an ordered video tour through the evidence loop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    final tour = find.text('Run the guided Snapshot');
    await tester.scrollUntilVisible(
      tour,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    // Ensure the scroll's final layout is painted before deriving tap bounds.
    await tester.pumpAndSettle();
    expect(tour.hitTestable(), findsOneWidget);
    await tester.tap(tour.hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('58-SECOND APP PATH'), findsOneWidget);
    expect(find.text('Tell one complete evidence story'), findsOneWidget);
    expect(find.text('Establish data trust'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reveal the repeated moment'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Reveal the repeated moment'), findsOneWidget);

    final completedResult = find.text('Open completed result');
    await tester.scrollUntilVisible(
      completedResult,
      420,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(completedResult);
    await tester.pumpAndSettle();
    expect(find.text('Show the measured result'), findsOneWidget);
    await tester.tap(completedResult);
    await tester.pumpAndSettle();
    expect(find.text('STRENGTHENED · SNAPSHOT'), findsOneWidget);
    expect(find.text('Recovery was 9 minutes faster.'), findsOneWidget);
    expect(find.text('54 min'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final proof = find.text('Open Proof & Export');
    await tester.scrollUntilVisible(
      proof,
      420,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('End with the receipt'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Optional outcome montage'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Optional outcome montage'), findsOneWidget);
  });

  testWidgets('Ask shows a working cancellation control during inference', (
    tester,
  ) async {
    final completion = Completer<ExplanationData?>();
    var cancelled = false;
    final state = VueniverseState(
      initialOnboarded: true,
      onAskRequested: (question, intent, onProgress) => completion.future,
      onExplanationCancel: () async => cancelled = true,
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: VueniverseScope(state: state, child: const AskVueniverseScreen()),
      ),
    );

    await tester.tap(find.text('Which meetings do not match?'));
    await tester.pump();
    expect(find.text('Cancel answer'), findsOneWidget);
    await tester.tap(find.text('Cancel answer'));
    await tester.pump();
    expect(cancelled, isTrue);
    expect(find.text('Cancel answer'), findsNothing);

    completion.complete(null);
    await tester.pumpAndSettle();
    expect(state.askInProgress, isFalse);
    expect(state.chatMessages, hasLength(1));
  });

  testWidgets('new Demo check-ins use the fixture clock', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = VueniverseState(
      initialOnboarded: true,
      initialCheckIns: const [],
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: VueniverseScope(state: state, child: const CheckInScreen()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Save check-in'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save check-in'));
    await tester.pumpAndSettle();

    expect(state.checkIns, hasLength(1));
    expect(state.checkIns.single.when, state.observeDashboard.asOf);
  });

  testWidgets('live onboarding includes source preparation as a product step', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final consent = modelDownloadStatus(ModelDownloadState.requiresConsent);
    final queued = modelDownloadStatus(
      ModelDownloadState.queued,
      detail: 'waiting_for_unmetered_network',
    );
    await tester.pumpWidget(
      VueniverseApp(
        initialModelDownloadStatus: consent,
        onModelDownloadInspect: () async => consent,
        onModelDownloadAcceptAndStart: () async => queued,
        onModelDownloadEnsureScheduled: () async => queued,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('See how it works'));
    await tester.pumpAndSettle();
    final liveSetup = find.text('Continue to Sources');
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(liveSetup);
    await tester.pumpAndSettle();

    expect(find.text('Choose what Vueniverse can use.'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Android Calendar'), findsOneWidget);
    expect(find.text('Manual check-ins'), findsOneWidget);
    expect(find.text('Snapshot'), findsOneWidget);

    final continueButton = find.text('Review on-device AI');
    await tester.scrollUntilVisible(
      continueButton,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Prepare private on-device explanations.'),
      findsOneWidget,
    );
    expect(find.textContaining('2.49 GB MedGemma'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(find.text('Disable'), findsNothing);

    final downloadButton = find.text('Download model');
    await tester.scrollUntilVisible(
      downloadButton,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(downloadButton);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('missing model configuration blocks Live onboarding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final missing = modelDownloadStatus(
      ModelDownloadState.notConfigured,
      retryable: false,
      detail: 'configuration_missing',
    );
    await tester.pumpWidget(
      VueniverseApp(
        initialModelDownloadStatus: missing,
        onModelDownloadInspect: () async => missing,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('See how it works'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continue to Sources'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue to Sources'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Review on-device AI'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Review on-device AI'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('missing the download link for the AI model'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.textContaining('missing the download link for the AI model'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Download model'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('LIVE'), findsNothing);
  });

  testWidgets('Settings renders progress and exposes Cancel and Retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var status = modelDownloadStatus(
      ModelDownloadState.downloading,
      downloadedBytes: 1244947072,
      progress: 50,
    );
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialModelDownloadStatus: status,
        onModelDownloadInspect: () async => status,
        onModelDownloadCancel: () async {
          status = modelDownloadStatus(
            ModelDownloadState.cancelled,
            downloadedBytes: 1244947072,
            progress: 50,
            detail: 'download_cancelled',
          );
          return status;
        },
        onModelDownloadRetry: () async {
          status = modelDownloadStatus(
            ModelDownloadState.queued,
            downloadedBytes: 1244947072,
            progress: 50,
            detail: 'waiting_for_unmetered_network',
          );
          return status;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('On-device AI model'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('partial file is saved'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Queued'), findsOneWidget);
  });

  testWidgets('switching Demo to Live presents mandatory model disclosure', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final consent = modelDownloadStatus(ModelDownloadState.requiresConsent);
    final queued = modelDownloadStatus(ModelDownloadState.queued);
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.demo,
        initialOnboarded: true,
        initialModelDownloadStatus: consent,
        onModelDownloadInspect: () async => consent,
        onModelDownloadAcceptAndStart: () async => queued,
        onModelDownloadEnsureScheduled: () async => queued,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change data mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Live evidence'));
    await tester.pumpAndSettle();

    expect(
      find.text('Prepare private on-device explanations.'),
      findsOneWidget,
    );
    expect(find.text('Later'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Download model'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Download model'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('current Live evidence is visible on Today and Proof', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      VueniverseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialObserveDashboard: liveObserveDashboardWithEvidence(),
        initialFinding: FindingData(
          status: 'supported',
          title: 'Live recurring event and heart rate',
          evidenceHash: 'live-evidence-hash',
          evidenceVersion: 'live-finding-v1',
          candidateCount: 9,
          includedCount: 6,
          controlsCount: 9,
          positiveCount: 5,
          counterevidenceCount: 1,
          medianDifferenceBpm: 7,
          effectLowerBpm: 4,
          effectUpperBpm: 10,
          completeness: .9,
          recoveryDurationMinutes: 30,
          unresolvedInfluenceCount: 1,
          createdAt: DateTime.utc(2026, 7, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    expect(find.text('Review proposed test'), findsOneWidget);
    expect(find.text('How results are described'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proof & exports'));
    await tester.pumpAndSettle();
    expect(find.text('LOCAL RECEIPT'), findsOneWidget);
    expect(find.text('live-evidence-hash'), findsOneWidget);
  });

  testWidgets('Sources is a standalone screen in the Observe journey', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.textContaining('Manage sources'));
    await tester.pumpAndSettle();

    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('Control which data Vueniverse can use'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Android Calendar'), findsOneWidget);
    expect(find.text('Manual check-ins'), findsOneWidget);
    expect(find.text('Snapshot'), findsOneWidget);
  });

  testWidgets('Observe presents the complete source dashboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('View source data'));
    await tester.pumpAndSettle();

    expect(find.text('Observe'), findsOneWidget);
    expect(find.text('Your data, in one view'), findsOneWidget);
    expect(find.text('Signals over time'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Steps'));
    await tester.pumpAndSettle();
    expect(find.text('DAILY AVG'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Steps chart with 30 recorded days')),
      findsOneWidget,
    );

    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('Source mix'),
      360,
      scrollable: verticalScrollable,
    );
    expect(find.text('Health signals'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recently observed'),
      320,
      scrollable: verticalScrollable,
    );
    expect(find.text('Recently observed'), findsOneWidget);
  });

  testWidgets('core evidence journey reaches bounded Ask Vueniverse', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pattern detail'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Heart-rate chart with 8 meetings')),
      findsOneWidget,
    );

    final challenge = find.text('Review the data');
    await tester.scrollUntilVisible(
      challenge,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(challenge);
    await tester.pumpAndSettle();
    expect(find.text('Review the recurring 1:1 pattern'), findsOneWidget);

    final influences = find.text('Review missing context');
    await tester.scrollUntilVisible(
      influences,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(influences);
    await tester.pumpAndSettle();
    expect(find.text('Check the details used in this pattern'), findsOneWidget);
    expect(find.text('Add context'), findsOneWidget);
    await tester.tap(find.text('Add context'));
    await tester.pumpAndSettle();
    expect(find.text('What context matters right now?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('How were meetings compared?'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byType(ExpansionTile), findsNothing);

    final explain = find.text('Explain this pattern');
    await tester.scrollUntilVisible(
      explain,
      420,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explain);
    await tester.pumpAndSettle();
    expect(find.text('USES ONLY THIS PATTERN’S DATA'), findsOneWidget);
    expect(find.text('Data used for this answer'), findsOneWidget);
    expect(find.text('Meetings compared'), findsOneWidget);
    expect(find.text('Usual heart-rate difference'), findsOneWidget);

    final ask = find.text('Ask about this pattern');
    await tester.scrollUntilVisible(
      ask,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(ask);
    await tester.pumpAndSettle();
    expect(find.text('Ask Vueniverse'), findsOneWidget);

    await tester.tap(find.text('What data is missing?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('100% of the needed data is available'),
      findsOneWidget,
    );
  });

  testWidgets('Ask Vueniverse is directly discoverable from Today', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    final askEntry = find.bySemanticsLabel(
      'Ask Vueniverse about the recurring 1:1 pattern',
    );
    await tester.scrollUntilVisible(
      askEntry,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(askEntry);
    await tester.pumpAndSettle();

    expect(find.text('THIS PATTERN ONLY'), findsOneWidget);
    await tester.tap(find.text('What data is missing?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('100% of the needed data is available'),
      findsOneWidget,
    );
  });

  testWidgets('history exposes result states and example cases', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-380, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-260, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weakened'));
    await tester.pumpAndSettle();
    expect(find.text('Late meetings and sleep duration'), findsOneWidget);
    await tester.tap(find.text('Late meetings and sleep duration'));
    await tester.pumpAndSettle();
    expect(find.text('Analysis / provenance'), findsOneWidget);
    expect(find.text('Seeded Snapshot lifecycle receipt'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expired'));
    await tester.pumpAndSettle();
    expect(find.text('Travel-day recovery pattern'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await enterDemo(tester);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
      await tester.pumpAndSettle();
    }

    final demoCases = find.text('Snapshot scenario library');
    expect(demoCases, findsOneWidget);
    await tester.ensureVisible(demoCases);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 180));
    await tester.pumpAndSettle();
    final demoCasesCard = find.ancestor(
      of: demoCases,
      matching: find.byType(InkWell),
    );
    expect(demoCasesCard, findsOneWidget);
    tester.widget<InkWell>(demoCasesCard).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('16 Snapshot scenarios'), findsOneWidget);
    expect(find.text('Recurring 1:1 and heart rate'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Two meetings stayed near baseline'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Two meetings stayed near baseline'), findsOneWidget);

    final missing = find.text('Travel-confounded meeting');
    await tester.scrollUntilVisible(
      missing,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(missing);
    await tester.pumpAndSettle();
    await tester.tap(missing);
    await tester.pumpAndSettle();
    expect(find.text('No usable comparison remained'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final weakened = find.text('Late meetings and sleep duration');
    await tester.scrollUntilVisible(
      weakened,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(weakened);
    await tester.pumpAndSettle();
    expect(weakened, findsOneWidget);
    await tester.tap(weakened);
    await tester.pumpAndSettle();
    expect(find.text('The older conclusion became weaker'), findsOneWidget);
  });

  testWidgets('experiment result gallery covers all four outcome states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    final resultCases = find.text('See every possible result');
    await tester.scrollUntilVisible(
      resultCases,
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(resultCases);
    await tester.pumpAndSettle();

    expect(find.text('Strengthened'), findsOneWidget);
    expect(find.text('Weakened'), findsOneWidget);
    expect(find.text('Unchanged'), findsOneWidget);
    expect(find.text('Inconclusive'), findsOneWidget);

    final inconclusive = find.text('Inconclusive');
    await tester.scrollUntilVisible(
      inconclusive,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(inconclusive);
    await tester.pumpAndSettle();
    expect(
      find.text('There is not enough complete evidence to resolve the test.'),
      findsOneWidget,
    );
    expect(
      find.text('Not enough complete data for a fair result'),
      findsOneWidget,
    );
    expect(
      find.text(
        'One planned change was skipped even though the meeting occurred, and another occurrence lacked enough heart-rate coverage. Vueniverse will not force a conclusion.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('experiment can start and record an eligible occurrence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var occurrenceCalls = 0;
    await tester.pumpWidget(
      VueniverseApp(
        initialOnboarded: true,
        onExperimentStart: () async {},
        onExperimentOccurrence: (note) async {
          expect(note, isNotEmpty);
          occurrenceCalls += 1;
          if (occurrenceCalls > 1) {
            throw StateError('The next scheduled meeting is not due.');
          }
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review proposed test'));
    await tester.pumpAndSettle();

    expect(find.text('Your 3-meeting plan'), findsOneWidget);
    expect(find.text('Post-meeting recovery time'), findsOneWidget);
    expect(find.text('Matched earlier recurring 1:1 meetings'), findsOneWidget);

    final consent = find.text(
      'I understand this is a personal test, not treatment.',
    );
    await tester.scrollUntilVisible(
      consent,
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(consent);
    await tester.pumpAndSettle();
    final start = find.text('Start 3-meeting experiment');
    await tester.scrollUntilVisible(
      start,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(find.text('0/3 eligible meetings'), findsOneWidget);
    await tester.tap(find.text('Complete occurrence check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I completed the 10-minute quiet buffer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save occurrence'));
    await tester.pumpAndSettle();
    expect(find.text('1/3 eligible meetings'), findsOneWidget);
    await tester.tap(find.text('Complete occurrence check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I completed the 10-minute quiet buffer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save occurrence'));
    await tester.pumpAndSettle();
    expect(find.text('1/3 eligible meetings'), findsOneWidget);
    expect(
      find.textContaining('Only a due scheduled meeting can be checked in'),
      findsOneWidget,
    );
  });

  testWidgets('restored experiment exposes pause resume cancel and stop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var paused = true;
    var stopped = false;
    await tester.pumpWidget(
      VueniverseApp(
        initialOnboarded: true,
        initialExperimentStatus: ExperimentStatus.paused,
        initialExperimentCheckIns: 1,
        onExperimentPauseChanged: (value) async => paused = value,
        onExperimentStop: () async => stopped = true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('1/3 eligible meetings'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Stop early'), findsOneWidget);

    await tester.tap(find.text('Resume experiment'));
    await tester.pumpAndSettle();
    expect(paused, isFalse);
    expect(find.text('ACTIVE'), findsOneWidget);
    await tester.tap(find.text('Pause experiment'));
    await tester.pumpAndSettle();
    expect(paused, isTrue);

    await tester.tap(find.text('Stop early'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Stop early'));
    await tester.pumpAndSettle();
    expect(stopped, isTrue);
    expect(find.text('STOPPED'), findsOneWidget);
  });

  testWidgets('completed protocol does not fabricate an experiment result', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const VueniverseApp(
        initialOnboarded: true,
        initialExperimentStatus: ExperimentStatus.completed,
        initialExperimentCheckIns: 3,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();

    expect(find.text('COMPLETE'), findsOneWidget);
    expect(
      find.textContaining(
        'no result is shown until a deterministic experiment receipt',
      ),
      findsOneWidget,
    );
    expect(find.text('View result'), findsNothing);
  });

  testWidgets('previews stay in their journeys and information stays passive', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proof & exports'));
    await tester.pumpAndSettle();
    expect(find.text('Proof & Export'), findsOneWidget);
    final integrity = find.text('FILE FINGERPRINT');
    await tester.scrollUntilVisible(
      integrity,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(integrity, findsOneWidget);

    final clinician = find.text('Reviewed Clinician Report');
    await tester.scrollUntilVisible(
      clinician,
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(clinician);
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW · SAMPLE DATA'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
      await tester.pumpAndSettle();
    }
    final weeklyDigest = find.text('Weekly Digest');
    expect(weeklyDigest, findsOneWidget);
    await tester.ensureVisible(weeklyDigest);
    await tester.tap(find.text('Weekly Digest'));
    await tester.pumpAndSettle();
    expect(find.text('What your data showed this week'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    final whatIfLab = find.text('What-if Lab');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
    await tester.pumpAndSettle();
    expect(whatIfLab, findsOneWidget);
    await tester.ensureVisible(whatIfLab);
    await tester.tap(whatIfLab);
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW · SIMULATION'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final expansion = find.text('Expansion');
    await tester.scrollUntilVisible(
      expansion,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.textContaining('Screen time · Strava · Spotify'),
      findsOneWidget,
    );
    expect(find.text('LATER'), findsWidgets);
    expect(find.text('Connect'), findsNothing);
    expect(
      find.ancestor(of: expansion, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(find.text('About Vueniverse'), findsOneWidget);
    expect(find.text('Preview Lab'), findsNothing);
  });
}
