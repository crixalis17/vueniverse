import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:why_pulse/data/demo/demo_content.dart';
import 'package:why_pulse/domain/model_runtime/ask_intent_router.dart';
import 'package:why_pulse/domain/models/app_models.dart';
import 'package:why_pulse/platform/generated/model_download_api.g.dart';

class WhyPulseState extends ChangeNotifier with WidgetsBindingObserver {
  WhyPulseState({
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
    Future<ExplanationData?> Function(String intent)? onExplanationRequested,
    Future<ExplanationData?> Function(String question, String intent)?
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
                   evidenceVersion: 'demo-fixture-v1',
                   candidateCount: 12,
                   includedCount: 8,
                   controlsCount: 12,
                   positiveCount: 6,
                   counterevidenceCount: 2,
                   medianDifferenceBpm: 11,
                   effectLowerBpm: 8,
                   effectUpperBpm: 14,
                   completeness: .86,
                   recoveryDurationMinutes: 42,
                   unresolvedInfluenceCount: 2,
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
                       valuesBpm: [79, 91, 77],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 2',
                       valuesBpm: [82, 93, 78],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 3',
                       valuesBpm: [80, 90, 76],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 4',
                       valuesBpm: [83, 94, 79],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 5',
                       valuesBpm: [81, 92, 77],
                     ),
                     ReplayTraceData(
                       label: 'Repeat 6',
                       valuesBpm: [84, 95, 80],
                     ),
                   ],
                   matchedBaselineBpm: [70, 72, 71],
                   sourceLabel: 'Deterministic Demo event windows',
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
  final Future<ExplanationData?> Function(String intent)?
  _onExplanationRequested;
  final Future<ExplanationData?> Function(String question, String intent)?
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
  ModelDownloadStatus modelDownloadStatus;
  bool get modelDownloadOperationInProgress =>
      _modelDownloadOperationInProgress;
  static const _askRouter = AskIntentRouter();

  void finishOnboarding(AppMode selectedMode) {
    onboarded = true;
    mode = selectedMode;
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
    mode = value;
    final modeChanged = _onModeChanged;
    if (modeChanged != null) unawaited(modeChanged(value));
    if (value == AppMode.live) {
      unawaited(ensureModelDownloadScheduled());
    } else {
      unawaited(cancelModelDownload());
    }
    notifyListeners();
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
        totalBytes: 2489894144,
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
      if (callback != null) await callback();
    } on Object {
      experimentCheckIns = previousCheckIns;
      experimentStatus = previousStatus;
      experimentOperationMessage =
          'The occurrence check-in could not be saved. Try again.';
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
    final callback = _onExport;
    if (callback == null) return null;
    return callback();
  }

  Future<void> loadExplanation({bool refresh = false}) async {
    if (explanationInProgress || (!refresh && currentExplanation != null)) {
      return;
    }
    explanationInProgress = true;
    explanationMessage = null;
    notifyListeners();
    try {
      currentExplanation =
          await _onExplanationRequested?.call('why_promoted') ??
          _localExplanation('why_promoted');
      if (currentExplanation == null) {
        explanationMessage =
            'No current evidence explanation is available yet.';
      }
    } on Object {
      explanationMessage =
          'The explanation could not be generated. No unverified text was shown.';
    } finally {
      explanationInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> cancelExplanation() async {
    await _onExplanationCancel?.call();
    explanationInProgress = false;
    askInProgress = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> ask(String question) async {
    final cleaned = question.trim();
    if (cleaned.isEmpty || askInProgress) return;
    chatMessages.add(ChatMessageData(text: cleaned, fromUser: true));
    final routed = _askRouter.route(cleaned);
    if (routed == AskIntent.unsupported) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'I can only explain this evidence bundle. Ask why it was shown, what is missing, what disagrees, or what to observe next.',
          fromUser: false,
          evidence: ['Safety boundary'],
          uncertainty:
              'Diagnosis, treatment, and unrelated questions are blocked.',
        ),
      );
      notifyListeners();
      return;
    }
    askInProgress = true;
    notifyListeners();
    try {
      final intent = _askIntentWireName(routed);
      final explanation =
          await _onAskRequested?.call(cleaned, intent) ??
          _localExplanation(intent);
      if (explanation == null) {
        chatMessages.add(
          const ChatMessageData(
            text:
                'No validated explanation is available for the current evidence.',
            fromUser: false,
            evidence: ['Output guard'],
            uncertainty: 'Unverified model text was not displayed.',
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
          ),
        );
      }
    } on Object {
      chatMessages.add(
        const ChatMessageData(
          text:
              'The explanation runtime was unavailable, and no unverified text was shown.',
          fromUser: false,
          evidence: ['Output guard'],
          uncertainty: 'Try again after the evidence bundle is refreshed.',
        ),
      );
    } finally {
      askInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  ExplanationData? _localExplanation(String intent) {
    final current = finding;
    if (current == null || !current.isCurrent) return null;
    final summary = switch (intent) {
      'missing_evidence' =>
        'Evidence completeness is ${(current.completeness * 100).round()} percent, with ${current.unresolvedInfluenceCount} unresolved influences still visible.',
      'disagreement' =>
        '${current.counterevidenceCount} comparable observations did not move in the promoted direction, so they remain visible as counterevidence.',
      'observe_next' => 'Log caffeine before the next comparable meeting.',
      _ =>
        'The comparison is supported by ${current.includedCount} included meetings: the median difference was ${current.medianDifferenceBpm >= 0 ? '+' : ''}${current.medianDifferenceBpm.toStringAsFixed(0)} bpm.',
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
            'disagreement' => const ['counterevidence_count'],
            'observe_next' => const ['unresolved_influences'],
            _ => const ['included_count', 'median_difference_bpm'],
          },
        ),
      ],
      uncertainty:
          'This describes a repeated personal association and does not establish why it happened or what action to take.',
      runtimeLabel: 'Deterministic preview',
      deterministicFallback: true,
      fromCache: false,
      createdAt: DateTime.now().toUtc(),
      nextObservation: intent == 'observe_next'
          ? 'Log caffeine before the next comparable meeting.'
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
    mode = AppMode.demo;
    unawaited(cancelModelDownload());
    sources = List<SourceData>.of(seedSources);
    experimentStatus = ExperimentStatus.draft;
    experimentCheckIns = 0;
    chatMessages.clear();
    currentExplanation = null;
    explanationMessage = null;
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

class WhyPulseScope extends InheritedNotifier<WhyPulseState> {
  const WhyPulseScope({
    super.key,
    required WhyPulseState state,
    required super.child,
  }) : super(notifier: state);

  static WhyPulseState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<WhyPulseScope>();
    assert(result != null, 'WhyPulseScope is missing.');
    return result!.notifier!;
  }
}
