import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:why_pulse/app/app_preferences.dart';
import 'package:why_pulse/app/app_state.dart';
import 'package:why_pulse/app/store_providers.dart';
import 'package:why_pulse/app/theme.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/exports/evidence_export_service.dart';
import 'package:why_pulse/data/history/history_repository.dart';
import 'package:why_pulse/data/observe/observe_dashboard_repository.dart';
import 'package:why_pulse/data/replay/moment_replay_repository.dart';
import 'package:why_pulse/data/security/store_security_gateway.dart';
import 'package:why_pulse/data/demo/demo_content.dart';
import 'package:why_pulse/data/store/store_coordinator.dart';
import 'package:why_pulse/data/sources/manual_checkin_repository.dart';
import 'package:why_pulse/data/sources/source_repository.dart';
import 'package:why_pulse/domain/models/app_models.dart';
import 'package:why_pulse/domain/models/experiment_models.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';
import 'package:why_pulse/domain/model_runtime/explanation_coordinator.dart';
import 'package:why_pulse/domain/store_kind.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';
import 'package:why_pulse/platform/generated/model_download_api.g.dart';
import 'package:why_pulse/platform/generated/notification_api.g.dart';
import 'package:why_pulse/features/why_pulse_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final preferences = SharedAppPreferences(sharedPreferences);
  final initialPreferences = InitialUiPreferences(
    onboarded: await preferences.getOnboardingComplete(),
    reducedMotion: await preferences.getReducedMotion(),
  );
  final coordinator = StoreCoordinator(
    security: PigeonStoreSecurityGateway(),
    preferences: preferences,
    demoImporter: const DemoImportService(
      DemoFixtureLoader(RootBundleFixtureAssetReader()),
    ),
  );
  runApp(
    ProviderScope(
      overrides: [storeCoordinatorProvider.overrideWithValue(coordinator)],
      child: StoreRoot(
        preferences: preferences,
        initialPreferences: initialPreferences,
      ),
    ),
  );
}

class WhyPulseApp extends StatefulWidget {
  const WhyPulseApp({
    super.key,
    this.initialMode = AppMode.demo,
    this.initialOnboarded = false,
    this.initialReducedMotion = false,
    this.onModeChanged,
    this.onDemoReset,
    this.onOnboardingChanged,
    this.onReducedMotionChanged,
    this.initialSources,
    this.initialCheckIns,
    this.initialObserveDashboard,
    this.initialFinding,
    this.initialReplay,
    this.initialHistory,
    this.initialExperimentStatus = ExperimentStatus.draft,
    this.initialExperimentCheckIns = 0,
    this.onSourcesReload,
    this.onSourceAction,
    this.onCalendarDiscovery,
    this.onCalendarReview,
    this.onCheckInSaved,
    this.onCheckInDeleted,
    this.onObserveReload,
    this.onFindingReload,
    this.onReplayReload,
    this.onExperimentStart,
    this.onExperimentOccurrence,
    this.onExperimentPauseChanged,
    this.onExperimentCancel,
    this.onExperimentStop,
    this.onExport,
    this.onAppResumed,
    this.onExplanationRequested,
    this.onAskRequested,
    this.onExplanationCancel,
    this.onModelDownloadInspect,
    this.onModelDownloadAcceptAndStart,
    this.onModelDownloadEnsureScheduled,
    this.onModelDownloadRetry,
    this.onModelDownloadCancel,
    this.initialModelDownloadStatus,
  });

  final AppMode initialMode;
  final bool initialOnboarded;
  final bool initialReducedMotion;
  final Future<void> Function(AppMode mode)? onModeChanged;
  final Future<void> Function()? onDemoReset;
  final Future<void> Function(bool value)? onOnboardingChanged;
  final Future<void> Function(bool value)? onReducedMotionChanged;
  final List<SourceData>? initialSources;
  final List<CheckInData>? initialCheckIns;
  final ObserveDashboardData? initialObserveDashboard;
  final FindingData? initialFinding;
  final MomentReplayData? initialReplay;
  final List<HistoryItemData>? initialHistory;
  final ExperimentStatus initialExperimentStatus;
  final int initialExperimentCheckIns;
  final Future<List<SourceData>> Function()? onSourcesReload;
  final Future<void> Function(String sourceId, SourceAction action)?
  onSourceAction;
  final Future<List<CalendarSeriesData>> Function()? onCalendarDiscovery;
  final Future<void> Function(Map<String, String> reviewed)? onCalendarReview;
  final Future<void> Function(CheckInData checkIn)? onCheckInSaved;
  final Future<void> Function(String id)? onCheckInDeleted;
  final Future<ObserveDashboardData> Function()? onObserveReload;
  final Future<FindingData?> Function()? onFindingReload;
  final Future<MomentReplayData?> Function()? onReplayReload;
  final Future<void> Function()? onExperimentStart;
  final Future<void> Function()? onExperimentOccurrence;
  final Future<void> Function(bool paused)? onExperimentPauseChanged;
  final Future<void> Function()? onExperimentCancel;
  final Future<void> Function()? onExperimentStop;
  final Future<String?> Function()? onExport;
  final Future<void> Function()? onAppResumed;
  final Future<ExplanationData?> Function(
    String intent,
    bool preferCache,
    InferenceProgressCallback onProgress,
  )?
  onExplanationRequested;
  final Future<ExplanationData?> Function(
    String question,
    String intent,
    InferenceProgressCallback onProgress,
  )?
  onAskRequested;
  final Future<void> Function()? onExplanationCancel;
  final Future<ModelDownloadStatus> Function()? onModelDownloadInspect;
  final Future<ModelDownloadStatus> Function()? onModelDownloadAcceptAndStart;
  final Future<ModelDownloadStatus> Function()? onModelDownloadEnsureScheduled;
  final Future<ModelDownloadStatus> Function()? onModelDownloadRetry;
  final Future<ModelDownloadStatus> Function()? onModelDownloadCancel;
  final ModelDownloadStatus? initialModelDownloadStatus;

  @override
  State<WhyPulseApp> createState() => _WhyPulseAppState();
}

class _WhyPulseAppState extends State<WhyPulseApp> {
  late final WhyPulseState _state;

  @override
  void initState() {
    super.initState();
    _state = WhyPulseState(
      initialMode: widget.initialMode,
      initialOnboarded: widget.initialOnboarded,
      initialReducedMotion: widget.initialReducedMotion,
      onModeChanged: widget.onModeChanged,
      onDemoReset: widget.onDemoReset,
      onOnboardingChanged: widget.onOnboardingChanged,
      onReducedMotionChanged: widget.onReducedMotionChanged,
      initialSources: widget.initialSources,
      initialCheckIns: widget.initialCheckIns,
      initialObserveDashboard: widget.initialObserveDashboard,
      initialFinding: widget.initialFinding,
      initialReplay: widget.initialReplay,
      initialHistory: widget.initialHistory,
      initialExperimentStatus: widget.initialExperimentStatus,
      initialExperimentCheckIns: widget.initialExperimentCheckIns,
      onSourcesReload: widget.onSourcesReload,
      onSourceAction: widget.onSourceAction,
      onCalendarDiscovery: widget.onCalendarDiscovery,
      onCalendarReview: widget.onCalendarReview,
      onCheckInSaved: widget.onCheckInSaved,
      onCheckInDeleted: widget.onCheckInDeleted,
      onObserveReload: widget.onObserveReload,
      onFindingReload: widget.onFindingReload,
      onReplayReload: widget.onReplayReload,
      onExperimentStart: widget.onExperimentStart,
      onExperimentOccurrence: widget.onExperimentOccurrence,
      onExperimentPauseChanged: widget.onExperimentPauseChanged,
      onExperimentCancel: widget.onExperimentCancel,
      onExperimentStop: widget.onExperimentStop,
      onExport: widget.onExport,
      onAppResumed: widget.onAppResumed,
      onExplanationRequested: widget.onExplanationRequested,
      onAskRequested: widget.onAskRequested,
      onExplanationCancel: widget.onExplanationCancel,
      onModelDownloadInspect: widget.onModelDownloadInspect,
      onModelDownloadAcceptAndStart: widget.onModelDownloadAcceptAndStart,
      onModelDownloadEnsureScheduled: widget.onModelDownloadEnsureScheduled,
      onModelDownloadRetry: widget.onModelDownloadRetry,
      onModelDownloadCancel: widget.onModelDownloadCancel,
      initialModelDownloadStatus: widget.initialModelDownloadStatus,
    );
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WhyPulseScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'WhyPulse',
            debugShowCheckedModeBanner: false,
            theme: buildPulseTheme(),
            home: _state.onboarded
                ? const WhyPulseShell()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

class StoreRoot extends ConsumerStatefulWidget {
  const StoreRoot({
    super.key,
    required this.preferences,
    required this.initialPreferences,
  });

  final AppPreferences preferences;
  final InitialUiPreferences initialPreferences;

  @override
  ConsumerState<StoreRoot> createState() => _StoreRootState();
}

class _StoreRootState extends ConsumerState<StoreRoot> {
  final _modelDownloadApi = ModelDownloadApi();
  final _notificationApi = NotificationApi();
  late bool _onboarded;
  late bool _reducedMotion;
  RepositoryGraph? _preparedGraph;
  Future<_UiBootstrap>? _prepareFuture;

  @override
  void initState() {
    super.initState();
    _onboarded = widget.initialPreferences.onboarded;
    _reducedMotion = widget.initialPreferences.reducedMotion;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(storeSessionProvider);
    return session.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPulseTheme(),
        home: const _StoreLoadingScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPulseTheme(),
        home: StoreRecoveryScreen(
          error: error,
          onRetry: ref.read(storeSessionProvider.notifier).retry,
          onResetDemo: ref.read(storeSessionProvider.notifier).resetDemo,
          onDeleteLive: ref
              .read(storeSessionProvider.notifier)
              .recoverLiveByDeleting,
        ),
      ),
      data: (graph) {
        if (!identical(_preparedGraph, graph)) {
          _preparedGraph = graph;
          _prepareFuture = _prepare(graph);
        }
        return FutureBuilder<_UiBootstrap>(
          future: _prepareFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildPulseTheme(),
                home: const _StoreLoadingScreen(),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildPulseTheme(),
                home: StoreRecoveryScreen(
                  error: snapshot.error ?? StateError('Source setup failed.'),
                  onRetry: ref.read(storeSessionProvider.notifier).retry,
                  onResetDemo: ref
                      .read(storeSessionProvider.notifier)
                      .resetDemo,
                  onDeleteLive: ref
                      .read(storeSessionProvider.notifier)
                      .recoverLiveByDeleting,
                ),
              );
            }
            final bootstrap = snapshot.requireData;
            return WhyPulseApp(
              key: ValueKey(graph.kind),
              initialMode: graph.kind == StoreKind.live
                  ? AppMode.live
                  : AppMode.demo,
              initialOnboarded: _onboarded,
              initialReducedMotion: _reducedMotion,
              initialSources: bootstrap.sources,
              initialCheckIns: bootstrap.checkIns,
              initialObserveDashboard: bootstrap.observeDashboard,
              initialFinding: bootstrap.finding,
              initialReplay: bootstrap.replay,
              initialHistory: bootstrap.history,
              initialExperimentStatus: bootstrap.experiment.status,
              initialExperimentCheckIns: bootstrap.experiment.checkIns,
              onModeChanged: (mode) => ref
                  .read(storeSessionProvider.notifier)
                  .switchTo(
                    mode == AppMode.live ? StoreKind.live : StoreKind.demo,
                  ),
              onDemoReset: ref.read(storeSessionProvider.notifier).resetDemo,
              onOnboardingChanged: (value) async {
                if (mounted) setState(() => _onboarded = value);
                await widget.preferences.setOnboardingComplete(value);
              },
              onReducedMotionChanged: (value) async {
                if (mounted) setState(() => _reducedMotion = value);
                await widget.preferences.setReducedMotion(value);
              },
              onSourcesReload: () => _loadSources(graph),
              onSourceAction: (sourceId, action) =>
                  _performSourceAction(graph, sourceId, action),
              onCalendarDiscovery: () => _discoverCalendar(graph),
              onCalendarReview: (reviewed) =>
                  _saveCalendarReview(graph, reviewed),
              onCheckInSaved: (checkIn) => _saveCheckIn(graph, checkIn),
              onCheckInDeleted: (id) async {
                await graph.manualCheckins.delete(id);
                await graph.analysis.runPending();
              },
              onObserveReload: () => _loadObserveDashboard(graph),
              onFindingReload: () => _loadFinding(graph),
              onReplayReload: () => _loadReplay(graph),
              onExperimentStart: () => _startExperiment(graph),
              onExperimentOccurrence: () => _recordExperimentOccurrence(graph),
              onExperimentPauseChanged: (paused) =>
                  _setExperimentPaused(graph, paused),
              onExperimentCancel: () => _cancelExperiment(graph),
              onExperimentStop: () => _stopExperiment(graph),
              onExport: () => _exportEvidence(graph),
              onAppResumed: () async {
                await graph.sourceSync.onAppResumed();
                await graph.analysis.runPending();
              },
              onExplanationRequested: (intent, preferCache, onProgress) =>
                  _loadExplanation(
                    graph,
                    intent: intent,
                    preferCache: preferCache,
                    onProgress: onProgress,
                  ),
              onAskRequested: (question, intent, onProgress) =>
                  _loadExplanation(
                    graph,
                    intent: intent,
                    chatQuestion: question,
                    preferCache: true,
                    onProgress: onProgress,
                  ),
              onExplanationCancel: graph.explanationCoordinator.cancel,
              onModelDownloadInspect: _modelDownloadApi.inspectDownload,
              onModelDownloadAcceptAndStart: () async {
                try {
                  await _notificationApi.requestPermission();
                } on Object {
                  // Android still exposes foreground work in Task Manager when
                  // notification permission is denied or unavailable.
                }
                return _modelDownloadApi.acceptAndStart();
              },
              onModelDownloadEnsureScheduled: _modelDownloadApi.ensureScheduled,
              onModelDownloadRetry: _modelDownloadApi.retryDownload,
              onModelDownloadCancel: _modelDownloadApi.cancelDownload,
            );
          },
        );
      },
    );
  }

  Future<_UiBootstrap> _prepare(RepositoryGraph graph) async {
    if (graph.kind == StoreKind.live) await graph.sourceSync.initialize();
    final experiment = await _loadExperiment(graph);
    return _UiBootstrap(
      sources: await _loadSources(graph),
      checkIns: _mapCheckIns(await graph.manualCheckins.load()),
      observeDashboard: await _loadObserveDashboard(graph),
      finding: await _loadFinding(graph),
      replay: await _loadReplay(graph),
      history: await _loadHistory(graph),
      experiment: experiment,
    );
  }

  Future<ObserveDashboardData> _loadObserveDashboard(RepositoryGraph graph) =>
      ObserveDashboardRepository(graph.database).load(
        asOf: graph.demoImport?.virtualNowUtc ?? DateTime.now(),
        isDemo: graph.kind == StoreKind.demo,
      );

  Future<MomentReplayData?> _loadReplay(RepositoryGraph graph) =>
      MomentReplayRepository(graph.database).loadCurrent();

  Future<FindingData?> _loadFinding(RepositoryGraph graph) async {
    final evidence = await graph.analysis.currentEvidence();
    if (evidence == null) return null;
    final finding =
        await (graph.database.select(graph.database.findingVersions)
              ..where((row) => row.evidenceBundleId.equals(evidence.id))
              ..orderBy([(row) => OrderingTerm.desc(row.version)]))
            .getSingleOrNull();
    if (finding == null) return null;
    final metricRows = await (graph.database.select(
      graph.database.evidenceMetrics,
    )..where((row) => row.evidenceBundleId.equals(evidence.id))).get();
    final metrics = {for (final row in metricRows) row.metric: row.value};
    final medianRow = metricRows
        .where((row) => row.metric == 'median_difference_bpm')
        .firstOrNull;
    double metric(String name) => metrics[name] ?? 0;
    return FindingData(
      status: evidence.status,
      title: evidence.title,
      evidenceHash: evidence.evidenceHash,
      evidenceVersion: finding.id,
      candidateCount: metric('candidate_count').round(),
      includedCount: metric('included_count').round(),
      controlsCount: metric('control_count').round(),
      positiveCount: metric('positive_count').round(),
      counterevidenceCount: metric('counterevidence_count').round(),
      medianDifferenceBpm: metric('median_difference_bpm'),
      effectLowerBpm: medianRow?.lowerBound ?? metric('median_difference_bpm'),
      effectUpperBpm: medianRow?.upperBound ?? metric('median_difference_bpm'),
      completeness: metric('completeness'),
      recoveryDurationMinutes: metric('recovery_duration_minutes'),
      unresolvedInfluenceCount: metric('unresolved_influence_count').round(),
      createdAt: evidence.createdAt,
      invalidated: evidence.status == 'invalidated',
    );
  }

  Future<List<HistoryItemData>> _loadHistory(RepositoryGraph graph) async {
    return HistoryRepository(
      graph.database,
      kind: graph.kind,
      experiments: graph.experiments,
    ).load();
  }

  Future<List<SourceData>> _loadSources(RepositoryGraph graph) async {
    if (graph.kind == StoreKind.demo) {
      return [
        for (final source in seedSources)
          if (source.id == 'demo')
            source.copyWith(
              status: SourceStatus.demoFixtureLoaded,
              lastSync: 'Fixture v${graph.demoImport?.fixtureVersion ?? 1}',
              recordCount:
                  graph.demoImport?.sourceReports.values.fold<int>(
                    0,
                    (sum, report) => sum + report.inserted,
                  ) ??
                  0,
            )
          else
            source.copyWith(
              status: SourceStatus.availableInLive,
              completeness: 0,
              statusDetail: 'Switch to Live to connect',
            ),
      ];
    }
    final persisted = await graph.sourceSync.loadStates();
    final result = <SourceData>[];
    for (final template in seedSources.where((source) => source.id != 'demo')) {
      final sourceId = _repositorySourceId(template.id);
      final state = persisted.where((item) => item.id == sourceId).firstOrNull;
      final permissions = await graph.sourceRepository.loadPermissions(
        sourceId,
      );
      final granted = permissions.values
          .where((value) => value == 'granted')
          .length;
      result.add(
        template.copyWith(
          status: _sourceStatus(state?.status),
          lastSync: _lastSyncLabel(state?.configuration['lastSyncUtc']),
          completeness: state?.recordCount == 0 ? 0 : template.completeness,
          recordCount: state?.recordCount ?? 0,
          permissionsGranted: granted,
          permissionsTotal: permissions.length,
          statusDetail: state?.configuration['lastErrorMessage'] as String?,
        ),
      );
    }
    result.add(
      seedSources.last.copyWith(
        status: SourceStatus.available,
        completeness: 0,
        statusDetail: 'Switch to Demo to use fictional data',
      ),
    );
    return result;
  }

  Future<void> _performSourceAction(
    RepositoryGraph graph,
    String uiSourceId,
    SourceAction action,
  ) async {
    final sourceId = _repositorySourceId(uiSourceId);
    switch (action) {
      case SourceAction.connect:
        if (sourceId == SourceIds.health) {
          await graph.sourceSync.connectHealth();
        }
      case SourceAction.refresh:
        await graph.sourceSync.refresh(sourceId);
      case SourceAction.pause:
        await graph.sourceSync.pause(sourceId);
      case SourceAction.resume:
        await graph.sourceSync.resume(sourceId);
      case SourceAction.disconnect:
        await graph.sourceSync.disconnect(sourceId);
      case SourceAction.deleteData:
        await graph.sourceSync.deleteSourceData(sourceId);
      case SourceAction.openSettings:
        await graph.sourceSync.openSettings(sourceId);
    }
    if (action == SourceAction.connect ||
        action == SourceAction.refresh ||
        action == SourceAction.resume ||
        action == SourceAction.deleteData) {
      await graph.analysis.runPending();
    }
  }

  Future<List<CalendarSeriesData>> _discoverCalendar(
    RepositoryGraph graph,
  ) async {
    final series = await graph.sourceSync.connectCalendar();
    return [
      for (final item in series)
        CalendarSeriesData(
          transientId: item.transientId,
          title: item.title,
          recurrenceRule: item.recurrenceRule,
          timeZone: item.timeZone,
          category: item.category,
        ),
    ];
  }

  Future<void> _saveCalendarReview(
    RepositoryGraph graph,
    Map<String, String> reviewed,
  ) async {
    await graph.sourceSync.saveCalendarReview({
      for (final entry in reviewed.entries)
        entry.key: switch (entry.value) {
          'recurring_one_to_one' => ContextCategory.recurringOneToOne,
          'team_meeting' => ContextCategory.teamMeeting,
          _ => ContextCategory.otherRecurringMeeting,
        },
    });
    await graph.analysis.runPending();
  }

  Future<void> _startExperiment(RepositoryGraph graph) async {
    final evidence = await graph.analysis.currentEvidence();
    if (evidence == null) return;
    final finding =
        await (graph.database.select(graph.database.findingVersions)
              ..where((row) => row.validUntil.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.version)]))
            .getSingleOrNull();
    if (finding == null) return;
    final event =
        await (graph.database.select(graph.database.contextEvents)
              ..where(
                (row) =>
                    row.category.equals(ContextCategory.recurringOneToOne.name),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startAtUtc)]))
            .getSingleOrNull();
    final createdAt = graph.demoImport?.virtualNowUtc ?? DateTime.now().toUtc();
    final demoOccurrences = graph.kind == StoreKind.demo
        ? [
            ExperimentOccurrenceModel(
              id: 'demo-active-occurrence-${createdAt.microsecondsSinceEpoch}-1',
              scheduledAtUtc: createdAt,
              status: ExperimentOccurrenceStatus.due,
            ),
            ExperimentOccurrenceModel(
              id: 'demo-active-occurrence-${createdAt.microsecondsSinceEpoch}-2',
              scheduledAtUtc: createdAt.add(const Duration(days: 7)),
              status: ExperimentOccurrenceStatus.upcoming,
            ),
            ExperimentOccurrenceModel(
              id: 'demo-active-occurrence-${createdAt.microsecondsSinceEpoch}-3',
              scheduledAtUtc: createdAt.add(const Duration(days: 14)),
              status: ExperimentOccurrenceStatus.upcoming,
            ),
          ]
        : const <ExperimentOccurrenceModel>[];
    await graph.experiments.start(
      evidenceBundleId: evidence.id,
      findingVersionId: finding.id,
      recurrenceKeyHmac: event?.recurrenceKeyHmac ?? 'selected-recurring-event',
      createdAtUtc: createdAt,
      occurrences: demoOccurrences,
    );
  }

  Future<void> _recordExperimentOccurrence(RepositoryGraph graph) async {
    final protocols = await graph.experiments.loadProtocols();
    final protocol = protocols
        .where((item) => item.status == ExperimentProtocolStatus.active)
        .firstOrNull;
    final occurrence = protocol?.occurrences
        .where(
          (item) =>
              (item.status == ExperimentOccurrenceStatus.upcoming ||
                  item.status == ExperimentOccurrenceStatus.due) &&
              !item.scheduledAtUtc.isAfter(
                graph.demoImport?.virtualNowUtc ?? DateTime.now().toUtc(),
              ),
        )
        .firstOrNull;
    if (occurrence == null) {
      throw StateError('No scheduled experiment occurrence is due');
    }
    await graph.experiments.recordAdherence(
      occurrenceId: occurrence.id,
      adhered: true,
      recordedAtUtc: graph.demoImport?.virtualNowUtc ?? DateTime.now().toUtc(),
    );
  }

  Future<_ExperimentBootstrap> _loadExperiment(RepositoryGraph graph) async {
    final protocols = await graph.experiments.loadProtocols();
    final protocol = protocols
        .where((item) => item.findingVersionId.isNotEmpty)
        .firstOrNull;
    if (protocol == null) return const _ExperimentBootstrap();
    final checkIns = protocol.occurrences
        .where(
          (item) =>
              item.status == ExperimentOccurrenceStatus.adhered ||
              item.status == ExperimentOccurrenceStatus.partiallyAdhered,
        )
        .length;
    return _ExperimentBootstrap(
      status: switch (protocol.status) {
        ExperimentProtocolStatus.draft => ExperimentStatus.draft,
        ExperimentProtocolStatus.active => ExperimentStatus.active,
        ExperimentProtocolStatus.paused => ExperimentStatus.paused,
        ExperimentProtocolStatus.completed => ExperimentStatus.completed,
        ExperimentProtocolStatus.cancelled => ExperimentStatus.cancelled,
        ExperimentProtocolStatus.stopped => ExperimentStatus.stopped,
        ExperimentProtocolStatus.invalidated => ExperimentStatus.invalidated,
      },
      checkIns: checkIns.clamp(0, 3),
    );
  }

  Future<ExperimentProtocolModel?> _currentExperiment(
    RepositoryGraph graph,
  ) async {
    final protocols = await graph.experiments.loadProtocols();
    return protocols
        .where((item) => item.findingVersionId.isNotEmpty)
        .firstOrNull;
  }

  Future<void> _setExperimentPaused(RepositoryGraph graph, bool paused) async {
    final protocol = await _currentExperiment(graph);
    if (protocol == null) throw StateError('No persisted experiment');
    if (paused) {
      await graph.experiments.pause(protocol.id);
    } else {
      await graph.experiments.resume(protocol.id);
    }
  }

  Future<void> _cancelExperiment(RepositoryGraph graph) async {
    final protocol = await _currentExperiment(graph);
    if (protocol == null) throw StateError('No persisted experiment');
    await graph.experiments.cancel(protocol.id);
  }

  Future<void> _stopExperiment(RepositoryGraph graph) async {
    final protocol = await _currentExperiment(graph);
    if (protocol == null) throw StateError('No persisted experiment');
    await graph.experiments.stop(protocol.id);
  }

  Future<String?> _exportEvidence(RepositoryGraph graph) async {
    final evidence = await graph.analysis.currentEvidence();
    if (evidence == null || evidence.status == 'invalidated') return null;
    final finding = await _loadFinding(graph);
    if (finding == null || !finding.isCurrent) return null;
    final result = await graph.exports.export(
      EvidenceExportDocument(
        storeKind: graph.kind.name,
        evidenceVersion: finding.evidenceVersion,
        status: finding.status,
        title: finding.title,
        metrics: {
          'candidate_count': finding.candidateCount,
          'included_count': finding.includedCount,
          'control_count': finding.controlsCount,
          'positive_count': finding.positiveCount,
          'counterevidence_count': finding.counterevidenceCount,
          'median_difference_bpm': finding.medianDifferenceBpm,
          'effect_lower_bpm': finding.effectLowerBpm,
          'effect_upper_bpm': finding.effectUpperBpm,
          'completeness': finding.completeness,
          'recovery_duration_minutes': finding.recoveryDurationMinutes,
        },
        sources: evidenceExportSources(graph.kind),
        exclusions: {
          'unresolved_influence_count': finding.unresolvedInfluenceCount,
        },
        counterevidence: {'count': finding.counterevidenceCount},
        influences: const ['caffeine', 'exercise', 'illness', 'travel'],
        runtime: 'deterministic-analysis-v1',
        safetyState: 'validated',
      ),
    );
    return result.jsonPath;
  }

  Future<void> _saveCheckIn(RepositoryGraph graph, CheckInData checkIn) async {
    await graph.manualCheckins.save(
      ManualCheckinRecord(
        id: checkIn.id,
        category: CheckinCategory.values.firstWhere(
          (category) => category.name == checkIn.category,
          orElse: () => CheckinCategory.custom,
        ),
        occurredAt: checkIn.when,
        detail: checkIn.detail,
        customLabel: checkIn.customLabel,
      ),
    );
    await graph.analysis.runPending();
  }

  Future<ExplanationData?> _loadExplanation(
    RepositoryGraph graph, {
    required String intent,
    String? chatQuestion,
    bool preferCache = true,
    InferenceProgressCallback? onProgress,
  }) async {
    final delivery = await graph.explanationCoordinator.explain(
      intent: intent,
      chatQuestion: chatQuestion,
      preferCache: preferCache,
      onProgress: onProgress,
    );
    if (delivery == null) return null;
    return _mapExplanation(delivery);
  }
}

ExplanationData _mapExplanation(ExplanationDelivery delivery) {
  final output = delivery.explanation.output;
  final decoded = jsonDecode(output.citedParagraphsJson) as List<Object?>;
  final paragraphs = <ExplanationParagraphData>[
    for (final value in decoded)
      if (value case final Map<Object?, Object?> paragraph)
        ExplanationParagraphData(
          text: paragraph['text']! as String,
          citations: (paragraph['citations']! as List<Object?>).cast<String>(),
        ),
  ];
  final runtime = delivery.explanation.metadata.runtime;
  return ExplanationData(
    summary: output.summary,
    paragraphs: paragraphs,
    uncertainty: output.uncertainty,
    runtimeLabel: switch (runtime) {
      InferenceRuntime.phoneMedGemma => 'Explained privately on this phone',
      InferenceRuntime.developmentMachine =>
        'Explained by the development model',
      InferenceRuntime.deterministic => 'Plain-language backup explanation',
    },
    deterministicFallback: delivery.usedFallback,
    fromCache: delivery.fromCache,
    createdAt: delivery.explanation.createdAt,
    modelName: delivery.explanation.metadata.modelName,
    latencyMillis: delivery.explanation.metadata.latencyMillis,
    nextObservation: output.approvedNextObservation,
  );
}

final class _UiBootstrap {
  const _UiBootstrap({
    required this.sources,
    required this.checkIns,
    required this.observeDashboard,
    required this.finding,
    required this.replay,
    required this.history,
    required this.experiment,
  });

  final List<SourceData> sources;
  final List<CheckInData>? checkIns;
  final ObserveDashboardData observeDashboard;
  final FindingData? finding;
  final MomentReplayData? replay;
  final List<HistoryItemData> history;
  final _ExperimentBootstrap experiment;
}

final class _ExperimentBootstrap {
  const _ExperimentBootstrap({
    this.status = ExperimentStatus.draft,
    this.checkIns = 0,
  });

  final ExperimentStatus status;
  final int checkIns;
}

List<CheckInData> _mapCheckIns(List<ManualCheckinRecord> records) => [
  for (final record in records)
    CheckInData(
      id: record.id,
      when: record.occurredAt,
      context: record.category == CheckinCategory.custom
          ? record.customLabel ?? 'Custom check-in'
          : '${record.category.name[0].toUpperCase()}${record.category.name.substring(1)} check-in',
      detail: record.detail,
      icon: _checkInIcon(record.category),
      category: record.category.name,
      customLabel: record.customLabel,
    ),
];

IconData _checkInIcon(CheckinCategory category) => switch (category) {
  CheckinCategory.caffeine => Icons.coffee_outlined,
  CheckinCategory.exercise => Icons.directions_run_rounded,
  CheckinCategory.illness => Icons.sick_outlined,
  CheckinCategory.mood => Icons.sentiment_satisfied_alt_outlined,
  CheckinCategory.travel => Icons.flight_outlined,
  CheckinCategory.custom => Icons.edit_note_rounded,
};

String _repositorySourceId(String uiSourceId) => switch (uiSourceId) {
  'health' => SourceIds.health,
  'calendar' => SourceIds.calendar,
  'checkins' => SourceIds.manual,
  _ => uiSourceId,
};

SourceStatus _sourceStatus(String? status) => switch (status) {
  'unavailable' => SourceStatus.unavailable,
  'permission_required' => SourceStatus.permissionRequired,
  'partially_permitted' => SourceStatus.partiallyPermitted,
  'syncing' => SourceStatus.syncing,
  'connected_empty' => SourceStatus.connectedEmpty,
  'connected_data' => SourceStatus.connectedData,
  'paused' => SourceStatus.paused,
  'error' => SourceStatus.error,
  'deleting' => SourceStatus.deleting,
  'stale' => SourceStatus.stale,
  _ => SourceStatus.disconnected,
};

String? _lastSyncLabel(Object? value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return null;
  final now = DateTime.now();
  if (now.difference(parsed).inMinutes.abs() < 2) return 'Just now';
  return '${parsed.month}/${parsed.day} · ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}

class InitialUiPreferences {
  const InitialUiPreferences({
    required this.onboarded,
    required this.reducedMotion,
  });

  final bool onboarded;
  final bool reducedMotion;
}

class _StoreLoadingScreen extends StatelessWidget {
  const _StoreLoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(
        label: 'Opening encrypted local store',
        child: const CircularProgressIndicator(),
      ),
    ),
  );
}

class StoreRecoveryScreen extends StatelessWidget {
  const StoreRecoveryScreen({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onResetDemo,
    required this.onDeleteLive,
  });

  final Object error;
  final AsyncCallback onRetry;
  final AsyncCallback onResetDemo;
  final AsyncCallback onDeleteLive;

  @override
  Widget build(BuildContext context) {
    final securityError = error is StoreSecurityException
        ? error as StoreSecurityException
        : null;
    final isLive = securityError?.kind == StoreKind.live;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48),
              const SizedBox(height: 20),
              Text(
                isLive ? 'Live data is locked' : 'Demo store needs recovery',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                isLive
                    ? 'WhyPulse could not recover the key for the encrypted Live store. It will not create a plaintext replacement.'
                    : 'WhyPulse could not open the encrypted Demo store. Live data has not been changed.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isLive)
                FilledButton(
                  onPressed: onDeleteLive,
                  child: const Text('Delete Live data and recreate'),
                )
              else
                FilledButton(
                  onPressed: onResetDemo,
                  child: const Text('Reset Demo only'),
                ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
