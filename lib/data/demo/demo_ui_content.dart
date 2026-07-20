import 'package:flutter/material.dart';
import 'package:vueniverse/data/demo/demo_scenario_analysis_repository.dart';
import 'package:vueniverse/domain/models/app_models.dart';

/// Explicitly later capabilities are UI scope metadata, not a live source.
const expansionSources = <SourceData>[
  SourceData(
    id: 'screen',
    name: 'Screen time',
    description: 'Coarse device activity windows',
    contribution: 'Late activity and attention patterns',
    icon: Icons.phone_android_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'strava',
    name: 'Strava',
    description: 'Route-free workout timing and intensity',
    contribution: 'Exercise context and recovery comparisons',
    icon: Icons.directions_bike_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'media',
    name: 'Spotify',
    description: 'Coarse listening sessions',
    contribution: 'Media context around repeated moments',
    icon: Icons.headphones_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'wearables',
    name: 'Rings & wearables',
    description: 'Direct provider integrations',
    contribution: 'Additional physiology and recovery signals',
    icon: Icons.watch_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'fhir',
    name: 'Clinical records',
    description: 'FHIR import with explicit review',
    contribution: 'User-controlled clinical context',
    icon: Icons.medical_information_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
  SourceData(
    id: 'environment',
    name: 'Smart environment',
    description: 'Light, sound and room conditions',
    contribution: 'Environmental context without surveillance',
    icon: Icons.home_work_rounded,
    status: SourceStatus.unavailable,
    tier: FeatureTier.later,
  ),
];

class DemoScenarioData {
  const DemoScenarioData({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.badge,
    required this.color,
    required this.icon,
    required this.outcome,
    required this.reason,
    required this.signals,
    required this.videoGuidance,
    required this.sourceDisclosure,
  });

  final String id;
  final DemoScenarioKind kind;
  final String title;
  final String detail;
  final String badge;
  final Color color;
  final IconData icon;
  final String outcome;
  final String reason;
  final List<String> signals;
  final String videoGuidance;
  final String sourceDisclosure;

  bool get usesCalculatedEvidence => kind == DemoScenarioKind.calculated;
}

const demoScenarios = <DemoScenarioData>[
  DemoScenarioData(
    id: 'supported-recurring-pattern',
    kind: DemoScenarioKind.calculated,
    title: 'Recurring 1:1 and heart rate',
    detail: '6 of 8 similar meetings showed a higher pre-meeting heart rate',
    badge: 'PATTERN FOUND',
    color: Color(0xFFC7FF3F),
    icon: Icons.monitor_heart_rounded,
    outcome: 'Repeated personal pattern',
    reason:
        'Enough good-quality meeting windows moved in the same direction after unreliable and confounded windows were left out.',
    signals: [
      '12 meetings checked; 8 could be fairly compared',
      '6 of 8 showed the pattern',
      'Usual difference: +11 beats per minute',
    ],
    videoGuidance:
        'Lead with this case: source timeline → replay → exclusions → bounded Ask Vueniverse explanation.',
    sourceDisclosure:
        'Fixture-calculated from the encrypted Demo v4 store by the recurring-meeting heart-rate engine.',
  ),
  DemoScenarioData(
    id: 'null-small-difference',
    kind: DemoScenarioKind.calculated,
    title: 'Two meetings stayed near baseline',
    detail: 'Two comparable meetings differed by only −1.5 bpm',
    badge: 'NO CLEAR PATTERN',
    color: Color(0xFF6F8CFF),
    icon: Icons.horizontal_rule_rounded,
    outcome: 'A useful null finding',
    reason:
        'Both complete meeting windows stayed close to their matched controls, so the engine kept the small result without promoting a pattern.',
    signals: [
      '2 of 2 windows were usable',
      'Usual difference: −1.5 beats per minute',
      'Both values stayed below the 5 bpm materiality gate',
    ],
    videoGuidance:
        'Show this after the supported case to prove that Demo mode does not force every comparison into a positive story.',
    sourceDisclosure:
        'Fixture-calculated from meetings 11 and 12 in the encrypted Demo v4 store.',
  ),
  DemoScenarioData(
    id: 'contradictory-mixed-direction',
    kind: DemoScenarioKind.calculated,
    title: 'Mixed meeting response',
    detail: 'One comparable meeting was higher and one was below baseline',
    badge: 'MIXED RESULT',
    color: Color(0xFFFFB547),
    icon: Icons.compare_arrows_rounded,
    outcome: 'The directions disagree',
    reason:
        'The two usable windows moved in opposite directions. The engine retained the counterexample and returned a mixed result.',
    signals: [
      '2 of 2 windows were usable',
      'One difference was +14 bpm',
      'One counterexample was −2 bpm',
    ],
    videoGuidance:
        'Show the opposing traces and counterevidence count; this demonstrates why one dramatic event is not enough.',
    sourceDisclosure:
        'Fixture-calculated from meetings 10 and 11 in the encrypted Demo v4 store.',
  ),
  DemoScenarioData(
    id: 'developing-early-repeat',
    kind: DemoScenarioKind.calculated,
    title: 'Early recurring-meeting signal',
    detail: 'Two comparable meetings moved in the same direction',
    badge: 'DEVELOPING',
    color: Color(0xFF5AF0BA),
    icon: Icons.timeline_rounded,
    outcome: 'Promising, but not ready',
    reason:
        'The difference was material and consistent, but only two usable repeats were available. The promotion policy requires at least four.',
    signals: [
      '2 of 2 windows showed the same direction',
      'Usual difference: +9 beats per minute',
      '2 more comparable meetings required',
    ],
    videoGuidance:
        'Use this to explain the four-repeat promotion gate and why promising evidence remains developing.',
    sourceDisclosure:
        'Fixture-calculated from meetings 1 and 3 in the encrypted Demo v4 store.',
  ),
  DemoScenarioData(
    id: 'insufficient-travel-confounded',
    kind: DemoScenarioKind.calculated,
    title: 'Travel-confounded meeting',
    detail: 'The meeting was found but excluded from the comparison',
    badge: 'NOT ENOUGH DATA',
    color: Color(0xFF747D78),
    icon: Icons.rule_rounded,
    outcome: 'No usable comparison remained',
    reason:
        'Travel was logged on the same local day, so the engine excluded the otherwise complete meeting window instead of treating it as evidence.',
    signals: [
      '1 meeting found',
      '1 matched control found',
      'Travel exclusion left 0 usable meetings',
    ],
    videoGuidance:
        'Open the exclusion reason and show that the large-looking trace is not promoted when major context is present.',
    sourceDisclosure:
        'Fixture-calculated from meeting 8 and its travel check-in in the encrypted Demo v4 store.',
  ),
  DemoScenarioData(
    id: 'expired-travel-recovery',
    kind: DemoScenarioKind.lifecycle,
    title: 'Travel-day recovery',
    detail:
        'The source was deleted, so the previous result is no longer current',
    badge: 'LIFECYCLE',
    color: Color(0xFFFF725E),
    icon: Icons.flight_outlined,
    outcome: 'Result invalidated',
    reason:
        'One of the records used by the result was removed. Vueniverse keeps the history but does not present it as current evidence.',
    signals: [
      'Travel check-in source removed',
      'Dependent explanation and chat invalidated',
      'Historical receipt preserved',
    ],
    videoGuidance:
        'Open this from History as an invalidation receipt, after the current calculated cases.',
    sourceDisclosure:
        'Seeded lifecycle receipt. It is not recalculated from the current Demo store.',
  ),
  DemoScenarioData(
    id: 'weakened-context-review-receipt',
    kind: DemoScenarioKind.lifecycle,
    title: 'Late meetings and sleep duration',
    detail: 'An earlier receipt weakened after illness context was reviewed',
    badge: 'LIFECYCLE',
    color: Color(0xFFFFB547),
    icon: Icons.history_toggle_off_rounded,
    outcome: 'The older conclusion became weaker',
    reason:
        'This seeded receipt demonstrates how History preserves a prior conclusion after newly reviewed context changes its interpretation.',
    signals: [
      'Earlier receipt preserved',
      'Illness context reviewed later',
      'Status changed to Weakened',
    ],
    videoGuidance:
        'Open this from History to show versioned review, and state that it is a seeded lifecycle receipt.',
    sourceDisclosure:
        'Seeded lifecycle receipt. It is not recalculated by the current meeting heart-rate engine.',
  ),
  DemoScenarioData(
    id: 'demo-experiment-strengthened',
    kind: DemoScenarioKind.experiment,
    title: 'Quiet buffer before a 1:1',
    detail: 'Recovery was 9 minutes faster across 3 eligible meetings',
    badge: 'DEMO TEST',
    color: Color(0xFF55D8FF),
    icon: Icons.science_rounded,
    outcome: 'Small personal test completed',
    reason:
        'All three planned occurrences had enough data, and the measured recovery moved in the expected direction.',
    signals: [
      '3 of 3 planned meetings completed',
      'Recovery was 9 minutes faster',
      'The result stays a personal observation, not treatment advice',
    ],
    videoGuidance:
        'Show the completed protocol, three adherence check-ins, and the strengthened result after the evidence cases.',
    sourceDisclosure:
        'Seeded completed Demo experiment. It is separate from the meeting evidence engine.',
  ),
  DemoScenarioData(
    id: 'demo-experiment-inconclusive',
    kind: DemoScenarioKind.experiment,
    title: 'Skip caffeine before a 1:1',
    detail: 'Low coverage and a skipped change left the test inconclusive',
    badge: 'DEMO TEST',
    color: Color(0xFFB19CFF),
    icon: Icons.schedule_rounded,
    outcome: 'The test did not resolve the question',
    reason:
        'One planned change was skipped and another occurrence lacked enough heart-rate coverage, so no conclusion was promoted.',
    signals: [
      '1 eligible meeting completed',
      '1 planned change skipped',
      '1 meeting lacked heart-rate coverage',
    ],
    videoGuidance:
        'Use as the second experiment outcome to show that incomplete adherence does not become a success story.',
    sourceDisclosure:
        'Seeded completed Demo experiment. It is separate from the meeting evidence engine.',
  ),
  DemoScenarioData(
    id: 'illustrative-caffeine-sleep',
    kind: DemoScenarioKind.illustrative,
    title: 'Caffeine and sleep duration',
    detail: 'Preview of a future sleep comparison',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.bedtime_rounded,
    outcome: 'What a reviewed sleep detector could show',
    reason:
        'The Demo timeline contains sleep and caffeine records, but this build does not yet run a deterministic sleep comparison engine.',
    signals: [
      'Fictional sleep and caffeine records are present',
      'No current EvidenceCard is generated for this claim',
      'Kept as an explicitly labelled roadmap example',
    ],
    videoGuidance:
        'Use only as a short future-scenario beat and say that it is illustrative.',
    sourceDisclosure:
        'Illustrative preview. This claim is not calculated by the current build.',
  ),
  DemoScenarioData(
    id: 'illustrative-evening-walk',
    kind: DemoScenarioKind.illustrative,
    title: 'Evening walks and resting heart rate',
    detail: 'Preview of a future activity comparison',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.directions_walk_rounded,
    outcome: 'What an activity detector could investigate',
    reason:
        'Activity records can support this question later, but no walk-specific deterministic engine is active in this build.',
    signals: [
      'Activity timing would be the anchor',
      'Morning heart rate would be the outcome',
      'No current EvidenceCard is generated',
    ],
    videoGuidance: 'Use only if the video needs a future activity example.',
    sourceDisclosure:
        'Illustrative preview. This claim is not calculated by the current build.',
  ),
  DemoScenarioData(
    id: 'illustrative-workout-recovery',
    kind: DemoScenarioKind.illustrative,
    title: 'Morning workout and recovery',
    detail: 'Preview of a future workout recovery comparison',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.fitness_center_rounded,
    outcome: 'What a workout detector could investigate',
    reason:
        'Workout records are present, but the current reviewed detector only calculates recurring-meeting heart-rate evidence.',
    signals: [
      'Workout timing is available',
      'A recovery metric is not calculated yet',
      'No supported workout claim is shown',
    ],
    videoGuidance:
        'Use as a roadmap example, not as a second supported result.',
    sourceDisclosure:
        'Illustrative preview. This claim is not calculated by the current build.',
  ),
  DemoScenarioData(
    id: 'illustrative-bedtime-heart-rate',
    kind: DemoScenarioKind.illustrative,
    title: 'Consistent bedtime and morning heart rate',
    detail: 'Preview of a future bedtime comparison',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.dark_mode_rounded,
    outcome: 'What a paired-morning detector could show',
    reason:
        'Sleep and morning heart-rate records are present, but this paired comparison is not implemented as a reviewed detector.',
    signals: [
      'Sleep windows are available',
      'Morning heart rate is available',
      'No current null finding is generated',
    ],
    videoGuidance: 'Keep this in the optional future-scenarios section.',
    sourceDisclosure:
        'Illustrative preview. This claim is not calculated by the current build.',
  ),
  DemoScenarioData(
    id: 'illustrative-workout-hrv',
    kind: DemoScenarioKind.illustrative,
    title: 'Strength workouts and next-day HRV',
    detail: 'Preview of a future next-day comparison',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.query_stats_rounded,
    outcome: 'What a next-day HRV detector could investigate',
    reason:
        'The Demo store contains HRV and workout records, but the current engine does not calculate a next-day association.',
    signals: [
      'HRV records are visible in Observe',
      'Workout records are visible in Observe',
      'No current EvidenceCard is generated',
    ],
    videoGuidance: 'Use only if the demo video needs a future HRV example.',
    sourceDisclosure:
        'Illustrative preview. This claim is not calculated by the current build.',
  ),
  DemoScenarioData(
    id: 'illustrative-illness-recovery',
    kind: DemoScenarioKind.illustrative,
    title: 'Illness and post-event recovery',
    detail: 'Preview of a future context-aware recovery comparison',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.healing_outlined,
    outcome: 'What a reviewed illness-recovery detector could show',
    reason:
        'Illness currently acts as an exclusion for meeting evidence. It is not itself promoted as a recovery claim.',
    signals: [
      'Illness context is logged',
      'The meeting engine uses it as an exclusion',
      'No illness-recovery EvidenceCard is generated',
    ],
    videoGuidance:
        'Use to explain the difference between a confounder and a calculated outcome.',
    sourceDisclosure:
        'Illustrative preview. This claim is not calculated by the current build.',
  ),
  DemoScenarioData(
    id: 'illustrative-wearable-coverage',
    kind: DemoScenarioKind.illustrative,
    title: 'Wearable coverage gap',
    detail: 'Preview of a future multi-window coverage result',
    badge: 'ILLUSTRATIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.watch_off_outlined,
    outcome: 'What a broader coverage detector could report',
    reason:
        'The current fixture demonstrates real exclusions, but the “2 of 7” wearable story is not calculated by an active engine.',
    signals: [
      'Coverage is checked for every meeting window',
      'The real travel exclusion case is calculated',
      'This broader wearable story remains a preview',
    ],
    videoGuidance:
        'Prefer the real travel-exclusion scenario; use this only as an optional roadmap card.',
    sourceDisclosure:
        'Illustrative preview. The “2 of 7” claim is not calculated by the current build.',
  ),
];
