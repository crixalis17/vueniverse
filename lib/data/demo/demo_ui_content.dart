import 'package:flutter/material.dart';
import 'package:why_pulse/domain/models/app_models.dart';

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
    required this.title,
    required this.detail,
    required this.badge,
    required this.color,
    required this.icon,
    required this.outcome,
    required this.reason,
    required this.signals,
  });

  final String title;
  final String detail;
  final String badge;
  final Color color;
  final IconData icon;
  final String outcome;
  final String reason;
  final List<String> signals;
}

const demoScenarios = <DemoScenarioData>[
  DemoScenarioData(
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
  ),
  DemoScenarioData(
    title: 'Caffeine and sleep duration',
    detail: 'No clear repeated difference across 3 similar nights',
    badge: 'NO CLEAR PATTERN',
    color: Color(0xFF6F8CFF),
    icon: Icons.bedtime_rounded,
    outcome: 'No repeatable difference yet',
    reason:
        'The completed comparisons stayed close to the fictional person’s usual sleep duration.',
    signals: [
      '3 nights had complete caffeine context',
      'Night-to-night changes went in both directions',
      'No result was forced from a small difference',
    ],
  ),
  DemoScenarioData(
    title: 'Late meetings and sleep duration',
    detail: 'The difference narrowed after illness days were excluded',
    badge: 'WEAKENED',
    color: Color(0xFFFFB547),
    icon: Icons.nights_stay_outlined,
    outcome: 'An earlier result became weaker',
    reason:
        'Removing illness days changed the comparison enough that the earlier result no longer had the same support.',
    signals: [
      'Illness overlapped with 2 late-meeting days',
      'The adjusted sleep difference became smaller',
      'The earlier result remains visible in History',
    ],
  ),
  DemoScenarioData(
    title: 'Evening walks and resting heart rate',
    detail: 'Seen 5 times; 2 more similar nights are needed',
    badge: 'DEVELOPING',
    color: Color(0xFF5AF0BA),
    icon: Icons.directions_walk_rounded,
    outcome: 'Promising, but not ready',
    reason:
        'The same direction appeared more than once, but too few comparable nights passed the minimum repeatability check.',
    signals: [
      '5 usable walk nights',
      '2 additional comparable nights needed',
      'Caffeine and illness context are still incomplete',
    ],
  ),
  DemoScenarioData(
    title: 'Travel-day recovery',
    detail:
        'The source was deleted, so the previous result is no longer current',
    badge: 'EXPIRED',
    color: Color(0xFFFF725E),
    icon: Icons.flight_outlined,
    outcome: 'Result invalidated',
    reason:
        'One of the records used by the result was removed. WhyPulse keeps the history but does not present it as current evidence.',
    signals: [
      'Travel check-in source removed',
      'Dependent explanation and chat invalidated',
      'Historical receipt preserved',
    ],
  ),
  DemoScenarioData(
    title: 'Quiet buffer before a 1:1',
    detail: 'Recovery was 9 minutes faster across 3 eligible meetings',
    badge: 'STRENGTHENED',
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
  ),
  DemoScenarioData(
    title: 'Move the 1:1 later',
    detail: 'Missing context left the three-meeting test inconclusive',
    badge: 'INCONCLUSIVE',
    color: Color(0xFFB19CFF),
    icon: Icons.schedule_rounded,
    outcome: 'The test did not resolve the question',
    reason:
        'One meeting was missed and another lacked enough heart-rate coverage, so no conclusion was promoted.',
    signals: [
      '1 eligible meeting completed',
      '1 meeting missed',
      '1 meeting lacked heart-rate coverage',
    ],
  ),
  DemoScenarioData(
    title: 'Morning workout and recovery',
    detail: 'Recovery looked faster on 4 of 6 comparable workout days',
    badge: 'PATTERN FOUND',
    color: Color(0xFFC7FF3F),
    icon: Icons.fitness_center_rounded,
    outcome: 'A second supported example',
    reason:
        'The repeated recovery windows passed the same quality, completeness, and repeatability checks used for meeting patterns.',
    signals: [
      '8 workout days checked; 6 usable',
      '4 of 6 showed faster recovery',
      'Travel days were excluded',
    ],
  ),
  DemoScenarioData(
    title: 'Consistent bedtime and morning heart rate',
    detail: 'Four paired mornings stayed within the person’s usual range',
    badge: 'NO CLEAR PATTERN',
    color: Color(0xFF6F8CFF),
    icon: Icons.dark_mode_rounded,
    outcome: 'A useful null result',
    reason:
        'The paired mornings were comparable, but the measured values did not move far enough or consistently enough to show a pattern.',
    signals: [
      '4 paired mornings compared',
      'Values remained inside the usual range',
      'The null result is retained in History',
    ],
  ),
  DemoScenarioData(
    title: 'Wearable coverage gap',
    detail: 'Only 2 of 7 event windows had enough sensor data',
    badge: 'NOT ENOUGH DATA',
    color: Color(0xFF747D78),
    icon: Icons.watch_off_outlined,
    outcome: 'More reliable data needed',
    reason:
        'Too many event windows were missing heart-rate coverage to make a fair repeated comparison.',
    signals: [
      '7 events found',
      'Only 2 had usable heart-rate windows',
      'No explanation or experiment was created',
    ],
  ),
];
