import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:vueniverse/data/demo/demo_content.dart';
import 'package:vueniverse/domain/model_runtime/ask_intent_router.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/platform/generated/model_download_api.g.dart';

class VueniverseState extends ChangeNotifier with WidgetsBindingObserver {
  VueniverseState({
    AppMode initialMode = AppMode.demo,
    bool initialOnboarded = false,
    bool initialReducedMotion = false,
    Future<void> Function(AppMode mode)? onModeChanged,
    Future<void> Function()? onDemoReset,
    Future<void> Function(bool value)? onOnboardingChanged,
    Future<void> Function(bool value)? onReducedMotionChanged,
    List<SourceData>? initialSources,
    List<CheckInData>? initialCheckIns,
    ObserveDashboardData? initialObserveDashboard,
    FindingData? initialFinding,
    MomentReplayData? initialReplay,
    List<HistoryItemData>? initialHistory,
    ExperimentStatus initialExperimentStatus = ExperimentStatus.draft,
    int initialExperimentCheckIns = 0,
    Future<List<SourceData>> Function()? onSourcesReload,
    Future<void> Function(String sourceId, SourceAction action)? onSourceAction,
    Future<List<CalendarSeriesData>> Function()? onCalendarDiscovery,
    Future<void> Function(Map<String, String> reviewed)? onCalendarReview,
    Future<void> Function(CheckInData checkIn)? onCheckInSaved,
    Future<void> Function(String id)? onCheckInDeleted,
    Future<ObserveDashboardData> Function()? onObserveReload,
    Future<FindingData?> Function()? onFindingReload,
    Future<MomentReplayData?> Function()? onReplayReload,
    Future<void> Function()? onExperimentStart,
    Future<void> Function()? onExperimentOccurrence,
    Future<void> Function(bool paused)? onExperimentPauseChanged,
    Future<void> Function()? onExperimentCancel,
    Future<void> Function()? onExperimentStop,
    Future<String?> Function()? onExport,
    Future<void> Function()? onAppResumed,
    Future<ExplanationData?> Function(
      String intent,
      bool preferCache,
      InferenceProgressCallback onProgress,
    )?
    onExplanationRequested,
    Future<ExplanationData?> Function(
      String question,
      String intent,
      InferenceProgressCallback onProgress,
    )?
    onAskRequested,
    Future<void> Function()? onExplanationCancel,
    Future<ModelDownloadStatus> Function()? onModelDownloadInspect,
    Future<ModelDownloadStatus> Function()? onModelDownloadAcceptAndStart,
    Future<ModelDownloadStatus> Function()? onModelDownloadEnsureScheduled,
    Future<ModelDownloadStatus> Function()? onModelDownloadRetry,
    Future<ModelDownloadStatus> Function()? onModelDownloadCancel,
    ModelDownloadStatus? initialModelDownloadStatus,
  }) : mode = initialMode,
       onboarded = initialOnboarded,
       reducedMotion = initialReducedMotion,
       _onModeChanged = onModeChanged,
       _onDemoReset = onDemoReset,
       _onOnboardingChanged = onOnboardingChanged,
       _onReducedMotionChanged = onReducedMotionChanged,
       _onSourcesReload = onSourcesReload,
       _onSourceAction = onSourceAction,
       _onCalendarDiscovery = onCalendarDiscovery,
       _onCalendarReview = onCalendarReview,
       _onCheckInSaved = onCheckInSaved,
       _onCheckInDeleted = onCheckInDeleted,
       _onObserveReload = onObserveReload,
       _onFindingReload = onFindingReload,
       _onReplayReload = onReplayReload,
       _onExperimentStart = onExperimentStart,
       _onExperimentOccurrence = onExperimentOccurrence,
       _onExperimentPauseChanged = onExperimentPauseChanged,
       _onExperimentCancel = onExperimentCancel,
       _onExperimentStop = onExperimentStop,
       _onExport = onExport,
       _onAppResumed = onAppResumed,
       _onExplanationRequested = onExplanationRequested,
       _onAskRequested = onAskRequested,
       _onExplanationCancel = onExplanationCancel,
       _onModelDownloadInspect = onModelDownloadInspect,
       _onModelDownloadAcceptAndStart = onModelDownloadAcceptAndStart,
       _onModelDownloadEnsureScheduled = onModelDownloadEnsureScheduled,
       _onModelDownloadRetry = onModelDownloadRetry,
       _onModelDownloadCancel = onModelDownloadCancel,
       modelDownloadStatus =
           initialModelDownloadStatus ?? _initialModelDownloadStatus(),
       sources = List<SourceData>.of(initialSources ?? seedSources),
       finding =
           initialFinding ??
           (initialMode == AppMode.demo
               ? FindingData(
                   status: 'supported',
                   title: 'Recurring 1:1 and heart rate',
                   evidenceHash: '7c9e…f42a',
                   evidenceVersion: 'demo-fixture-v3',
                   candidateCount: 12,
                   includedCount: 8,
                   controlsCount: 12,
                   positiveCount: 6,
                   counterevidenceCount: 2,
                   medianDifferenceBpm: 11,
                   effectLowerBpm: 8,
                   effectUpperBpm: 14,
                   completeness: 1,
                   recoveryDurationMinutes: 42,
                   unresolvedInfluenceCount: 3,
                   createdAt: DateTime(2026, 7, 16),
                 )
               : null),
       replay =
           initialReplay ??
           (initialMode == AppMode.demo
               ? const MomentReplayData(
                   phases: ['Before', 'During', 'Recovery'],
                   traces: [
                     ReplayTraceData(
                       label: 'Repeat 1',
                       valuesBpm: [76, 79, 74],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 2',
                       valuesBpm: [79, 82, 75],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 3',
                       valuesBpm: [80, 83, 74],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 4',
                       valuesBpm: [81, 84, 74],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 5',
                       valuesBpm: [81, 84, 73],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 6',
                       valuesBpm: [84, 87, 76],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 7',
                       valuesBpm: [64, 67, 72],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 8',
                       valuesBpm: [65, 68, 72],
                     ),
                   ],
                   matchedBaselineBpm: [68, 68, 68],
                   sourceLabel:
                       'Persisted included event windows · matched controls',
                 )
               : null),
       history = List<HistoryItemData>.of(
         initialHistory ??
             (initialMode == AppMode.demo ? seedHistory : const []),
       ),
       checkIns = List<CheckInData>.of(
         initialCheckIns ??
             [
               CheckInData(
                 id: 'morning',
                 when: DateTime(2026, 7, 16, 8, 5),
                 context: 'Morning check-in',
                 detail: 'Mood steady · No caffeine yet',
                 icon: Icons.sentiment_satisfied_alt_rounded,
                 category: 'mood',
               ),
               CheckInData(
                 id: 'meeting-context',
                 when: DateTime(2026, 7, 15, 10, 42),
                 context: 'Before weekly 1:1',
                 detail: '1 coffee · No exercise · Not ill',
                 icon: Icons.coffee_rounded,
                 category: 'caffeine',
               ),
             ],
       ),
       experimentStatus = initialExperimentStatus,
       experimentCheckIns = initialExperimentCheckIns,
       observeDashboard =
           initialObserveDashboard ??
           (initialMode == AppMode.demo
               ? seedObserveDashboard
               : _emptyObserveDashboard(DateTime.now(), isDemo: false)) {
    WidgetsBinding.instance.addObserver(this);
    if (mode == AppMode.live && _onAppResumed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOnResume());
    }
    if (mode == AppMode.live &&
        onboarded &&
        _onModelDownloadEnsureScheduled != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(ensureModelDownloadScheduled()),
      );
    }
    if (mode == AppMode.demo && _onModelDownloadInspect != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(inspectModelDownload()),
      );
    }
  }

  final Future<void> Function(AppMode mode)? _onModeChanged;
  final Future<void> Function()? _onDemoReset;
  final Future<void> Function(bool value)? _onOnboardingChanged;
  final Future<void> Function(bool value)? _onReducedMotionChanged;
  final Future<List<SourceData>> Function()? _onSourcesReload;
  final Future<void> Function(String sourceId, SourceAction action)?
  _onSourceAction;
  final Future<List<CalendarSeriesData>> Function()? _onCalendarDiscovery;
  final Future<void> Function(Map<String, String> reviewed)? _onCalendarReview;
  final Future<void> Function(CheckInData checkIn)? _onCheckInSaved;
  final Future<void> Function(String id)? _onCheckInDeleted;
  final Future<ObserveDashboardData> Function()? _onObserveReload;
  final Future<FindingData?> Function()? _onFindingReload;
  final Future<MomentReplayData?> Function()? _onReplayReload;
  final Future<void> Function()? _onExperimentStart;
  final Future<void> Function()? _onExperimentOccurrence;
  final Future<void> Function(bool paused)? _onExperimentPauseChanged;
  final Future<void> Function()? _onExperimentCancel;
  final Future<void> Function()? _onExperimentStop;
  final Future<String?> Function()? _onExport;
  final Future<void> Function()? _onAppResumed;
  final Future<ExplanationData?> Function(
    String intent,
    bool preferCache,
    InferenceProgressCallback onProgress,
  )?
  _onExplanationRequested;
  final Future<ExplanationData?> Function(
    String question,
    String intent,
    InferenceProgressCallback onProgress,
  )?
  _onAskRequested;
  final Future<void> Function()? _onExplanationCancel;
  final Future<ModelDownloadStatus> Function()? _onModelDownloadInspect;
  final Future<ModelDownloadStatus> Function()? _onModelDownloadAcceptAndStart;
  final Future<ModelDownloadStatus> Function()? _onModelDownloadEnsureScheduled;
  final Future<ModelDownloadStatus> Function()? _onModelDownloadRetry;
  final Future<ModelDownloadStatus> Function()? _onModelDownloadCancel;
  bool _disposed = false;
  Timer? _modelDownloadPoll;
  int _modelDownloadPollingClients = 0;
  bool _modelDownloadOperationInProgress = false;
  int _inferenceGeneration = 0;

  int tabIndex = 0;
  bool onboarded;
  AppMode mode;
  bool reducedMotion;
  bool offline = false;
  bool sourceOperationInProgress = false;
  String? sourceOperationMessage;
  bool observeRefreshInProgress = false;
  String? observeRefreshMessage;
  bool experimentOperationInProgress = false;
  String? experimentOperationMessage;
  ExperimentStatus experimentStatus;
  int experimentCheckIns;
  List<SourceData> sources;
  ObserveDashboardData observeDashboard;
  FindingData? finding;
  MomentReplayData? replay;
  List<HistoryItemData> history;
  final List<CheckInData> checkIns;
  final List<ChatMessageData> chatMessages = [];
  ExplanationData? currentExplanation;
  bool explanationInProgress = false;
  String? explanationMessage;
  bool askInProgress = false;
  InferenceProgress? inferenceProgress;
  ModelDownloadStatus modelDownloadStatus;
  bool get modelDownloadOperationInProgress =>
      _modelDownloadOperationInProgress;
  bool get hasDisplayableCurrentFinding {
    final current = finding;
    if (current == null || !current.isCurrent) return false;
    final dashboardMatchesMode =
        observeDashboard.isDemo == (mode == AppMode.demo);
    if (!dashboardMatchesMode) return false;
    if (mode == AppMode.demo) return !observeDashboard.isEmpty;
    return observeDashboard.heartRateRecords > 0 &&
        observeDashboard.eventRecords > 0;
  }

  static const _askRouter = AskIntentRouter();

  void finishOnboarding(AppMode selectedMode) {
    onboarded = true;
    if (mode != selectedMode) _clearModeScopedState(selectedMode);
    final modeChanged = _onModeChanged;
    if (modeChanged != null) unawaited(modeChanged(selectedMode));
    final onboardingChanged = _onOnboardingChanged;
    if (onboardingChanged != null) unawaited(onboardingChanged(true));
    if (selectedMode == AppMode.live) {
      unawaited(ensureModelDownloadScheduled());
    }
    notifyListeners();
  }

  void selectTab(int value) {
    tabIndex = value;
    notifyListeners();
  }

  void setMode(AppMode value) {
    if (mode == value) return;
    _clearModeScopedState(value);
    final modeChanged = _onModeChanged;
    if (modeChanged != null) unawaited(modeChanged(value));
    if (value == AppMode.live) {
      unawaited(ensureModelDownloadScheduled());
    } else {
      unawaited(inspectModelDownload());
    }
    notifyListeners();
  }

  void _clearModeScopedState(AppMode nextMode) {
    _inferenceGeneration += 1;
    mode = nextMode;
    sources = nextMode == AppMode.demo
        ? List<SourceData>.of(seedSources)
        : <SourceData>[];
    finding = null;
    replay = null;
    history.clear();
    checkIns.clear();
    observeDashboard = _emptyObserveDashboard(
      DateTime.now(),
      isDemo: nextMode == AppMode.demo,
    );
    experimentStatus = ExperimentStatus.draft;
    experimentCheckIns = 0;
    experimentOperationMessage = null;
    sourceOperationMessage = null;
    observeRefreshMessage = null;
    chatMessages.clear();
    currentExplanation = null;
    explanationMessage = null;
    inferenceProgress = null;
  }

  Future<ModelDownloadStatus> inspectModelDownload() async {
    final callback = _onModelDownloadInspect;
    if (callback == null) return modelDownloadStatus;
    try {
      return _setModelDownloadStatus(await callback());
    } on Object {
      return _setModelDownloadStatus(
        _modelDownloadFailure('platform_unavailable'),
      );
    }
  }

  Future<ModelDownloadStatus> acceptAndStartModelDownload() =>
      _runModelDownloadOperation(_onModelDownloadAcceptAndStart);

  Future<ModelDownloadStatus> ensureModelDownloadScheduled() =>
      _runModelDownloadOperation(_onModelDownloadEnsureScheduled);

  Future<ModelDownloadStatus> retryModelDownload() =>
      _runModelDownloadOperation(_onModelDownloadRetry);

  Future<ModelDownloadStatus> cancelModelDownload() =>
      _runModelDownloadOperation(_onModelDownloadCancel);

  Future<ModelDownloadStatus> _runModelDownloadOperation(
    Future<ModelDownloadStatus> Function()? callback,
  ) async {
    if (callback == null) return modelDownloadStatus;
    _modelDownloadOperationInProgress = true;
    if (!_disposed) notifyListeners();
    try {
      return _setModelDownloadStatus(await callback());
    } on Object {
      return _setModelDownloadStatus(
        _modelDownloadFailure('platform_unavailable'),
      );
    } finally {
      _modelDownloadOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  ModelDownloadStatus _setModelDownloadStatus(ModelDownloadStatus status) {
    modelDownloadStatus = status;
    if (!_disposed) notifyListeners();
    return status;
  }

  void beginModelDownloadPolling() {
    _modelDownloadPollingClients += 1;
    if (_modelDownloadPollingClients != 1) return;
    unawaited(inspectModelDownload());
    _modelDownloadPoll = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(inspectModelDownload()),
    );
  }

  void endModelDownloadPolling() {
    if (_modelDownloadPollingClients == 0) return;
    _modelDownloadPollingClients -= 1;
    if (_modelDownloadPollingClients != 0) return;
    _modelDownloadPoll?.cancel();
    _modelDownloadPoll = null;
  }

  static ModelDownloadStatus _initialModelDownloadStatus() =>
      ModelDownloadStatus(
        state: ModelDownloadState.notConfigured,
        downloadedBytes: 0,
        totalBytes: 2489894976,
        progress: 0,
        retryable: false,
        detail: 'not_inspected',
      );

  ModelDownloadStatus _modelDownloadFailure(String detail) =>
      ModelDownloadStatus(
        state: ModelDownloadState.failed,
        downloadedBytes: modelDownloadStatus.downloadedBytes,
        totalBytes: modelDownloadStatus.totalBytes,
        progress: modelDownloadStatus.progress,
        retryable: true,
        detail: detail,
      );

  void setReducedMotion(bool value) {
    reducedMotion = value;
    final reducedMotionChanged = _onReducedMotionChanged;
    if (reducedMotionChanged != null) unawaited(reducedMotionChanged(value));
    notifyListeners();
  }

  void setOffline(bool value) {
    offline = value;
    notifyListeners();
  }

  void updateSource(String id, SourceStatus status) {
    sources = sources.map((source) {
      if (source.id != id) return source;
      return source.copyWith(
        status: status,
        lastSync: status == SourceStatus.connected
            ? 'Just now'
            : source.lastSync,
        completeness: status == SourceStatus.connected
            ? source.completeness
            : 0,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> refreshSources() async {
    if (_onSourceAction == null) {
      sources = sources.map((source) {
        if (source.status != SourceStatus.connected) return source;
        return source.copyWith(lastSync: 'Just now');
      }).toList();
      notifyListeners();
      return;
    }
    for (final source in sources.where(
      (source) => source.id == 'health' || source.id == 'calendar',
    )) {
      await performSourceAction(source.id, SourceAction.refresh);
    }
  }

  Future<void> performSourceAction(String id, SourceAction action) async {
    final callback = _onSourceAction;
    if (callback == null) {
      if (action == SourceAction.pause) {
        updateSource(id, SourceStatus.paused);
      } else if (action == SourceAction.resume ||
          action == SourceAction.connect ||
          action == SourceAction.refresh) {
        updateSource(id, SourceStatus.connected);
      }
      return;
    }
    sourceOperationInProgress = true;
    sourceOperationMessage = null;
    notifyListeners();
    try {
      await callback(id, action);
      await reloadSources();
      await refreshObserveDashboard();
      await refreshFinding();
    } on Object {
      sourceOperationMessage =
          'This source could not complete the request. Its last safe state was kept.';
    } finally {
      sourceOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<CalendarSeriesData>> discoverCalendarSeries() async {
    final callback = _onCalendarDiscovery;
    if (callback == null) return const [];
    sourceOperationInProgress = true;
    sourceOperationMessage = null;
    notifyListeners();
    try {
      final result = await callback();
      await reloadSources();
      return result;
    } on Object {
      sourceOperationMessage =
          'Calendar review could not open. Check permission and try again.';
      return const [];
    } finally {
      sourceOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> saveCalendarReview(Map<String, String> reviewed) async {
    final callback = _onCalendarReview;
    if (callback == null) return;
    sourceOperationInProgress = true;
    notifyListeners();
    try {
      await callback(reviewed);
      await reloadSources();
      await refreshObserveDashboard();
      await refreshFinding();
    } finally {
      sourceOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> reloadSources() async {
    final callback = _onSourcesReload;
    if (callback == null) return;
    sources = await callback();
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshFinding() async {
    final callback = _onFindingReload;
    if (callback == null) return;
    final priorEvidenceVersion = finding?.evidenceVersion;
    finding = await callback();
    final replayReload = _onReplayReload;
    if (replayReload != null) replay = await replayReload();
    if (finding?.evidenceVersion != priorEvidenceVersion) {
      currentExplanation = null;
      explanationMessage = null;
      chatMessages.clear();
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshObserveDashboard() async {
    final callback = _onObserveReload;
    if (callback == null) return;
    observeRefreshInProgress = true;
    observeRefreshMessage = null;
    if (!_disposed) notifyListeners();
    try {
      observeDashboard = await callback();
    } on Object {
      observeRefreshMessage =
          'The dashboard could not refresh. The last local snapshot is still shown.';
    } finally {
      observeRefreshInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  void addCheckIn(CheckInData checkIn) {
    checkIns.insert(0, checkIn);
    final callback = _onCheckInSaved;
    if (callback != null) {
      unawaited(
        callback(checkIn)
            .then((_) async {
              await refreshObserveDashboard();
              await refreshFinding();
            })
            .catchError((_) {}),
      );
    }
    notifyListeners();
  }

  void editCheckIn(CheckInData checkIn) {
    final index = checkIns.indexWhere((entry) => entry.id == checkIn.id);
    if (index == -1) return;
    checkIns[index] = checkIn;
    final callback = _onCheckInSaved;
    if (callback != null) {
      unawaited(
        callback(checkIn)
            .then((_) async {
              await refreshObserveDashboard();
              await refreshFinding();
            })
            .catchError((_) {}),
      );
    }
    notifyListeners();
  }

  void deleteCheckIn(String id) {
    checkIns.removeWhere((entry) => entry.id == id);
    final callback = _onCheckInDeleted;
    if (callback != null) {
      unawaited(
        callback(id)
            .then((_) async {
              await refreshObserveDashboard();
              await refreshFinding();
            })
            .catchError((_) {}),
      );
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || mode != AppMode.live) return;
    _refreshOnResume();
    unawaited(inspectModelDownload());
  }

  void _refreshOnResume() {
    final callback = _onAppResumed;
    if (callback == null || _disposed) return;
    unawaited(() async {
      try {
        await callback();
        await reloadSources();
        await refreshObserveDashboard();
        await refreshFinding();
      } on Object {
        // Persisted source state contains the retryable failure shown in the UI.
      }
    }());
  }

  Future<void> activateExperiment() async {
    if (experimentOperationInProgress) return;
    final previousStatus = experimentStatus;
    final previousCheckIns = experimentCheckIns;
    experimentStatus = ExperimentStatus.active;
    experimentCheckIns = 0;
    experimentOperationInProgress = true;
    experimentOperationMessage = null;
    notifyListeners();
    final callback = _onExperimentStart;
    try {
      if (callback != null) await callback();
    } on Object {
      experimentStatus = previousStatus;
      experimentCheckIns = previousCheckIns;
      experimentOperationMessage =
          'The experiment could not start. No protocol was changed.';
    } finally {
      experimentOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggleExperimentPause() async {
    if (experimentOperationInProgress) return;
    final previous = experimentStatus;
    if (experimentStatus == ExperimentStatus.active) {
      experimentStatus = ExperimentStatus.paused;
    } else if (experimentStatus == ExperimentStatus.paused) {
      experimentStatus = ExperimentStatus.active;
    } else {
      return;
    }
    experimentOperationInProgress = true;
    experimentOperationMessage = null;
    notifyListeners();
    try {
      await _onExperimentPauseChanged?.call(
        experimentStatus == ExperimentStatus.paused,
      );
    } on Object {
      experimentStatus = previous;
      experimentOperationMessage =
          'The pause state could not be saved. The last persisted state is shown.';
    } finally {
      experimentOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> completeExperimentOccurrence() async {
    if (experimentStatus != ExperimentStatus.active ||
        experimentOperationInProgress) {
      return;
    }
    final previousCheckIns = experimentCheckIns;
    final previousStatus = experimentStatus;
    experimentCheckIns = (experimentCheckIns + 1).clamp(0, 3);
    if (experimentCheckIns == 3) experimentStatus = ExperimentStatus.completed;
    experimentOperationInProgress = true;
    experimentOperationMessage = null;
    notifyListeners();
    final callback = _onExperimentOccurrence;
    try {
      if (callback == null) {
        throw StateError('No experiment occurrence repository is available');
      }
      await callback();
    } on Object {
      experimentCheckIns = previousCheckIns;
      experimentStatus = previousStatus;
      experimentOperationMessage =
          'The occurrence check-in could not be saved. Only a due scheduled meeting can be checked in.';
    } finally {
      experimentOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> cancelExperiment() async {
    await _endExperiment(
      ExperimentStatus.cancelled,
      _onExperimentCancel,
      'The cancellation could not be saved.',
    );
  }

  Future<void> stopExperiment() async {
    await _endExperiment(
      ExperimentStatus.stopped,
      _onExperimentStop,
      'The stop request could not be saved.',
    );
  }

  Future<void> _endExperiment(
    ExperimentStatus status,
    Future<void> Function()? callback,
    String errorMessage,
  ) async {
    if (experimentOperationInProgress) return;
    final previous = experimentStatus;
    experimentStatus = status;
    experimentOperationInProgress = true;
    experimentOperationMessage = null;
    notifyListeners();
    try {
      if (callback != null) await callback();
    } on Object {
      experimentStatus = previous;
      experimentOperationMessage = errorMessage;
    } finally {
      experimentOperationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String?> exportEvidence() async {
    if (!hasDisplayableCurrentFinding) return null;
    final callback = _onExport;
    if (callback == null) return null;
    return callback();
  }

  Future<void> loadExplanation({bool refresh = false}) async {
    if (!hasDisplayableCurrentFinding) return;
    if (explanationInProgress ||
        askInProgress ||
        (!refresh && currentExplanation != null)) {
      return;
    }
    if (refresh) currentExplanation = null;
    explanationInProgress = true;
    inferenceProgress = const InferenceProgress(
      stage: InferenceProgressStage.preparingEvidence,
    );
    explanationMessage = null;
    final generation = ++_inferenceGeneration;
    notifyListeners();
    try {
      final explanation =
          await _onExplanationRequested?.call('why_promoted', !refresh, (
            progress,
          ) {
            if (generation == _inferenceGeneration) {
              _updateInferenceProgress(progress);
            }
          }) ??
          _localExplanation('why_promoted');
      if (generation != _inferenceGeneration) return;
      currentExplanation = explanation;
      if (currentExplanation == null) {
        explanationMessage = 'No explanation is available for this result yet.';
      }
    } on Object {
      if (generation != _inferenceGeneration) return;
      explanationMessage =
          'Vueniverse could not create a reliable explanation, so it did not show one.';
    } finally {
      if (generation == _inferenceGeneration) {
        explanationInProgress = false;
        inferenceProgress = null;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<void> cancelExplanation() async {
    _inferenceGeneration += 1;
    explanationInProgress = false;
    askInProgress = false;
    inferenceProgress = null;
    if (!_disposed) notifyListeners();
    try {
      await _onExplanationCancel?.call();
    } on Object {
      // The local request is already invalidated even if a runtime cannot
      // acknowledge cancellation.
    }
  }

  Future<void> ask(String question) async {
    if (!hasDisplayableCurrentFinding) return;
    final cleaned = question.trim();
    if (cleaned.isEmpty || askInProgress || explanationInProgress) return;
    chatMessages.add(ChatMessageData(text: cleaned, fromUser: true));
    final routed = _askRouter.route(cleaned);
    if (routed == AskIntent.unsupported) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'I can answer questions about this pattern only. Ask why it is shown, what data is missing, which meetings do not match, or what to track next.',
          fromUser: false,
          evidence: ['Answer scope'],
          uncertainty:
              'Vueniverse does not answer diagnosis or treatment questions here.',
        ),
      );
      notifyListeners();
      return;
    }
    askInProgress = true;
    final generation = ++_inferenceGeneration;
    inferenceProgress = const InferenceProgress(
      stage: InferenceProgressStage.preparingEvidence,
    );
    notifyListeners();
    try {
      final intent = _askIntentWireName(routed);
      final explanation =
          await _onAskRequested?.call(cleaned, intent, (progress) {
            if (generation == _inferenceGeneration) {
              _updateInferenceProgress(progress);
            }
          }) ??
          _localExplanation(intent);
      if (generation != _inferenceGeneration) return;
      if (explanation == null) {
        chatMessages.add(
          const ChatMessageData(
            text:
                'Vueniverse could not prepare an answer that matched the current data.',
            fromUser: false,
            evidence: ['Current pattern data'],
            uncertainty:
                'Vueniverse did not show a model-written answer because it could not check it against the data.',
          ),
        );
      } else {
        chatMessages.add(
          ChatMessageData(
            text: explanation.summary,
            fromUser: false,
            evidence: <String>{
              for (final paragraph in explanation.paragraphs)
                ...paragraph.citations,
            }.toList(),
            uncertainty: explanation.uncertainty,
            runtimeLabel: explanation.runtimeLabel,
            modelName: explanation.modelName,
            latencyMillis: explanation.latencyMillis,
          ),
        );
      }
    } on Object {
      if (generation != _inferenceGeneration) return;
      chatMessages.add(
        const ChatMessageData(
          text:
              'Vueniverse could not prepare an answer just now. It did not show an unchecked answer.',
          fromUser: false,
          evidence: ['Current pattern data'],
          uncertainty: 'Refresh the pattern and try again.',
        ),
      );
    } finally {
      if (generation == _inferenceGeneration) {
        askInProgress = false;
        inferenceProgress = null;
        if (!_disposed) notifyListeners();
      }
    }
  }

  void _updateInferenceProgress(InferenceProgress progress) {
    inferenceProgress = progress;
    if (!_disposed) notifyListeners();
  }

  ExplanationData? _localExplanation(String intent) {
    final current = finding;
    if (!hasDisplayableCurrentFinding || current == null) return null;
    final summary = switch (intent) {
      'missing_evidence' =>
        '${(current.completeness * 100).round()}% of the needed data is available. ${current.unresolvedInfluenceCount} context ${current.unresolvedInfluenceCount == 1 ? 'detail still needs' : 'details still need'} review.',
      'disagreement' =>
        '${current.counterevidenceCount} of ${current.includedCount} meetings we could compare did not show the same pattern.',
      'observe_next' => 'Log caffeine before the next similar meeting.',
      _ =>
        'Heart rate followed the same pattern in ${current.positiveCount} of the ${current.includedCount} meetings we could fairly compare. The usual difference was ${current.medianDifferenceBpm >= 0 ? '+' : ''}${current.medianDifferenceBpm.toStringAsFixed(0)} beats per minute.',
    };
    return ExplanationData(
      summary: summary,
      paragraphs: [
        ExplanationParagraphData(
          text: summary,
          citations: switch (intent) {
            'missing_evidence' => const [
              'completeness',
              'unresolved_influence_count',
            ],
            'disagreement' => const ['counterevidence_count', 'included_count'],
            'observe_next' => const ['unresolved_influences'],
            _ => const [
              'positive_count',
              'included_count',
              'median_difference_bpm',
            ],
          },
        ),
      ],
      uncertainty:
          'This is a pattern in your data. It does not prove that the meeting was the reason for the heart-rate change.',
      runtimeLabel: 'Plain-language backup explanation',
      deterministicFallback: true,
      fromCache: false,
      createdAt: DateTime.now().toUtc(),
      modelName: 'Checked local explanation rules',
      latencyMillis: 0,
      nextObservation: intent == 'observe_next'
          ? 'Log caffeine before the next similar meeting.'
          : null,
    );
  }

  String _askIntentWireName(AskIntent intent) => switch (intent) {
    AskIntent.whyPromoted => 'why_promoted',
    AskIntent.missingEvidence => 'missing_evidence',
    AskIntent.disagreement => 'disagreement',
    AskIntent.observeNext => 'observe_next',
    AskIntent.unsupported => 'unsupported',
  };

  void resetDemo() {
    _clearModeScopedState(AppMode.demo);
    final demoReset = _onDemoReset;
    if (demoReset != null) unawaited(demoReset());
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _modelDownloadPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

ObserveDashboardData _emptyObserveDashboard(
  DateTime asOf, {
  required bool isDemo,
}) {
  final end = DateTime(asOf.year, asOf.month, asOf.day);
  final start = end.subtract(const Duration(days: 29));
  return ObserveDashboardData(
    rangeStart: start,
    rangeEnd: end,
    asOf: asOf,
    isDemo: isDemo,
    days: List.unmodifiable([
      for (var index = 0; index < 30; index++)
        ObserveDayData(
          day: start.add(Duration(days: index)),
          heartRateMedianBpm: null,
          sleepMinutes: null,
          steps: null,
          eventCount: 0,
          checkInCount: 0,
          recordCount: 0,
        ),
    ]),
    recentActivity: const [],
    heartRateRecords: 0,
    hrvRecords: 0,
    stepRecords: 0,
    sleepRecords: 0,
    workoutRecords: 0,
    activityRecords: 0,
    eventRecords: 0,
    checkInRecords: 0,
  );
}

class VueniverseScope extends InheritedNotifier<VueniverseState> {
  const VueniverseScope({
    super.key,
    required VueniverseState state,
    required super.child,
  }) : super(notifier: state);

  static VueniverseState of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<VueniverseScope>();
    assert(result != null, 'VueniverseScope is missing.');
    return result!.notifier!;
  }
}
