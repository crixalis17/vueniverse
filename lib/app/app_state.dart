import 'package:flutter/material.dart';
import 'package:why_pulse/data/seed/seed_content.dart';
import 'package:why_pulse/domain/models/app_models.dart';

class WhyPulseState extends ChangeNotifier {
  int tabIndex = 0;
  bool onboarded = false;
  AppMode mode = AppMode.demo;
  bool reducedMotion = false;
  bool offline = false;
  ExperimentStatus experimentStatus = ExperimentStatus.draft;
  int experimentCheckIns = 0;
  List<SourceData> sources = List<SourceData>.of(seedSources);
  final List<CheckInData> checkIns = [
    CheckInData(
      id: 'morning',
      when: DateTime(2026, 7, 16, 8, 5),
      context: 'Morning check-in',
      detail: 'Mood steady · No caffeine yet',
      icon: Icons.sentiment_satisfied_alt_rounded,
    ),
    CheckInData(
      id: 'meeting-context',
      when: DateTime(2026, 7, 15, 10, 42),
      context: 'Before weekly 1:1',
      detail: '1 coffee · No exercise · Not ill',
      icon: Icons.coffee_rounded,
    ),
  ];
  final List<ChatMessageData> chatMessages = [];

  void finishOnboarding(AppMode selectedMode) {
    onboarded = true;
    mode = selectedMode;
    notifyListeners();
  }

  void selectTab(int value) {
    tabIndex = value;
    notifyListeners();
  }

  void setMode(AppMode value) {
    mode = value;
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    reducedMotion = value;
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

  void refreshSources() {
    sources = sources.map((source) {
      if (source.status != SourceStatus.connected) return source;
      return source.copyWith(lastSync: 'Just now');
    }).toList();
    notifyListeners();
  }

  void addCheckIn(CheckInData checkIn) {
    checkIns.insert(0, checkIn);
    notifyListeners();
  }

  void deleteCheckIn(String id) {
    checkIns.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  void activateExperiment() {
    experimentStatus = ExperimentStatus.active;
    experimentCheckIns = 0;
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
    if (experimentCheckIns == 3) experimentStatus = ExperimentStatus.completed;
    notifyListeners();
  }

  void stopExperiment() {
    experimentStatus = ExperimentStatus.invalidated;
    notifyListeners();
  }

  void ask(String question) {
    final cleaned = question.trim();
    if (cleaned.isEmpty) return;
    chatMessages.add(ChatMessageData(text: cleaned, fromUser: true));
    final lower = cleaned.toLowerCase();
    if (lower.contains('diagnos') ||
        lower.contains('treatment') ||
        lower.contains('medicine')) {
      chatMessages.add(
        const ChatMessageData(
          text:
              'I can only explain this evidence bundle. I cannot diagnose a condition or recommend treatment.',
          fromUser: false,
          evidence: ['Safety boundary'],
          uncertainty: 'You can ask what supports or weakens this pattern.',
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
    notifyListeners();
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
