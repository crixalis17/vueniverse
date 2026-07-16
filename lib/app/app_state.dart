import 'dart:async';

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:why_pulse/data/demo/demo_content.dart';
import 'package:why_pulse/domain/model_runtime/ask_intent_router.dart';
import 'package:why_pulse/domain/models/app_models.dart';

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
    FindingData? initialFinding,
    List<HistoryItemData>? initialHistory,
    Future<List<SourceData>> Function()? onSourcesReload,
    Future<void> Function(String sourceId, SourceAction action)? onSourceAction,
    Future<List<CalendarSeriesData>> Function()? onCalendarDiscovery,
    Future<void> Function(Map<String, String> reviewed)? onCalendarReview,
    Future<void> Function(CheckInData checkIn)? onCheckInSaved,
    Future<void> Function(String id)? onCheckInDeleted,
    Future<FindingData?> Function()? onFindingReload,
    Future<void> Function()? onExperimentStart,
    Future<void> Function()? onExperimentOccurrence,
    Future<String?> Function()? onExport,
    Future<void> Function()? onAppResumed,
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
       _onFindingReload = onFindingReload,
       _onExperimentStart = onExperimentStart,
       _onExperimentOccurrence = onExperimentOccurrence,
       _onExport = onExport,
       _onAppResumed = onAppResumed,
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
       ) {
    WidgetsBinding.instance.addObserver(this);
    if (mode == AppMode.live && _onAppResumed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOnResume());
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
  final Future<FindingData?> Function()? _onFindingReload;
  final Future<void> Function()? _onExperimentStart;
  final Future<void> Function()? _onExperimentOccurrence;
  final Future<String?> Function()? _onExport;
  final Future<void> Function()? _onAppResumed;
  bool _disposed = false;

  int tabIndex = 0;
  bool onboarded;
  AppMode mode;
  bool reducedMotion;
  bool offline = false;
  bool sourceOperationInProgress = false;
  String? sourceOperationMessage;
  ExperimentStatus experimentStatus = ExperimentStatus.draft;
  int experimentCheckIns = 0;
  List<SourceData> sources;
  FindingData? finding;
  List<HistoryItemData> history;
  final List<CheckInData> checkIns;
  final List<ChatMessageData> chatMessages = [];
  static const _askRouter = AskIntentRouter();

  void finishOnboarding(AppMode selectedMode) {
    onboarded = true;
    mode = selectedMode;
    final modeChanged = _onModeChanged;
    if (modeChanged != null) unawaited(modeChanged(selectedMode));
    final onboardingChanged = _onOnboardingChanged;
    if (onboardingChanged != null) unawaited(onboardingChanged(true));
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
    notifyListeners();
  }

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
    finding = await callback();
    if (!_disposed) notifyListeners();
  }

  void addCheckIn(CheckInData checkIn) {
    checkIns.insert(0, checkIn);
    final callback = _onCheckInSaved;
    if (callback != null) {
      unawaited(
        callback(checkIn).then((_) => refreshFinding()).catchError((_) {}),
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
        callback(checkIn).then((_) => refreshFinding()).catchError((_) {}),
      );
    }
    notifyListeners();
  }

  void deleteCheckIn(String id) {
    checkIns.removeWhere((entry) => entry.id == id);
    final callback = _onCheckInDeleted;
    if (callback != null) {
      unawaited(callback(id).then((_) => refreshFinding()).catchError((_) {}));
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || mode != AppMode.live) return;
    _refreshOnResume();
  }

  void _refreshOnResume() {
    final callback = _onAppResumed;
    if (callback == null || _disposed) return;
    unawaited(() async {
      try {
        await callback();
        await reloadSources();
      } on Object {
        // Persisted source state contains the retryable failure shown in the UI.
      }
    }());
  }

  void activateExperiment() {
    experimentStatus = ExperimentStatus.active;
    experimentCheckIns = 0;
    final callback = _onExperimentStart;
    if (callback != null) unawaited(callback());
    notifyListeners();
  }

  void toggleExperimentPause() {
    if (experimentStatus == ExperimentStatus.active) {
      experimentStatus = ExperimentStatus.paused;
    } else if (experimentStatus == ExperimentStatus.paused) {
      experimentStatus = ExperimentStatus.active;
    }
    notifyListeners();
  }

  void completeExperimentOccurrence() {
    if (experimentStatus != ExperimentStatus.active) return;
    experimentCheckIns = (experimentCheckIns + 1).clamp(0, 3);
    final callback = _onExperimentOccurrence;
    if (callback != null) unawaited(callback());
    if (experimentCheckIns == 3) experimentStatus = ExperimentStatus.completed;
    notifyListeners();
  }

  void stopExperiment() {
    experimentStatus = ExperimentStatus.invalidated;
    notifyListeners();
  }

  Future<String?> exportEvidence() async {
    final callback = _onExport;
    if (callback == null) return null;
    return callback();
  }

  void ask(String question) {
    final cleaned = question.trim();
    if (cleaned.isEmpty) return;
    chatMessages.add(ChatMessageData(text: cleaned, fromUser: true));
    final lower = cleaned.toLowerCase();
    if (_askRouter.route(cleaned) == AskIntent.unsupported) {
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
    } else if (lower.contains('exercise')) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'Recent exercise is unlikely to explain all of the difference. Three active windows were excluded, and six comparable meetings still showed a higher pre-event heart rate.',
          fromUser: false,
          evidence: ['Activity exclusion', '6 included meetings'],
          uncertainty: 'Caffeine was missing on two meeting days.',
        ),
      );
    } else if (lower.contains('disagree') || lower.contains('counter')) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'Two meetings did not show the same rise. One followed recent exercise and one had incomplete caffeine context, so both remain visible as counterevidence.',
          fromUser: false,
          evidence: ['2 of 8 did not repeat', 'Influence log'],
          uncertainty:
              'Those exceptions limit confidence and prevent a causal claim.',
        ),
      );
    } else if (lower.contains('missing') || lower.contains('weaken')) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'The largest gap is caffeine context on two days. More complete check-ins or meetings that do not show the rise could weaken the pattern.',
          fromUser: false,
          evidence: ['86% completeness', '2 unknown caffeine days'],
          uncertainty:
              'This is a repeated association, not a causal conclusion.',
        ),
      );
    } else if (lower.contains('observe') || lower.contains('next')) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'For the next comparable meeting, record caffeine, recent exercise, illness, and whether the event was rescheduled. Complete context makes the matched comparison easier to challenge.',
          fromUser: false,
          evidence: ['2 context gaps', 'Next eligible meeting'],
          uncertainty:
              'Observing more context can clarify the pattern, but cannot guarantee a conclusion.',
        ),
      );
    } else if (lower.contains('why') || lower.contains('promot')) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'It was promoted because six of eight comparable meetings moved in the same direction, with a median +11 bpm difference after activity and travel exclusions.',
          fromUser: false,
          evidence: ['6 of 8 meetings', '+11 bpm', 'Matched comparison'],
          uncertainty: 'Promotion means supported—not proven or causal.',
        ),
      );
    } else {
      chatMessages.add(
        const ChatMessageData(
          text:
              'Across six comparable recurring meetings, the pre-event window was 8–14 bpm above matched no-meeting windows. Activity and travel windows were excluded.',
          fromUser: false,
          evidence: ['Matched comparison', '+8–14 bpm', '6 of 8 meetings'],
          uncertainty: 'Caffeine context is incomplete.',
        ),
      );
    }
    notifyListeners();
  }

  void resetDemo() {
    mode = AppMode.demo;
    sources = List<SourceData>.of(seedSources);
    experimentStatus = ExperimentStatus.draft;
    experimentCheckIns = 0;
    chatMessages.clear();
    final demoReset = _onDemoReset;
    if (demoReset != null) unawaited(demoReset());
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
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
