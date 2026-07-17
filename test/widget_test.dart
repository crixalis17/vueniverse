import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/domain/models/app_models.dart';
import 'package:why_pulse/main.dart';
import 'package:why_pulse/platform/generated/model_download_api.g.dart';

ModelDownloadStatus modelDownloadStatus(
  ModelDownloadState state, {
  int downloadedBytes = 0,
  double progress = 0,
  bool? retryable,
  String? detail,
}) => ModelDownloadStatus(
  state: state,
  downloadedBytes: downloadedBytes,
  totalBytes: 2489894144,
  progress: progress,
  retryable:
      retryable ??
      (state == ModelDownloadState.failed ||
          state == ModelDownloadState.cancelled),
  detail: detail,
);

Future<void> enterDemo(WidgetTester tester) async {
  await tester.pumpWidget(const WhyPulseApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('See how it works'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Explore Demo Data'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {});

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
    expect(find.text('DEMO'), findsWidgets);
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
      WhyPulseApp(
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

    expect(find.text('Choose what WhyPulse can use.'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Android Calendar'), findsOneWidget);
    expect(find.text('Manual check-ins'), findsOneWidget);
    expect(find.text('Demo Data'), findsOneWidget);

    final continueButton = find.text('Continue with selected sources');
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
    expect(find.text('LIVE'), findsOneWidget);
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
      WhyPulseApp(
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
      find.text('Continue with selected sources'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue with selected sources'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('This build has no model URL'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('This build has no model URL'), findsOneWidget);
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
      WhyPulseApp(
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
      WhyPulseApp(
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
    await tester.tap(find.text('Demo Data').first);
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
    expect(find.text('LIVE'), findsWidgets);
  });

  testWidgets('current Live evidence is visible on Today and Proof', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      WhyPulseApp(
        initialMode: AppMode.live,
        initialOnboarded: true,
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
    expect(find.text('Control what evidence WhyPulse can use'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Android Calendar'), findsOneWidget);
    expect(find.text('Manual check-ins'), findsOneWidget);
    expect(find.text('Demo Data'), findsOneWidget);
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

  testWidgets('core evidence journey reaches bounded Ask WhyPulse', (
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
    expect(find.text('Moment Fingerprint'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Repeated trace chart with 6 included meetings'),
      ),
      findsOneWidget,
    );

    final challenge = find.text('Challenge the evidence');
    await tester.scrollUntilVisible(
      challenge,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(challenge);
    await tester.pumpAndSettle();
    expect(find.text('Challenge the recurring 1:1 finding'), findsOneWidget);

    final influences = find.text('Review influences');
    await tester.scrollUntilVisible(
      influences,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(influences);
    await tester.pumpAndSettle();
    expect(find.text('Correct the context used by evidence'), findsOneWidget);
    expect(find.text('Add influence'), findsOneWidget);
    await tester.tap(find.text('Add influence'));
    await tester.pumpAndSettle();
    expect(find.text('What context matters right now?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final explain = find.text('Explain this evidence');
    await tester.scrollUntilVisible(
      explain,
      420,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explain);
    await tester.pumpAndSettle();
    expect(find.text('Bounded to this evidence bundle'), findsOneWidget);

    final ask = find.text('Ask about this evidence');
    await tester.scrollUntilVisible(
      ask,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(ask);
    await tester.pumpAndSettle();
    expect(find.text('Ask WhyPulse'), findsOneWidget);

    await tester.tap(find.text('What evidence is missing?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Evidence completeness is 86 percent'),
      findsOneWidget,
    );
  });

  testWidgets('Ask WhyPulse is directly discoverable from Today', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    final askEntry = find.bySemanticsLabel(
      'Ask WhyPulse about the recurring 1:1 evidence',
    );
    await tester.scrollUntilVisible(
      askEntry,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(askEntry);
    await tester.pumpAndSettle();

    expect(find.text('Recurring 1:1 evidence only'), findsOneWidget);
    await tester.tap(find.text('What evidence is missing?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Evidence completeness is 86 percent'),
      findsOneWidget,
    );
  });

  testWidgets('history exposes lifecycle and deterministic evidence cases', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-380, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weakened'));
    await tester.pumpAndSettle();
    expect(find.text('Late meetings and sleep duration'), findsOneWidget);
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

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
      await tester.pumpAndSettle();
    }

    final demoCases = find.text('Demo evidence cases');
    expect(demoCases, findsOneWidget);
    await tester.ensureVisible(demoCases);
    await tester.pumpAndSettle();
    await tester.tap(demoCases);
    await tester.pumpAndSettle();

    expect(find.text('Supported repeated pattern'), findsOneWidget);
    expect(find.text('Null finding'), findsOneWidget);
    expect(find.text('Contradictory evidence'), findsOneWidget);
    expect(find.text('Missing-data result'), findsOneWidget);

    await tester.tap(find.text('Contradictory evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Promotion stopped'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final missing = find.text('Missing-data result');
    await tester.scrollUntilVisible(
      missing,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(missing);
    await tester.pumpAndSettle();
    expect(find.text('Evidence gate not reached'), findsOneWidget);
  });

  testWidgets('experiment result gallery covers all four outcome states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    final resultCases = find.text('Deterministic result cases');
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
    expect(find.text('Evidence gate not reached'), findsOneWidget);
  });

  testWidgets('experiment can start and record an eligible occurrence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review proposed test'));
    await tester.pumpAndSettle();

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
    expect(find.text('1/3 eligible meetings'), findsOneWidget);
  });

  testWidgets('restored experiment exposes pause resume cancel and stop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var paused = true;
    var stopped = false;
    await tester.pumpWidget(
      WhyPulseApp(
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

  testWidgets('proof, previews and expansion remain honestly labelled', (
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
    final integrity = find.text('INTEGRITY HASH');
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

    final previewLab = find.text('Preview Lab');
    await tester.scrollUntilVisible(
      previewLab,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(previewLab);
    await tester.pumpAndSettle();
    expect(find.text('Weekly Digest'), findsOneWidget);
    expect(find.text('What-if Lab'), findsOneWidget);
    await tester.tap(find.text('Weekly Digest'));
    await tester.pumpAndSettle();
    expect(find.text('Your week in evidence'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('What-if Lab'));
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW · SIMULATION'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final expansion = find.text('Expansion');
    await tester.scrollUntilVisible(
      expansion,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(expansion);
    await tester.pumpAndSettle();
    expect(
      find.text('Future capabilities · no unfinished integrations'),
      findsOneWidget,
    );
    expect(find.text('LATER'), findsWidgets);
    expect(find.text('Connect'), findsNothing);
  });
}
