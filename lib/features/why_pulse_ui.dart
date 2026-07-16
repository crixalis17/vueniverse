import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:why_pulse/app/app_state.dart';
import 'package:why_pulse/app/theme.dart';
import 'package:why_pulse/data/seed/seed_content.dart';
import 'package:why_pulse/domain/models/app_models.dart';

void openPulsePage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: state.reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 320),
          child: step == 0
              ? _WelcomeStep(
                  key: const ValueKey('welcome'),
                  onContinue: () => setState(() => step = 1),
                )
              : step == 1
              ? _ModeStep(
                  key: const ValueKey('mode'),
                  onBack: () => setState(() => step = 0),
                  onDemo: () => state.finishOnboarding(AppMode.demo),
                  onLive: () {
                    state.setMode(AppMode.live);
                    setState(() => step = 2);
                  },
                )
              : _OnboardingSourcesStep(
                  key: const ValueKey('source-setup'),
                  onBack: () => setState(() => step = 1),
                  onContinue: () => state.finishOnboarding(AppMode.live),
                  onDemo: () => state.finishOnboarding(AppMode.demo),
                ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PulseMark(size: 34),
              const SizedBox(width: 12),
              Text('WHYPULSE', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const Spacer(),
          const Eyebrow('EVIDENCE TO ACTION'),
          const SizedBox(height: 16),
          Text(
            'Understand what repeated moments do to you.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 18),
          Text(
            'WhyPulse aligns your health signals around meaningful events, challenges the pattern, then helps you test a small change.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 30),
          const _JourneyStrip(),
          const Spacer(),
          const InlineNotice(
            icon: Icons.lock_outline_rounded,
            text:
                'Your evidence stays source-labelled. WhyPulse does not diagnose, prescribe, or invent measurements.',
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onContinue,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('See how it works'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeStep extends StatelessWidget {
  const _ModeStep({
    super.key,
    required this.onBack,
    required this.onDemo,
    required this.onLive,
  });

  final VoidCallback onBack;
  final VoidCallback onDemo;
  final VoidCallback onLive;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 20),
        const PulseMark(size: 44),
        const SizedBox(height: 28),
        const Eyebrow('CHOOSE YOUR START'),
        const SizedBox(height: 12),
        Text(
          'Begin with evidence you can inspect.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'You can switch modes later. Demo and live records are always kept separate.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 28),
        _ChoiceCard(
          icon: Icons.science_rounded,
          accent: PulseColors.lime,
          title: 'Explore the complete demo',
          badge: 'RECOMMENDED',
          description:
              'A deterministic 30-day history with a recurring-meeting fingerprint, counterevidence and completed experiment.',
          bullets: const [
            'No permissions required',
            'Positive, null and missing-data cases',
            'Safe to reset at any time',
          ],
          action: 'Explore Demo Data',
          onTap: onDemo,
        ),
        const SizedBox(height: 14),
        _ChoiceCard(
          icon: Icons.health_and_safety_rounded,
          accent: PulseColors.cyan,
          title: 'Set up your sources',
          badge: 'LIVE',
          description:
              'Start with Health Connect, a selected recurring calendar event and optional manual context.',
          bullets: const [
            'Read only the evidence you approve',
            'Pause, disconnect or delete at any time',
            'Demo remains available if data is incomplete',
          ],
          action: 'Continue to Sources',
          onTap: onLive,
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.badge,
    required this.description,
    required this.bullets,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String badge;
  final String description;
  final List<String> bullets;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AccentIcon(icon: icon, accent: accent),
                const Spacer(),
                StatusPill(label: badge, color: accent),
              ],
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, color: accent, size: 17),
                    const SizedBox(width: 9),
                    Expanded(child: Text(bullet)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(onPressed: onTap, child: Text(action)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSourcesStep extends StatelessWidget {
  const _OnboardingSourcesStep({
    super.key,
    required this.onBack,
    required this.onContinue,
    required this.onDemo,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 12),
        const Eyebrow('PREPARE EVIDENCE'),
        const SizedBox(height: 10),
        Text(
          'Choose what WhyPulse can use.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Each source is independent. You can pause, disconnect, or delete it later from the full Sources screen.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        for (final source in state.sources) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AccentIcon(icon: source.icon, accent: PulseColors.cyan),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          source.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: source.status == SourceStatus.connected,
                    onChanged: (value) => state.updateSource(
                      source.id,
                      value ? SourceStatus.connected : SourceStatus.available,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const InlineNotice(
          icon: Icons.privacy_tip_outlined,
          text:
              'Calendar titles and identity are discarded after local categorization. Health access is read-only.',
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue with selected sources'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onDemo,
          child: const Text('Use Demo Data instead'),
        ),
      ],
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip();

  static const stages = [
    ('Observe', Icons.visibility_outlined),
    ('Replay', Icons.multiline_chart_rounded),
    ('Challenge', Icons.fact_check_outlined),
    ('Explain', Icons.auto_awesome_outlined),
    ('Test', Icons.science_outlined),
    ('Learn', Icons.insights_outlined),
    ('Preserve', Icons.verified_user_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: PulseColors.textTertiary,
            size: 14,
          ),
        ),
        itemBuilder: (context, index) => Column(
          children: [
            Icon(stages[index].$2, color: PulseColors.lime, size: 22),
            const SizedBox(height: 8),
            Text(
              stages[index].$1,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class WhyPulseShell extends StatelessWidget {
  const WhyPulseShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    const screens = [
      TodayScreen(),
      HistoryScreen(),
      ExperimentsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: state.tabIndex, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science_rounded),
            label: 'Experiments',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return PulseRootScroll(
      title: 'Today',
      trailing: ModeBadge(mode: state.mode),
      children: [
        if (state.offline)
          const InlineNotice(
            icon: Icons.cloud_off_rounded,
            text: 'Offline · showing evidence saved 18 minutes ago.',
            accent: PulseColors.amber,
          ),
        SourceReadinessCard(
          onTap: () => openPulsePage(context, const SourcesScreen()),
        ),
        const SizedBox(height: 22),
        const Eyebrow('STRONGEST CURRENT FINDING'),
        const SizedBox(height: 10),
        HeroFindingCard(
          onOpen: () => openPulsePage(context, const MomentFingerprintScreen()),
          onWhy: () => openPulsePage(context, const ExplanationScreen()),
        ),
        const SizedBox(height: 12),
        AskWhyPulseEntryCard(
          onTap: () => openPulsePage(context, const AskWhyPulseScreen()),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'REPEATS',
                value: '6 / 8',
                detail: 'same direction',
                accent: PulseColors.lime,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: MetricCard(
                label: 'RECOVERY',
                value: '42m',
                detail: 'median',
                accent: PulseColors.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(
          eyebrow: 'CONTEXT',
          title: 'Add what sensors cannot see',
          action: 'Check in',
          onAction: () => openPulsePage(context, const CheckInScreen()),
        ),
        const SizedBox(height: 12),
        ContextCard(checkIn: state.checkIns.first),
        const SizedBox(height: 24),
        SectionHeader(
          eyebrow: 'EXPERIMENT',
          title: state.experimentStatus == ExperimentStatus.draft
              ? 'Test a quiet buffer'
              : 'Quiet buffer before 1:1',
          action: state.experimentStatus == ExperimentStatus.draft
              ? 'Review'
              : 'Open',
          onAction: () => state.experimentStatus == ExperimentStatus.draft
              ? openPulsePage(context, const ExperimentSetupScreen())
              : state.selectTab(2),
        ),
        const SizedBox(height: 12),
        ExperimentSummaryCard(state: state),
        const SizedBox(height: 24),
        PreviewEntryCard(
          icon: Icons.view_week_outlined,
          title: 'Weekly evidence digest',
          description:
              'A sample of how supported, weakened and null findings could be summarized.',
          onTap: () => openPulsePage(
            context,
            const PreviewScreen(type: PreviewType.weeklyDigest),
          ),
        ),
      ],
    );
  }
}

class HeroFindingCard extends StatelessWidget {
  const HeroFindingCard({super.key, required this.onOpen, required this.onWhy});

  final VoidCallback onOpen;
  final VoidCallback onWhy;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const StatusPill(label: 'SUPPORTED', color: PulseColors.lime),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'Updated 18 min ago',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Your heart rate was usually higher before your recurring 1:1.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+11', style: Theme.of(context).textTheme.displayLarge),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 6),
                    child: Text(
                      'bpm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: PulseColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Median difference from matched no-meeting windows · range +8–14 bpm',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 126, child: MiniFingerprintChart()),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onWhy,
                      child: const Text('Why this?'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onOpen,
                      child: const Text('Replay moment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AskWhyPulseEntryCard extends StatelessWidget {
  const AskWhyPulseEntryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask WhyPulse about the recurring 1:1 evidence',
      child: Card(
        color: PulseColors.cyan.withValues(alpha: 0.055),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                const AccentIcon(
                  icon: Icons.chat_bubble_outline_rounded,
                  accent: PulseColors.cyan,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ask WhyPulse',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const StatusPill(
                            label: 'EVIDENCE ONLY',
                            color: PulseColors.cyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Ask why, what disagrees, what is missing, or what to observe next.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: PulseColors.cyan,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SourceReadinessCard extends StatelessWidget {
  const SourceReadinessCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final connected = state.sources
        .where((source) => source.status == SourceStatus.connected)
        .length;
    return Semantics(
      button: true,
      label: '$connected of 4 core sources ready. Manage sources.',
      child: Card(
        color: PulseColors.surfaceAlt,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                EvidenceRing(
                  value: connected / 4,
                  color: connected == 4 ? PulseColors.lime : PulseColors.amber,
                  size: 48,
                  stroke: 4,
                  child: Text(
                    '$connected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$connected of 4 sources ready',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Evidence coverage 86% · Manage sources',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PulseColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExperimentSummaryCard extends StatelessWidget {
  const ExperimentSummaryCard({super.key, required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final draft = state.experimentStatus == ExperimentStatus.draft;
    final complete = state.experimentStatus == ExperimentStatus.completed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            EvidenceRing(
              value: draft ? 0 : state.experimentCheckIns / 3,
              color: complete ? PulseColors.mint : PulseColors.cyan,
              size: 60,
              stroke: 5,
              child: Icon(
                complete ? Icons.check_rounded : Icons.science_rounded,
                color: complete ? PulseColors.mint : PulseColors.cyan,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft
                        ? '10-minute quiet buffer'
                        : complete
                        ? 'Result ready'
                        : '${state.experimentCheckIns} of 3 meetings complete',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    draft
                        ? 'A reversible test using the same evidence windows.'
                        : complete
                        ? 'Recovery was faster in the measured test windows.'
                        : 'Next eligible 1:1 · Tuesday, 11:00 AM',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContextCard extends StatelessWidget {
  const ContextCard({super.key, required this.checkIn});

  final CheckInData checkIn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AccentIcon(icon: checkIn.icon, accent: PulseColors.amber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checkIn.context,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    checkIn.detail,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const StatusPill(label: 'CONTEXT', color: PulseColors.amber),
          ],
        ),
      ),
    );
  }
}

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final connected = state.sources
        .where((source) => source.status == SourceStatus.connected)
        .length;
    return PulseDetailScaffold(
      title: 'Sources',
      subtitle: 'Control what evidence WhyPulse can use',
      actions: [
        IconButton(
          tooltip: 'Refresh sources',
          onPressed: () {
            state.refreshSources();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Source evidence refreshed')),
            );
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        Card(
          color: PulseColors.surfaceAlt,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                EvidenceRing(
                  value: connected / 4,
                  color: PulseColors.lime,
                  size: 74,
                  stroke: 6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$connected/4',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'ready',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evidence readiness',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        connected == 4
                            ? 'Ready for recurring-event analysis'
                            : 'Some evidence will remain incomplete',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ModeBadge(mode: state.mode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Eyebrow('CORE SOURCES'),
        const SizedBox(height: 10),
        for (final source in state.sources) ...[
          SourceCard(
            source: source,
            onTap: () =>
                openPulsePage(context, SourceDetailScreen(sourceId: source.id)),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 14),
        const Eyebrow('WHAT THIS ENABLES'),
        const SizedBox(height: 10),
        const CapabilityMatrix(),
        const SizedBox(height: 24),
        PreviewEntryCard(
          icon: Icons.add_circle_outline_rounded,
          title: 'Expansion sources',
          description:
              'Wearables, activity services, clinical records and environment signals are clearly marked Later.',
          label: 'LATER',
          onTap: () => openPulsePage(context, const ExpansionScreen()),
        ),
      ],
    );
  }
}

class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.source, required this.onTap});

  final SourceData source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final connected = source.status == SourceStatus.connected;
    final color = connected ? PulseColors.mint : PulseColors.amber;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              Row(
                children: [
                  AccentIcon(icon: source.icon, accent: color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          source.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: connected
                        ? 'CONNECTED'
                        : source.status.name.toUpperCase(),
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: source.completeness / 100,
                        minHeight: 5,
                        color: color,
                        backgroundColor: PulseColors.elevated,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${source.completeness}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: PulseColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceDetailScreen extends StatelessWidget {
  const SourceDetailScreen({super.key, required this.sourceId});

  final String sourceId;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final source = state.sources.firstWhere((item) => item.id == sourceId);
    final connected = source.status == SourceStatus.connected;
    final isDemo = source.id == 'demo';
    final isCheckIn = source.id == 'checkins';
    return PulseDetailScaffold(
      title: source.name,
      subtitle: source.contribution,
      children: [
        Row(
          children: [
            AccentIcon(
              icon: source.icon,
              accent: connected ? PulseColors.mint : PulseColors.amber,
              size: 54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    label: connected ? 'CONNECTED' : 'AVAILABLE',
                    color: connected ? PulseColors.mint : PulseColors.amber,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    source.lastSync ?? 'Not synced',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Eyebrow('EVIDENCE CONTRIBUTION'),
        const SizedBox(height: 10),
        InfoPanel(
          title: source.description,
          body: source.contribution,
          icon: Icons.account_tree_outlined,
          accent: PulseColors.cyan,
        ),
        const SizedBox(height: 16),
        if (source.id == 'health') ...[
          const SourcePermissionRow(
            label: 'Heart rate',
            detail: 'Read · last 30 days',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'Sleep sessions',
            detail: 'Read · last 30 days',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'Activity & workouts',
            detail: 'Read · exclusion only',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'HRV',
            detail: 'Not available on this device',
            allowed: false,
          ),
        ] else if (source.id == 'calendar') ...[
          const SourcePermissionRow(
            label: 'Selected calendar',
            detail: 'Work · read only',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'Recurring event',
            detail: 'Weekly 1:1 · Tuesdays',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'Private content',
            detail: 'Discarded after categorization',
            allowed: false,
          ),
        ] else if (isCheckIn) ...[
          for (final entry in state.checkIns)
            Dismissible(
              key: ValueKey(entry.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: PulseColors.error.withValues(alpha: 0.16),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: PulseColors.error,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => state.deleteCheckIn(entry.id),
              child: ContextCard(checkIn: entry),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const CheckInScreen()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add check-in'),
          ),
        ] else if (isDemo) ...[
          const SourcePermissionRow(
            label: '30-day history',
            detail: 'Deterministic fixture v1.0',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'Evidence cases',
            detail: 'Positive · null · contradictory · missing',
            allowed: true,
          ),
          const SourcePermissionRow(
            label: 'Personal records',
            detail: 'Never mixed with Demo Data',
            allowed: false,
          ),
          const SizedBox(height: 14),
          InfoPanel(
            title: 'Explore deterministic evidence cases',
            body:
                'Inspect the positive, null, contradictory and missing-data experiences required by the product plan.',
            icon: Icons.dataset_outlined,
            accent: PulseColors.violet,
            action: 'Open all four cases',
            onTap: () =>
                openPulsePage(context, const DemoEvidenceCasesScreen()),
          ),
        ],
        if (!isCheckIn) ...[
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                state.updateSource(
                  source.id,
                  connected ? SourceStatus.paused : SourceStatus.connected,
                );
              },
              child: Text(
                connected
                    ? (isDemo ? 'Pause Demo Data' : 'Pause source')
                    : (isDemo ? 'Load Demo Data' : 'Connect source'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDeleteSource(context, source),
              child: Text(isDemo ? 'Reset demo' : 'Disconnect and delete data'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const InlineNotice(
          icon: Icons.info_outline_rounded,
          text:
              'Pausing stops new reads. Disconnecting and deleting also invalidates dependent evidence, explanations, experiments and exports.',
        ),
      ],
    );
  }

  void _showDeleteSource(BuildContext context, SourceData source) {
    final state = WhyPulseScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PulseColors.elevated,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccentIcon(
                icon: Icons.delete_outline_rounded,
                accent: PulseColors.error,
              ),
              const SizedBox(height: 18),
              Text(
                'Review dependent evidence',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${source.name} contributes to 2 findings, 1 experiment, 3 explanations and 1 proof artifact. Those records will be marked invalidated.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  state.updateSource(source.id, SourceStatus.available);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${source.name} data removed; dependent evidence invalidated',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: PulseColors.error,
                  foregroundColor: PulseColors.text,
                ),
                child: const Text('Delete and invalidate'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep source'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourcePermissionRow extends StatelessWidget {
  const SourcePermissionRow({
    super.key,
    required this.label,
    required this.detail,
    required this.allowed,
  });

  final String label;
  final String detail;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            allowed
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            color: allowed ? PulseColors.mint : PulseColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class CapabilityMatrix extends StatelessWidget {
  const CapabilityMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Moment detection', 'Calendar', true),
      ('Physiology fingerprint', 'Health Connect', true),
      ('Possible influences', 'Check-ins + Health', true),
      ('Matched experiment', 'All core sources', true),
      ('Complete fallback', 'Demo Data', true),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: PulseColors.mint,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(rows[i].$1)),
                  Text(
                    rows[i].$2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (i != rows.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filter = 'All';
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final items = seedHistory.where((item) {
      final matchesFilter = filter == 'All' || item.status == filter;
      final normalized = query.trim().toLowerCase();
      final matchesQuery =
          normalized.isEmpty ||
          item.title.toLowerCase().contains(normalized) ||
          item.subtitle.toLowerCase().contains(normalized);
      return matchesFilter && matchesQuery;
    }).toList();
    return PulseRootScroll(
      title: 'History',
      subtitle: 'Versioned findings, tests and proof',
      children: [
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'Search findings and experiments',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final value in [
                'All',
                'Supported',
                'Developing',
                'Null finding',
                'Weakened',
                'Expired',
              ]) ...[
                FilterChip(
                  selected: filter == value,
                  label: Text(value),
                  onSelected: (_) => setState(() => filter = value),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final item in items) ...[
          HistoryCard(
            item: item,
            onTap: () {
              if (item.id == 'quiet-buffer-result') {
                openPulsePage(context, const ExperimentResultScreen());
              } else if (item.id == 'meeting-heart-rate') {
                openPulsePage(context, const MomentFingerprintScreen());
              } else {
                openPulsePage(context, FindingStatusScreen(item: item));
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        if (items.isEmpty)
          const InfoPanel(
            title: 'No matching evidence',
            body: 'Try another phrase or remove the current status filter.',
            icon: Icons.search_off_rounded,
            accent: PulseColors.nullBlue,
          ),
        if (filter == 'All' && query.trim().isEmpty) ...[
          const SizedBox(height: 14),
          InfoPanel(
            title: 'Demo evidence cases',
            body:
                'Verify supported, null, contradictory and missing-data outcomes without a model.',
            icon: Icons.dataset_outlined,
            accent: PulseColors.violet,
            action: 'Open deterministic cases',
            onTap: () =>
                openPulsePage(context, const DemoEvidenceCasesScreen()),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            eyebrow: 'CONTEXT HISTORY',
            title: 'Manual check-ins',
          ),
          const SizedBox(height: 10),
          for (final entry in state.checkIns.take(2)) ...[
            ContextCard(checkIn: entry),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 12),
        InfoPanel(
          title: 'Evidence changes when its sources change',
          body:
              'Past versions remain inspectable. Deleted source records mark dependent results as invalidated instead of silently rewriting history.',
          icon: Icons.history_toggle_off_rounded,
          accent: PulseColors.violet,
          onTap: () => openPulsePage(context, const ProofScreen()),
          action: 'Open evidence ledger',
        ),
      ],
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.item, required this.onTap});

  final HistoryItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: item.invalidated ? PulseColors.surfaceAlt : PulseColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccentIcon(icon: item.icon, accent: item.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(
                          label: item.status.toUpperCase(),
                          color: item.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.date,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FindingStatusScreen extends StatelessWidget {
  const FindingStatusScreen({super.key, required this.item});

  final HistoryItemData item;

  @override
  Widget build(BuildContext context) {
    final (statusTitle, statusBody, statusIcon) = switch (item.status) {
      'Null finding' => (
        'No repeatable association yet',
        'The available windows vary too much to support a repeated difference. This negative result is preserved rather than hidden.',
        Icons.remove_circle_outline_rounded,
      ),
      'Weakened' => (
        'New evidence weakened the pattern',
        'After illness days were excluded, the remaining effect became smaller and less consistent. The previous version remains inspectable.',
        Icons.trending_down_rounded,
      ),
      'Expired' => (
        'Dependent source data was removed',
        'This result is preserved as history but cannot be treated as current evidence. Its source dependency and invalidation date remain visible.',
        Icons.history_toggle_off_rounded,
      ),
      _ => (
        'Still developing',
        'WhyPulse needs more comparable windows before promoting this pattern.',
        Icons.hourglass_bottom_rounded,
      ),
    };
    return PulseDetailScaffold(
      title: item.title,
      subtitle: item.status,
      children: [
        AccentIcon(icon: item.icon, accent: item.accent, size: 62),
        const SizedBox(height: 22),
        Text(item.subtitle, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        InfoPanel(
          title: statusTitle,
          body: statusBody,
          icon: statusIcon,
          accent: item.accent,
        ),
        if (item.invalidated) ...[
          const SizedBox(height: 12),
          const InlineNotice(
            icon: Icons.link_off_rounded,
            text:
                'Invalidated Jul 2 · Calendar records removed · explanation and export marked stale.',
            accent: PulseColors.amber,
          ),
        ],
        const SizedBox(height: 16),
        const SourceProvenanceList(),
        if (item.invalidated) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => openPulsePage(context, const SourcesScreen()),
            icon: const Icon(Icons.hub_outlined),
            label: const Text('Review source dependencies'),
          ),
        ],
      ],
    );
  }
}

enum DemoEvidenceCaseType { positive, nullFinding, contradictory, missing }

class DemoEvidenceCasesScreen extends StatelessWidget {
  const DemoEvidenceCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const cases = [
      (
        DemoEvidenceCaseType.positive,
        'Supported repeated pattern',
        'Six comparable meetings show a repeatable pre-event rise.',
        Icons.trending_up_rounded,
        PulseColors.lime,
        'SUPPORTED',
      ),
      (
        DemoEvidenceCaseType.nullFinding,
        'Null finding',
        'Three comparable nights do not support a caffeine–sleep pattern.',
        Icons.remove_circle_outline_rounded,
        PulseColors.nullBlue,
        'NULL',
      ),
      (
        DemoEvidenceCaseType.contradictory,
        'Contradictory evidence',
        'Signals disagree, so the candidate finding is not promoted.',
        Icons.balance_rounded,
        PulseColors.amber,
        'CONTRADICTORY',
      ),
      (
        DemoEvidenceCaseType.missing,
        'Missing-data result',
        'Coverage is below the evidence gate and no result is invented.',
        Icons.data_array_outlined,
        PulseColors.coral,
        'INCOMPLETE',
      ),
    ];
    return PulseDetailScaffold(
      title: 'Demo Evidence Cases',
      subtitle: 'Deterministic outcomes · no model required',
      children: [
        const InlineNotice(
          icon: Icons.science_outlined,
          text:
              'These four fictional cases verify that WhyPulse can support, reject, challenge, or withhold a finding honestly.',
          accent: PulseColors.violet,
        ),
        const SizedBox(height: 20),
        for (final item in cases) ...[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                if (item.$1 == DemoEvidenceCaseType.positive) {
                  openPulsePage(context, const MomentFingerprintScreen());
                } else if (item.$1 == DemoEvidenceCaseType.nullFinding) {
                  final nullItem = seedHistory.firstWhere(
                    (historyItem) => historyItem.id == 'sleep-null',
                  );
                  openPulsePage(context, FindingStatusScreen(item: nullItem));
                } else {
                  openPulsePage(
                    context,
                    DemoEvidenceCaseDetailScreen(type: item.$1),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccentIcon(icon: item.$4, accent: item.$5),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.$2,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              StatusPill(label: item.$6, color: item.$5),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$3,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PulseColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class DemoEvidenceCaseDetailScreen extends StatelessWidget {
  const DemoEvidenceCaseDetailScreen({super.key, required this.type});

  final DemoEvidenceCaseType type;

  @override
  Widget build(BuildContext context) {
    final contradictory = type == DemoEvidenceCaseType.contradictory;
    final title = contradictory ? 'Contradictory Evidence' : 'Missing Data';
    final accent = contradictory ? PulseColors.amber : PulseColors.coral;
    return PulseDetailScaffold(
      title: title,
      subtitle: contradictory
          ? 'Candidate finding not promoted'
          : 'Evidence gate not reached',
      children: [
        StatusPill(
          label: contradictory ? 'CONTRADICTORY' : 'INSUFFICIENT DATA',
          color: accent,
        ),
        const SizedBox(height: 18),
        Text(
          contradictory
              ? 'The available signals do not tell one consistent story.'
              : 'WhyPulse does not have enough complete windows to produce a finding.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        if (contradictory) ...[
          const SignalAgreementCard(),
          const SizedBox(height: 14),
          const CounterEvidenceCard(),
          const SizedBox(height: 14),
          const InfoPanel(
            title: 'Promotion stopped',
            body:
                'Heart rate points upward, but recovery and sleep move inconsistently. Counterevidence is too strong to show a supported finding.',
            icon: Icons.block_rounded,
            accent: PulseColors.amber,
          ),
        ] else ...[
          const _MissingCoverageCard(),
          const SizedBox(height: 14),
          const InfoPanel(
            title: 'What is needed next',
            body:
                'At least two more complete event windows and matching baseline periods are required. No value is estimated for the gaps.',
            icon: Icons.add_chart_rounded,
            accent: PulseColors.cyan,
          ),
        ],
        const SizedBox(height: 18),
        const SourceProvenanceList(),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => openPulsePage(context, const SourcesScreen()),
          icon: const Icon(Icons.hub_outlined),
          label: const Text('Review contributing sources'),
        ),
      ],
    );
  }
}

class _MissingCoverageCard extends StatelessWidget {
  const _MissingCoverageCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Comparable events', '2 of 4 required', 0.5),
      ('Heart-rate coverage', '58% of required window', 0.58),
      ('Matched controls', '1 of 4 required', 0.25),
      ('Manual context', 'Illness unknown', 0.4),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final row in rows) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.$1),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: row.$3,
                            minHeight: 6,
                            color: PulseColors.coral,
                            backgroundColor: PulseColors.elevated,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 112,
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (row != rows.last) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class MomentFingerprintScreen extends StatelessWidget {
  const MomentFingerprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseDetailScaffold(
      title: 'Moment Fingerprint',
      subtitle: 'Weekly 1:1 · 6 included traces',
      actions: [
        IconButton(
          tooltip: 'View proof',
          onPressed: () => openPulsePage(context, const ProofScreen()),
          icon: const Icon(Icons.verified_user_outlined),
        ),
      ],
      children: [
        Row(
          children: [
            const StatusPill(label: 'SUPPORTED', color: PulseColors.lime),
            const SizedBox(width: 8),
            const StatusPill(label: 'DEMO', color: PulseColors.violet),
            const Spacer(),
            Text(
              'Jun 2 – Jul 14',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'A repeatable rise before the meeting',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Individual traces remain visible so the median never hides variability.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        const FingerprintChartCard(),
        const SizedBox(height: 12),
        const ChartLegend(),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'BEFORE',
                value: '+11',
                detail: 'bpm vs baseline',
                accent: PulseColors.coral,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'RECOVERY',
                value: '42m',
                detail: 'median',
                accent: PulseColors.cyan,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'COVERAGE',
                value: '86%',
                detail: '2 gaps',
                accent: PulseColors.lime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const TimelineWindowCard(),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => openPulsePage(context, const EvidenceScreen()),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Challenge the evidence'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              openPulsePage(context, const ExperimentSetupScreen()),
          icon: const Icon(Icons.science_outlined),
          label: const Text('Test this'),
        ),
      ],
    );
  }
}

class FingerprintChartCard extends StatelessWidget {
  const FingerprintChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Moment Fingerprint chart. Six meeting traces rise between 8 and 14 beats per minute before the meeting, peak near the start, and return toward baseline after a median of 42 minutes. Two windows have missing context.',
      child: Card(
        color: PulseColors.raisedCanvas,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Text(
                      'HEART RATE · BPM',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Spacer(),
                    const StatusPill(
                      label: '6 TRACES',
                      color: PulseColors.cyan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 260, child: MomentFingerprintChart()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('−30m', style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      'Meeting starts',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: PulseColors.lime),
                    ),
                    Text('+60m', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        LegendItem(label: 'Median', color: PulseColors.lime),
        LegendItem(label: 'Individual traces', color: PulseColors.cyan),
        LegendItem(label: 'Matched baseline', color: PulseColors.violet),
        LegendItem(label: 'Missing', color: PulseColors.amber),
      ],
    );
  }
}

class TimelineWindowCard extends StatelessWidget {
  const TimelineWindowCard({super.key});

  @override
  Widget build(BuildContext context) {
    const windows = [
      ('10:45', 'Before', '72 → 84 bpm', PulseColors.coral),
      ('11:00', 'Meeting', 'Peak 88 bpm', PulseColors.lime),
      ('11:30', 'Recovery', 'Returned by 11:42', PulseColors.cyan),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('EVENT WINDOW'),
            const SizedBox(height: 14),
            for (var i = 0; i < windows.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: windows[i].$4,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 48, child: Text(windows[i].$1)),
                  Expanded(
                    child: Text(
                      windows[i].$2,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    windows[i].$3,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (i != windows.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 3, bottom: 3),
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(color: PulseColors.borderStrong),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  bool caffeineAdded = false;

  @override
  Widget build(BuildContext context) {
    return PulseDetailScaffold(
      title: 'Evidence',
      subtitle: 'Challenge the recurring 1:1 finding',
      actions: [
        IconButton(
          tooltip: 'Manage sources',
          onPressed: () => openPulsePage(context, const SourcesScreen()),
          icon: const Icon(Icons.hub_outlined),
        ),
      ],
      children: [
        const InlineNotice(
          icon: Icons.fact_check_outlined,
          text:
              'Every number below was computed before an explanation was generated.',
          accent: PulseColors.lime,
        ),
        const SizedBox(height: 12),
        AskWhyPulseEntryCard(
          onTap: () => openPulsePage(context, const AskWhyPulseScreen()),
        ),
        const SizedBox(height: 20),
        const Eyebrow('VERIFIED MEASURES'),
        const SizedBox(height: 10),
        for (final fact in meetingEvidence) ...[
          EvidenceFactCard(fact: fact),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const SectionHeader(
          eyebrow: 'MATCHED COMPARISON',
          title: 'Like-for-like windows',
        ),
        const SizedBox(height: 10),
        const ComparisonCard(),
        const SizedBox(height: 24),
        const SectionHeader(
          eyebrow: 'SIGNAL AGREEMENT',
          title: 'What agrees—and what does not',
        ),
        const SizedBox(height: 10),
        const SignalAgreementCard(),
        const SizedBox(height: 24),
        SectionHeader(
          eyebrow: 'POSSIBLE INFLUENCES',
          title: 'Context that could weaken this',
          action: caffeineAdded ? 'Updated' : 'Add context',
          onAction: caffeineAdded ? null : () => _addInfluence(context),
        ),
        const SizedBox(height: 10),
        InfluenceCard(
          caffeineAdded: caffeineAdded,
          onEdit: () => _addInfluence(context),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          eyebrow: 'COUNTEREVIDENCE',
          title: 'Where the pattern did not hold',
        ),
        const SizedBox(height: 10),
        const CounterEvidenceCard(),
        const SizedBox(height: 24),
        const SectionHeader(
          eyebrow: 'PROMOTION GATES',
          title: 'Why this is shown as supported',
        ),
        const SizedBox(height: 10),
        const PromotionGatesCard(),
        const SizedBox(height: 24),
        const SectionHeader(
          eyebrow: 'PROVENANCE',
          title: 'Trace every claim to its source',
        ),
        const SizedBox(height: 10),
        const SourceProvenanceList(),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => openPulsePage(context, const ExplanationScreen()),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Explain this evidence'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              openPulsePage(context, const ExperimentSetupScreen()),
          icon: const Icon(Icons.science_outlined),
          label: const Text('Test this'),
        ),
      ],
    );
  }

  Future<void> _addInfluence(BuildContext context) async {
    var selected = '1 coffee before 10 AM';
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PulseColors.elevated,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('CORRECT THE EVIDENCE'),
                const SizedBox(height: 10),
                Text(
                  'Add caffeine context',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This changes completeness and recomputes affected windows. It does not directly change the measured heart rate.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in [
                      'No caffeine',
                      '1 coffee before 10 AM',
                      '2+ coffees',
                      'Unknown',
                    ])
                      ChoiceChip(
                        label: Text(value),
                        selected: selected == value,
                        onSelected: (_) =>
                            setSheetState(() => selected = value),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save and recompute'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true && context.mounted) {
      setState(() => caffeineAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidence updated · completeness is now 93%'),
        ),
      );
    }
  }
}

class EvidenceFactCard extends StatelessWidget {
  const EvidenceFactCard({super.key, required this.fact});

  final EvidenceFact fact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 62,
              decoration: BoxDecoration(
                color: fact.accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fact.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fact.detail,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    fact.source,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: fact.accent),
                  ),
                ],
              ),
            ),
            Text(
              fact.value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: fact.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const _ComparisonRow(
              label: 'Meeting windows',
              value: '84 bpm',
              detail: '6 included',
              color: PulseColors.coral,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: StatusPill(
                      label: 'VS',
                      color: PulseColors.textTertiary,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            const _ComparisonRow(
              label: 'Matched no-meeting windows',
              value: '73 bpm',
              detail: '12 controls · same weekday/time',
              color: PulseColors.violet,
            ),
            const SizedBox(height: 16),
            const InlineNotice(
              icon: Icons.filter_alt_outlined,
              text:
                  'Three active windows and one travel week were excluded before comparison.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Text(detail, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class SignalAgreementCard extends StatelessWidget {
  const SignalAgreementCard({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Heart rate', 'Supports', PulseColors.lime, 0.92),
      ('Recovery duration', 'Supports', PulseColors.cyan, 0.78),
      ('Activity', 'Excluded', PulseColors.violet, 0.58),
      ('Sleep', 'Mixed', PulseColors.amber, 0.43),
      ('HRV', 'Missing', PulseColors.nullBlue, 0.2),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final row in rows) ...[
              Row(
                children: [
                  SizedBox(width: 120, child: Text(row.$1)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: row.$4,
                        minHeight: 7,
                        color: row.$3,
                        backgroundColor: PulseColors.elevated,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 64,
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: row.$3),
                    ),
                  ),
                ],
              ),
              if (row != rows.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class InfluenceCard extends StatelessWidget {
  const InfluenceCard({
    super.key,
    required this.caffeineAdded,
    required this.onEdit,
  });

  final bool caffeineAdded;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Recent activity',
        '3 active windows excluded',
        Icons.directions_run_rounded,
        PulseColors.mint,
      ),
      (
        'Caffeine',
        caffeineAdded
            ? '1 coffee recorded · 1 day still unknown'
            : 'Missing on 2 meeting days',
        Icons.coffee_rounded,
        caffeineAdded ? PulseColors.mint : PulseColors.amber,
      ),
      (
        'Illness',
        'No illness check-ins',
        Icons.sick_outlined,
        PulseColors.mint,
      ),
      (
        'Sleep duration',
        'Signals point in different directions',
        Icons.bedtime_outlined,
        PulseColors.amber,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final row in rows) ...[
              Row(
                children: [
                  Icon(row.$3, color: row.$4, size: 21),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          row.$2,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (row.$1 == 'Caffeine')
                    IconButton(
                      tooltip: 'Edit caffeine context',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),
              if (row != rows.last)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class CounterEvidenceCard extends StatelessWidget {
  const CounterEvidenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PulseColors.amber.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AccentIcon(
                  icon: Icons.balance_rounded,
                  accent: PulseColors.amber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '2 of 8 meetings did not show the rise',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'One followed a shorter night; one had incomplete pre-event heart-rate coverage. These windows remain visible and reduce repeatability.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class PromotionGatesCard extends StatelessWidget {
  const PromotionGatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('At least 4 comparable events', '8 available', true),
      ('Matched control windows', '12 controls', true),
      ('Data completeness ≥ 75%', '86%', true),
      ('Consistent direction', '6 of 8', true),
      ('No dominant measured influence', 'None found', true),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final row in rows) ...[
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: PulseColors.lime,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(row.$1)),
                  Text(row.$2, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              if (row != rows.last) const SizedBox(height: 13),
            ],
          ],
        ),
      ),
    );
  }
}

class SourceProvenanceList extends StatelessWidget {
  const SourceProvenanceList({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        Icons.health_and_safety_rounded,
        'Health Connect',
        'Heart rate · 30 days · synced 8m ago',
      ),
      (
        Icons.calendar_month_rounded,
        'Android Calendar',
        'Recurring category only · synced 12m ago',
      ),
      (
        Icons.edit_note_rounded,
        'Manual check-ins',
        'Caffeine unknown on 2 days',
      ),
      (
        Icons.functions_rounded,
        'Deterministic analysis',
        'meeting-hr v1.4 · no model calculations',
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final row in rows) ...[
              Row(
                children: [
                  Icon(row.$1, color: PulseColors.cyan, size: 21),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.$2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          row.$3,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_outlined,
                    color: PulseColors.mint,
                    size: 19,
                  ),
                ],
              ),
              if (row != rows.last)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseDetailScaffold(
      title: 'Explanation',
      subtitle: 'Bounded to this evidence bundle',
      actions: [
        IconButton(
          tooltip: 'Ask WhyPulse',
          onPressed: () => openPulsePage(context, const AskWhyPulseScreen()),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      ],
      children: [
        Row(
          children: [
            const StatusPill(label: 'EVIDENCE-CITED', color: PulseColors.lime),
            const Spacer(),
            const ModelRuntimeBadge(),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Your heart rate was usually higher before this recurring meeting.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        const CitedParagraph(
          text:
              'Across six comparable meetings, the median pre-event heart rate was 11 bpm above matched no-meeting windows at a similar time of day.',
          citations: ['+11 bpm', '6 included', '12 controls'],
        ),
        const SizedBox(height: 12),
        const CitedParagraph(
          text:
              'The pattern remained after active windows and a travel week were excluded. Recovery typically took 42 minutes.',
          citations: ['Activity filter', '42 min recovery'],
        ),
        const SizedBox(height: 24),
        const InfoPanel(
          title: 'What could weaken this',
          body:
              'Two meetings did not show the same rise, and caffeine context is missing on two days. The evidence supports a repeated association, not a cause.',
          icon: Icons.balance_outlined,
          accent: PulseColors.amber,
        ),
        const SizedBox(height: 14),
        const InfoPanel(
          title: 'What remains unknown',
          body:
              'WhyPulse cannot tell whether the meeting itself caused the change or whether an unmeasured influence contributed.',
          icon: Icons.help_outline_rounded,
          accent: PulseColors.nullBlue,
        ),
        const SizedBox(height: 18),
        const InlineNotice(
          icon: Icons.shield_outlined,
          text:
              'This is a personal evidence summary—not a diagnosis, treatment recommendation, or health verdict.',
          accent: PulseColors.violet,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => openPulsePage(context, const AskWhyPulseScreen()),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Ask about this evidence'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              openPulsePage(context, const ExperimentSetupScreen()),
          icon: const Icon(Icons.science_outlined),
          label: const Text('Test this'),
        ),
      ],
    );
  }
}

class CitedParagraph extends StatelessWidget {
  const CitedParagraph({
    super.key,
    required this.text,
    required this.citations,
  });

  final String text;
  final List<String> citations;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final citation in citations) EvidenceChip(label: citation),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AskWhyPulseScreen extends StatefulWidget {
  const AskWhyPulseScreen({super.key});

  @override
  State<AskWhyPulseScreen> createState() => _AskWhyPulseScreenState();
}

class _AskWhyPulseScreenState extends State<AskWhyPulseScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask WhyPulse'),
            Text(
              'Recurring 1:1 evidence only',
              style: TextStyle(fontSize: 12, color: PulseColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: PulseColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: InlineNotice(
                icon: Icons.lock_outline_rounded,
                text: 'This conversation cannot access your complete timeline.',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (state.chatMessages.isEmpty) ...[
                    const _AssistantIntro(),
                    const SizedBox(height: 18),
                    Text(
                      'TRY ASKING',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    for (final prompt in [
                      'Why was this promoted?',
                      'Could exercise explain this?',
                      'What disagrees with this pattern?',
                      'What evidence is missing?',
                      'What should I observe next?',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: () => state.ask(prompt),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(prompt),
                          ),
                        ),
                      ),
                  ] else
                    for (final message in state.chatMessages)
                      ChatBubble(message: message),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: PulseColors.raisedCanvas,
                border: Border(top: BorderSide(color: PulseColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _send(state),
                      decoration: const InputDecoration(
                        hintText: 'Ask why, what weakens it, or what next…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send question',
                    onPressed: () => _send(state),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(WhyPulseState state) {
    state.ask(controller.text);
    controller.clear();
  }
}

class _AssistantIntro extends StatelessWidget {
  const _AssistantIntro();

  @override
  Widget build(BuildContext context) {
    return const ChatBubble(
      message: ChatMessageData(
        text:
            'I can explain why this finding was promoted, what evidence disagrees, and what you could observe next.',
        fromUser: false,
        evidence: ['Evidence bundle v3'],
        uncertainty: 'I cannot diagnose or recommend treatment.',
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessageData message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: message.fromUser
              ? PulseColors.lime.withValues(alpha: 0.14)
              : PulseColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message.fromUser ? PulseColors.lime : PulseColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text),
            if (message.evidence.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in message.evidence)
                    EvidenceChip(label: item),
                ],
              ),
            ],
            if (message.uncertainty != null) ...[
              const SizedBox(height: 10),
              Text(
                message.uncertainty!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: PulseColors.amber),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExperimentsScreen extends StatelessWidget {
  const ExperimentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return PulseRootScroll(
      title: 'Experiments',
      subtitle: 'Small changes, measured against the same evidence',
      children: [
        if (state.experimentStatus == ExperimentStatus.draft)
          _ExperimentEmptyState(
            onStart: () =>
                openPulsePage(context, const ExperimentSetupScreen()),
          )
        else if (state.experimentStatus == ExperimentStatus.completed)
          _CompletedExperimentCard(
            onOpen: () =>
                openPulsePage(context, const ExperimentResultScreen()),
          )
        else if (state.experimentStatus == ExperimentStatus.invalidated)
          const InfoPanel(
            title: 'Experiment stopped',
            body:
                'Completed observations were preserved, but this experiment cannot produce a supported result.',
            icon: Icons.stop_circle_outlined,
            accent: PulseColors.amber,
          )
        else
          ActiveExperimentCard(state: state),
        const SizedBox(height: 26),
        const SectionHeader(eyebrow: 'PAST TESTS', title: 'What you learned'),
        const SizedBox(height: 10),
        HistoryCard(
          item: seedHistory[1],
          onTap: () => openPulsePage(context, const ExperimentResultScreen()),
        ),
        const SizedBox(height: 14),
        InfoPanel(
          title: 'Deterministic result cases',
          body:
              'Inspect how the same experiment can strengthen, weaken, leave unchanged, or fail to resolve a finding.',
          icon: Icons.account_tree_outlined,
          accent: PulseColors.violet,
          action: 'Open all four outcomes',
          onTap: () =>
              openPulsePage(context, const ExperimentOutcomeCasesScreen()),
        ),
        const SizedBox(height: 24),
        PreviewEntryCard(
          icon: Icons.tune_rounded,
          title: 'What-if Lab',
          description:
              'Explore a read-only sample of how a future protocol could change one measured response.',
          onTap: () => openPulsePage(
            context,
            const PreviewScreen(type: PreviewType.whatIf),
          ),
        ),
      ],
    );
  }
}

class _ExperimentEmptyState extends StatelessWidget {
  const _ExperimentEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AccentIcon(
              icon: Icons.science_outlined,
              accent: PulseColors.cyan,
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              'Test a supported finding',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Experiments begin from evidence—not from a generic goal. Your recurring 1:1 finding has a reversible test ready.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                child: const Text('Review proposed test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveExperimentCard extends StatelessWidget {
  const ActiveExperimentCard({super.key, required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final paused = state.experimentStatus == ExperimentStatus.paused;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(
                  label: paused ? 'PAUSED' : 'ACTIVE',
                  color: paused ? PulseColors.amber : PulseColors.cyan,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${state.experimentCheckIns}/3 eligible meetings',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                EvidenceRing(
                  value: state.experimentCheckIns / 3,
                  color: PulseColors.cyan,
                  size: 82,
                  stroke: 7,
                  child: Text(
                    '${state.experimentCheckIns}/3',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '10-minute quiet buffer',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        paused
                            ? 'Resume before the next eligible meeting.'
                            : 'Next: Tuesday · 10:50 AM',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SourcePermissionRow(
              label: 'Health evidence',
              detail: 'Ready',
              allowed: true,
            ),
            const SourcePermissionRow(
              label: 'Calendar occurrence',
              detail: 'Eligible',
              allowed: true,
            ),
            const SourcePermissionRow(
              label: 'Context check-in',
              detail: 'Required after meeting',
              allowed: true,
            ),
            const SizedBox(height: 14),
            if (!paused)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.completeExperimentOccurrence,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Complete occurrence check-in'),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.toggleExperimentPause,
                    child: Text(paused ? 'Resume' : 'Pause'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => _confirmStop(context, state),
                    child: const Text('Stop experiment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmStop(BuildContext context, WhyPulseState state) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop this experiment?'),
        content: const Text(
          'Completed observations will be preserved, but the result will be marked incomplete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep running'),
          ),
          FilledButton(
            onPressed: () {
              state.stopExperiment();
              Navigator.pop(context);
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}

class _CompletedExperimentCard extends StatelessWidget {
  const _CompletedExperimentCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PulseColors.mint.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                StatusPill(label: 'RESULT READY', color: PulseColors.mint),
                Spacer(),
                Icon(Icons.check_circle_rounded, color: PulseColors.mint),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Recovery was faster with the quiet buffer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '3 of 3 eligible meetings · all required evidence persisted',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('View result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExperimentSetupScreen extends StatefulWidget {
  const ExperimentSetupScreen({super.key});

  @override
  State<ExperimentSetupScreen> createState() => _ExperimentSetupScreenState();
}

class _ExperimentSetupScreenState extends State<ExperimentSetupScreen> {
  bool reminders = true;
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return PulseDetailScaffold(
      title: 'Test This',
      subtitle: 'A reversible test from verified evidence',
      children: [
        const StatusPill(label: 'PROPOSED PROTOCOL', color: PulseColors.cyan),
        const SizedBox(height: 18),
        Text(
          'Take a 10-minute quiet buffer before your next 3 weekly 1:1s.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 14),
        const InlineNotice(
          icon: Icons.link_rounded,
          text: 'Tests the supported recurring 1:1 evidence bundle v3.',
          accent: PulseColors.lime,
        ),
        const SizedBox(height: 24),
        const ProtocolSection(
          number: '01',
          title: 'Small change',
          detail:
              'No calls, messages or work during the 10 minutes before the meeting.',
          icon: Icons.self_improvement_rounded,
        ),
        const ProtocolSection(
          number: '02',
          title: 'Same measurements',
          detail:
              'Pre-meeting heart rate and recovery duration, using the original matched windows.',
          icon: Icons.monitor_heart_outlined,
        ),
        const ProtocolSection(
          number: '03',
          title: 'Context check',
          detail:
              'Record caffeine, exercise, illness and whether you followed the buffer.',
          icon: Icons.edit_note_rounded,
        ),
        const ProtocolSection(
          number: '04',
          title: 'Three eligible meetings',
          detail:
              'Skipped, missing or rescheduled occurrences stay visible and do not count.',
          icon: Icons.event_repeat_rounded,
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: reminders,
          onChanged: (value) => setState(() => reminders = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('In-app reminder'),
          subtitle: const Text('10 minutes before an eligible meeting'),
        ),
        CheckboxListTile(
          value: confirmed,
          onChanged: (value) => setState(() => confirmed = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'I understand this is a personal test, not treatment.',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: confirmed
              ? () {
                  state.activateExperiment();
                  Navigator.pop(context);
                  state.selectTab(2);
                }
              : null,
          child: const Text('Start 3-meeting experiment'),
        ),
      ],
    );
  }
}

class ProtocolSection extends StatelessWidget {
  const ProtocolSection({
    super.key,
    required this.number,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String number;
  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              number,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: PulseColors.cyan),
            ),
          ),
          AccentIcon(icon: icon, accent: PulseColors.cyan),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExperimentResultScreen extends StatelessWidget {
  const ExperimentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseDetailScaffold(
      title: 'Experiment Result',
      subtitle: 'Quiet buffer · 3 eligible meetings',
      children: [
        const StatusPill(label: 'STRENGTHENED', color: PulseColors.mint),
        const SizedBox(height: 18),
        Text(
          'Recovery was faster with the quiet buffer.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'The original association remains supported, and the test adds measured evidence about one reversible change.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 24),
        const BeforeAfterCard(),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'BEFORE',
                value: '42m',
                detail: 'recovery',
                accent: PulseColors.coral,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'WITH BUFFER',
                value: '33m',
                detail: 'recovery',
                accent: PulseColors.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const InfoPanel(
          title: 'What this result supports',
          body:
              'Across three eligible meetings, recovery was 6–12 minutes faster with the buffer. All three moved in the same direction.',
          icon: Icons.trending_down_rounded,
          accent: PulseColors.mint,
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          title: 'Limitations',
          body:
              'Three meetings are a small personal sample. This does not prove the buffer caused the change or predict future meetings.',
          icon: Icons.balance_outlined,
          accent: PulseColors.amber,
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => openPulsePage(context, const ProofScreen()),
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Preserve result and proof'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A repeat protocol is ready for review'),
            ),
          ),
          child: const Text('Repeat experiment'),
        ),
      ],
    );
  }
}

class ExperimentOutcomeCasesScreen extends StatelessWidget {
  const ExperimentOutcomeCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const outcomes = [
      (
        ExperimentOutcome.strengthened,
        'Strengthened',
        'The measured change repeated the original direction.',
        Icons.trending_up_rounded,
        PulseColors.mint,
      ),
      (
        ExperimentOutcome.weakened,
        'Weakened',
        'The measured change did not repeat the expected improvement.',
        Icons.trending_down_rounded,
        PulseColors.coral,
      ),
      (
        ExperimentOutcome.unchanged,
        'Unchanged',
        'The measured response stayed inside the original range.',
        Icons.trending_flat_rounded,
        PulseColors.nullBlue,
      ),
      (
        ExperimentOutcome.inconclusive,
        'Inconclusive',
        'Too few eligible observations had complete evidence.',
        Icons.help_outline_rounded,
        PulseColors.amber,
      ),
    ];
    return PulseDetailScaffold(
      title: 'Experiment Outcomes',
      subtitle: 'Deterministic Demo Data · four honest result states',
      children: [
        const InlineNotice(
          icon: Icons.rule_rounded,
          text:
              'The result state follows predeclared evidence gates. An explanation cannot promote or rescue an incomplete experiment.',
          accent: PulseColors.violet,
        ),
        const SizedBox(height: 20),
        for (final outcome in outcomes) ...[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => openPulsePage(
                context,
                outcome.$1 == ExperimentOutcome.strengthened
                    ? const ExperimentResultScreen()
                    : ExperimentOutcomeScreen(outcome: outcome.$1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccentIcon(icon: outcome.$4, accent: outcome.$5),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  outcome.$2,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              StatusPill(
                                label: outcome.$2.toUpperCase(),
                                color: outcome.$5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            outcome.$3,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PulseColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class ExperimentOutcomeScreen extends StatelessWidget {
  const ExperimentOutcomeScreen({super.key, required this.outcome});

  final ExperimentOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (
      label,
      accent,
      headline,
      summary,
      afterValue,
      evidenceTitle,
      evidenceBody,
      limitationBody,
    ) = switch (outcome) {
      ExperimentOutcome.weakened => (
        'WEAKENED',
        PulseColors.coral,
        'The quiet buffer did not repeat the expected improvement.',
        'Two complete meetings moved in opposite directions. The original finding remains in History, but this test lowers confidence in the proposed change.',
        '45m',
        'What changed',
        'One meeting recovered 5 minutes faster and one recovered 11 minutes slower. The predeclared direction did not repeat.',
        'Only two observations were complete. A third was preserved as missing and was not estimated.',
      ),
      ExperimentOutcome.unchanged => (
        'UNCHANGED',
        PulseColors.nullBlue,
        'Recovery stayed within the original range.',
        'The quiet buffer produced no meaningful measured difference across three eligible meetings. The original association is neither strengthened nor weakened.',
        '41m',
        'What the comparison shows',
        'The median changed by 1 minute, inside the predeclared 5-minute minimum difference. WhyPulse reports this as unchanged.',
        'An unchanged result applies to this protocol and sample. It does not prove that every kind of pre-meeting buffer is ineffective.',
      ),
      ExperimentOutcome.inconclusive => (
        'INCONCLUSIVE',
        PulseColors.amber,
        'There is not enough complete evidence to resolve the test.',
        'Only one of three eligible meetings had every required measurement and context check. WhyPulse withholds an outcome instead of filling the gaps.',
        '1/3',
        'Evidence gate not reached',
        'Meeting 1 was complete. Meeting 2 lacked the post-event heart-rate window. Meeting 3 had no adherence check-in.',
        'No before/after effect is calculated from one complete observation. The protocol can be repeated from a new version.',
      ),
      ExperimentOutcome.strengthened => throw StateError(
        'Strengthened outcomes use ExperimentResultScreen.',
      ),
    };
    final afterLabel = outcome == ExperimentOutcome.inconclusive
        ? 'COMPLETE'
        : 'WITH BUFFER';
    return PulseDetailScaffold(
      title: 'Experiment Result',
      subtitle: 'Quiet buffer · deterministic Demo Data',
      children: [
        StatusPill(label: label, color: accent),
        const SizedBox(height: 18),
        Text(headline, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          summary,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: MetricCard(
                label: 'BEFORE',
                value: '42m',
                detail: 'recovery',
                accent: PulseColors.coral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: afterLabel,
                value: afterValue,
                detail: outcome == ExperimentOutcome.inconclusive
                    ? 'eligible meetings'
                    : 'recovery',
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        InfoPanel(
          title: evidenceTitle,
          body: evidenceBody,
          icon: outcome == ExperimentOutcome.inconclusive
              ? Icons.rule_folder_outlined
              : Icons.compare_arrows_rounded,
          accent: accent,
        ),
        const SizedBox(height: 12),
        InfoPanel(
          title: 'Limitations',
          body: limitationBody,
          icon: Icons.balance_outlined,
          accent: PulseColors.amber,
        ),
        const SizedBox(height: 18),
        const SourceProvenanceList(),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => openPulsePage(context, const ProofScreen()),
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Preserve result and proof'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new protocol version is ready for review'),
            ),
          ),
          child: const Text('Repeat from a new version'),
        ),
      ],
    );
  }
}

class BeforeAfterCard extends StatelessWidget {
  const BeforeAfterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PulseColors.raisedCanvas,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('MATCHED BEFORE / AFTER'),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _BeforeAfterPainter(),
                size: Size.infinite,
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LegendItem(label: 'Original', color: PulseColors.coral),
                SizedBox(width: 18),
                LegendItem(label: 'With buffer', color: PulseColors.mint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return PulseRootScroll(
      title: 'Settings',
      subtitle: 'Privacy, runtime and presentation',
      children: [
        SettingsGroup(
          title: 'EVIDENCE',
          children: [
            SettingsRow(
              icon: Icons.hub_outlined,
              title: 'Sources',
              subtitle: '4 core sources · 86% evidence coverage',
              accent: PulseColors.lime,
              onTap: () => openPulsePage(context, const SourcesScreen()),
            ),
            SettingsRow(
              icon: Icons.science_outlined,
              title: 'Data mode',
              subtitle: state.mode == AppMode.demo
                  ? 'Demo Data · isolated from live records'
                  : 'Live records · Demo kept separate',
              accent: PulseColors.violet,
              onTap: () => _showModeSheet(context, state),
            ),
            SettingsRow(
              icon: Icons.verified_user_outlined,
              title: 'Proof & exports',
              subtitle: '1 current proof artifact',
              accent: PulseColors.cyan,
              onTap: () => openPulsePage(context, const ProofScreen()),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsGroup(
          title: 'PRIVACY & CONTROL',
          children: [
            SettingsRow(
              icon: Icons.lock_outline_rounded,
              title: 'How local evidence works',
              subtitle: 'Sources, models and retention explained',
              accent: PulseColors.mint,
              onTap: () => openPulsePage(context, const PrivacyScreen()),
            ),
            SettingsRow(
              icon: Icons.delete_outline_rounded,
              title: 'Delete all app data',
              subtitle: 'Review dependencies before deletion',
              accent: PulseColors.error,
              onTap: () => _showDeleteAll(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsGroup(
          title: 'ACCESSIBILITY',
          children: [
            SwitchListTile.adaptive(
              value: state.reducedMotion,
              onChanged: state.setReducedMotion,
              secondary: const Icon(
                Icons.motion_photos_off_outlined,
                color: PulseColors.cyan,
              ),
              title: const Text('Reduce motion'),
              subtitle: const Text('Use fades instead of tracing and scanning'),
            ),
            const Divider(),
            const SettingsRow(
              icon: Icons.insert_chart_outlined,
              title: 'Chart text alternatives',
              subtitle: 'Always available below visual evidence',
              accent: PulseColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsGroup(
          title: 'PRODUCT',
          children: [
            SettingsRow(
              icon: Icons.add_circle_outline_rounded,
              title: 'Expansion',
              subtitle: 'Future sources and capabilities · Later',
              accent: PulseColors.violet,
              onTap: () => openPulsePage(context, const ExpansionScreen()),
            ),
            SettingsRow(
              icon: Icons.info_outline_rounded,
              title: 'About WhyPulse',
              subtitle: 'App 0.1.0 · analysis meeting-hr v1.4',
              accent: PulseColors.textSecondary,
              onTap: () => openPulsePage(context, const AboutScreen()),
            ),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: state.resetDemo,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset deterministic demo'),
        ),
      ],
    );
  }

  void _showModeSheet(BuildContext context, WhyPulseState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PulseColors.elevated,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose data mode',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Modes use separate namespaces and are never silently mixed.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              ListTile(
                selected: state.mode == AppMode.live,
                leading: Icon(
                  state.mode == AppMode.live
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: const Text('Live evidence'),
                subtitle: const Text('Health Connect, Calendar and check-ins'),
                onTap: () {
                  state.setMode(AppMode.live);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                selected: state.mode == AppMode.demo,
                leading: Icon(
                  state.mode == AppMode.demo
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: const Text('Demo Data'),
                subtitle: const Text('Deterministic fictional history'),
                onTap: () {
                  state.setMode(AppMode.demo);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all WhyPulse data?'),
        content: const Text(
          'This removes source records, findings, explanations, experiments, chats and proof artifacts. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PulseColors.error),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Deletion preview complete · no data removed in Demo mode',
                  ),
                ),
              );
            },
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(title),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 68,
      onTap: onTap,
      leading: Icon(icon, color: accent),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PulseDetailScaffold(
      title: 'Privacy & Data',
      subtitle: 'How evidence moves through WhyPulse',
      children: [
        InfoPanel(
          title: 'Source-minimized',
          body:
              'WhyPulse reads only the fields needed for reviewed analyses. Calendar identity and unnecessary content are discarded after local categorization.',
          icon: Icons.filter_alt_outlined,
          accent: PulseColors.lime,
        ),
        SizedBox(height: 12),
        InfoPanel(
          title: 'Evidence before language',
          body:
              'Deterministic code calculates every displayed number. The explainer receives a bounded evidence bundle, never unrestricted raw history.',
          icon: Icons.fact_check_outlined,
          accent: PulseColors.cyan,
        ),
        SizedBox(height: 12),
        InfoPanel(
          title: 'Dependency-aware deletion',
          body:
              'Deleting a source also removes its records and marks dependent findings, experiments and proof artifacts invalid.',
          icon: Icons.delete_sweep_outlined,
          accent: PulseColors.coral,
        ),
        SizedBox(height: 12),
        InfoPanel(
          title: 'Live and Demo stay separate',
          body:
              'Every record carries its namespace. The app never silently uses fictional data to fill gaps in live evidence.',
          icon: Icons.call_split_rounded,
          accent: PulseColors.violet,
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseDetailScaffold(
      title: 'About WhyPulse',
      subtitle: 'Evidence to action—not another health dashboard',
      children: [
        const PulseMark(size: 72),
        const SizedBox(height: 22),
        Text('WhyPulse', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Android prototype · 0.1.0 (1)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        const SourcePermissionRow(
          label: 'Analysis runtime',
          detail: 'meeting-hr v1.4',
          allowed: true,
        ),
        const SourcePermissionRow(
          label: 'Explanation runtime',
          detail: 'Deterministic fallback',
          allowed: true,
        ),
        const SourcePermissionRow(
          label: 'Evidence schema',
          detail: 'v3',
          allowed: true,
        ),
        const SourcePermissionRow(
          label: 'Data horizon',
          detail: 'Rolling 30 days',
          allowed: true,
        ),
        const SizedBox(height: 18),
        const InlineNotice(
          icon: Icons.code_rounded,
          text:
              'Built with Codex. Model-assisted development never receives personal health records.',
        ),
      ],
    );
  }
}

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String caffeine = 'None yet';
  String exercise = 'No recent exercise';
  String illness = 'Not ill';
  String mood = 'Steady';
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return PulseDetailScaffold(
      title: 'Manual Check-in',
      subtitle: 'Context—not a physiological measurement',
      children: [
        const InlineNotice(
          icon: Icons.info_outline_rounded,
          text:
              'Your answers can explain missing context. They do not overwrite sensor evidence.',
          accent: PulseColors.amber,
        ),
        const SizedBox(height: 22),
        CheckInChoice(
          label: 'CAFFEINE',
          value: caffeine,
          options: const ['None yet', '1 coffee', '2+ coffees', 'Unknown'],
          onChanged: (value) => setState(() => caffeine = value),
        ),
        CheckInChoice(
          label: 'EXERCISE',
          value: exercise,
          options: const [
            'No recent exercise',
            'Light activity',
            'Workout',
            'Unknown',
          ],
          onChanged: (value) => setState(() => exercise = value),
        ),
        CheckInChoice(
          label: 'ILLNESS',
          value: illness,
          options: const [
            'Not ill',
            'Possible symptoms',
            'Ill',
            'Prefer not to say',
          ],
          onChanged: (value) => setState(() => illness = value),
        ),
        CheckInChoice(
          label: 'PERCEIVED STATE',
          value: mood,
          options: const ['Calm', 'Steady', 'Tense', 'Drained'],
          onChanged: (value) => setState(() => mood = value),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: note,
          maxLines: 3,
          maxLength: 180,
          decoration: const InputDecoration(
            labelText: 'Optional note',
            hintText: 'Anything else that may matter?',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            state.addCheckIn(
              CheckInData(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                when: DateTime.now(),
                context: 'Manual context',
                detail: '$mood · $caffeine · $exercise',
                icon: Icons.edit_note_rounded,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save contextual evidence'),
        ),
      ],
    );
  }
}

class CheckInChoice extends StatelessWidget {
  const CheckInChoice({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: option == value,
                  onSelected: (_) => onChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProofScreen extends StatelessWidget {
  const ProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Investigation', 'meeting-heart-rate · finding v3'),
      ('Namespace', 'Demo Data · fixture v1.0'),
      ('Source window', 'Jun 2 – Jul 14 · rolling 30 days'),
      ('Included / excluded', '6 included · 2 contradictory · 4 excluded'),
      ('Completeness', '86% · caffeine missing on 2 days'),
      ('Matched baseline', '12 same-weekday, same-time controls'),
      ('Analytical version', 'meeting-hr v1.4'),
      ('Explanation runtime', 'Deterministic fallback · guarded'),
      ('Safety result', 'Passed · no unsupported claims'),
      ('Deletion state', 'Current · all dependencies present'),
    ];
    return PulseDetailScaffold(
      title: 'Proof & Export',
      subtitle: 'A portable record of how this finding was produced',
      children: [
        const Row(
          children: [
            StatusPill(label: 'CURRENT', color: PulseColors.mint),
            SizedBox(width: 8),
            StatusPill(label: 'DEMO', color: PulseColors.violet),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 118,
                        child: Text(
                          rows[i].$1,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rows[i].$2,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  if (i != rows.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const ProofHashCard(),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Human-readable proof prepared locally'),
            ),
          ),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Create readable report'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evidence bundle JSON prepared locally'),
            ),
          ),
          icon: const Icon(Icons.data_object_rounded),
          label: const Text('Export evidence bundle'),
        ),
        const SizedBox(height: 20),
        PreviewEntryCard(
          icon: Icons.medical_information_outlined,
          title: 'Reviewed Clinician Report',
          description:
              'A read-only sample showing sources, evidence, uncertainty and redactions.',
          onTap: () => openPulsePage(
            context,
            const PreviewScreen(type: PreviewType.clinicianReport),
          ),
        ),
      ],
    );
  }
}

class ProofHashCard extends StatelessWidget {
  const ProofHashCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PulseColors.lime.withValues(alpha: 0.06),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: PulseColors.lime),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INTEGRITY HASH',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: PulseColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '7D4A · 91C2 · 0F8B · 33E1',
                    style: TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(label: 'VERIFIED', color: PulseColors.lime),
          ],
        ),
      ),
    );
  }
}

enum PreviewType { weeklyDigest, whatIf, clinicianReport }

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.type});

  final PreviewType type;

  @override
  Widget build(BuildContext context) {
    final title = switch (type) {
      PreviewType.weeklyDigest => 'Weekly Evidence Digest',
      PreviewType.whatIf => 'What-if Lab',
      PreviewType.clinicianReport => 'Clinician Report',
    };
    final subtitle = switch (type) {
      PreviewType.weeklyDigest =>
        'A sample week across supported and null findings',
      PreviewType.whatIf => 'A simulated protocol—not measured behavior',
      PreviewType.clinicianReport =>
        'A reviewed sample with no live clinical claims',
    };
    return PulseDetailScaffold(
      title: title,
      subtitle: subtitle,
      children: [
        const StatusPill(
          label: 'PREVIEW · SAMPLE DATA',
          color: PulseColors.violet,
        ),
        const SizedBox(height: 20),
        if (type == PreviewType.weeklyDigest) const WeeklyDigestPreview(),
        if (type == PreviewType.whatIf) const WhatIfPreview(),
        if (type == PreviewType.clinicianReport) const ClinicianReportPreview(),
        const SizedBox(height: 20),
        const InlineNotice(
          icon: Icons.visibility_outlined,
          text:
              'This polished sample uses the same evidence language but is not a measured live capability.',
          accent: PulseColors.violet,
        ),
      ],
    );
  }
}

class WeeklyDigestPreview extends StatelessWidget {
  const WeeklyDigestPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your evidence this week',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        const InfoPanel(
          title: '1 supported pattern',
          body: 'Recurring-meeting heart-rate association · 6 of 8 repeats.',
          icon: Icons.trending_up_rounded,
          accent: PulseColors.lime,
        ),
        const SizedBox(height: 10),
        const InfoPanel(
          title: '1 developing pattern',
          body: 'Evening walks need two more comparable nights.',
          icon: Icons.hourglass_bottom_rounded,
          accent: PulseColors.mint,
        ),
        const SizedBox(height: 10),
        const InfoPanel(
          title: '1 null finding',
          body: 'No repeatable caffeine–sleep association yet.',
          icon: Icons.remove_circle_outline_rounded,
          accent: PulseColors.nullBlue,
        ),
      ],
    );
  }
}

class WhatIfPreview extends StatelessWidget {
  const WhatIfPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore one measured response',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 18),
        const InfoPanel(
          title: 'If the quiet buffer were 15 minutes…',
          body:
              'WhyPulse would propose a separate three-meeting protocol. It would not forecast a health outcome.',
          icon: Icons.tune_rounded,
          accent: PulseColors.violet,
        ),
        const SizedBox(height: 14),
        Slider(value: 10, min: 5, max: 20, divisions: 3, onChanged: null),
        const Center(child: Text('10 minute sample protocol')),
      ],
    );
  }
}

class ClinicianReportPreview extends StatelessWidget {
  const ClinicianReportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal evidence summary',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Jun 2 – Jul 14 · user-reviewed fields only',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        const CitedParagraph(
          text:
              'Observed: heart rate was usually higher before a selected recurring event. This is not a diagnosis or causal conclusion.',
          citations: ['6 events', '+8–14 bpm', '86% complete'],
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          title: 'Redactions',
          body:
              'Event title, attendees, location, notes and raw free text excluded.',
          icon: Icons.visibility_off_outlined,
          accent: PulseColors.coral,
        ),
      ],
    );
  }
}

class ExpansionScreen extends StatelessWidget {
  const ExpansionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseDetailScaffold(
      title: 'Expansion',
      subtitle: 'Future capabilities · no unfinished integrations',
      children: [
        const InlineNotice(
          icon: Icons.schedule_rounded,
          text:
              'Later items explain direction only. They never request permissions or display fake connection states.',
          accent: PulseColors.violet,
        ),
        const SizedBox(height: 22),
        const Eyebrow('FUTURE SOURCES'),
        const SizedBox(height: 10),
        for (final source in expansionSources) ...[
          ExpansionCard(source: source),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const Eyebrow('FUTURE EXPERIENCES'),
        const SizedBox(height: 10),
        for (final feature in const [
          (
            'Multimodal Journal',
            'Reviewed photo or voice context',
            Icons.perm_media_outlined,
          ),
          (
            'Shared Analysis Packs',
            'Audited reusable investigation specs',
            Icons.inventory_2_outlined,
          ),
          (
            'Quiet Intelligence',
            'Low-interruption evidence updates',
            Icons.notifications_off_outlined,
          ),
          (
            'Adaptive presentation',
            'Accessibility-led information density',
            Icons.auto_awesome_motion_outlined,
          ),
          (
            'iOS',
            'Platform expansion after Android validation',
            Icons.phone_iphone_rounded,
          ),
        ]) ...[
          Card(
            child: ListTile(
              minTileHeight: 72,
              leading: Icon(feature.$3, color: PulseColors.violet),
              title: Text(feature.$1),
              subtitle: Text(feature.$2),
              trailing: const StatusPill(
                label: 'LATER',
                color: PulseColors.violet,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class ExpansionCard extends StatelessWidget {
  const ExpansionCard({super.key, required this.source});

  final SourceData source;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 78,
        leading: AccentIcon(icon: source.icon, accent: PulseColors.violet),
        title: Text(source.name),
        subtitle: Text('${source.description}\n${source.contribution}'),
        isThreeLine: true,
        trailing: const StatusPill(label: 'LATER', color: PulseColors.violet),
      ),
    );
  }
}

class PulseRootScroll extends StatelessWidget {
  const PulseRootScroll({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey(title),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          sliver: SliverList.list(children: children),
        ),
      ],
    );
  }
}

class PulseDetailScaffold extends StatelessWidget {
  const PulseDetailScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        actions: actions,
        backgroundColor: PulseColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: children,
        ),
      ),
    );
  }
}

class PulseMark extends StatelessWidget {
  const PulseMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WhyPulse',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: PulseColors.lime,
          borderRadius: BorderRadius.circular(size * 0.31),
          boxShadow: [
            BoxShadow(
              color: PulseColors.lime.withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Icon(
          Icons.multiline_chart_rounded,
          color: PulseColors.canvas,
          size: size * 0.58,
        ),
      ),
    );
  }
}

class AccentIcon extends StatelessWidget {
  const AccentIcon({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 44,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: accent, size: size * 0.5),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 9.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class ModeBadge extends StatelessWidget {
  const ModeBadge({super.key, required this.mode});

  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final demo = mode == AppMode.demo;
    return StatusPill(
      label: demo ? 'DEMO' : 'LIVE',
      color: demo ? PulseColors.violet : PulseColors.mint,
    );
  }
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.icon,
    required this.text,
    this.accent = PulseColors.textSecondary,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final String label;
  final String value;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 9),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: accent, fontSize: 24),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    this.action,
    this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccentIcon(icon: icon, accent: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    if (action != null) ...[
                      const SizedBox(height: 9),
                      Text(
                        action!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PulseColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreviewEntryCard extends StatelessWidget {
  const PreviewEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.label = 'PREVIEW',
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PulseColors.violet.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              AccentIcon(icon: icon, accent: PulseColors.violet),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusPill(label: label, color: PulseColors.violet),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: PulseColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EvidenceChip extends StatelessWidget {
  const EvidenceChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: PulseColors.lime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: PulseColors.lime.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_rounded, color: PulseColors.lime, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PulseColors.lime,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class ModelRuntimeBadge extends StatelessWidget {
  const ModelRuntimeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Deterministic evidence template · output guard passed',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.memory_rounded, color: PulseColors.cyan, size: 17),
          SizedBox(width: 6),
          Text(
            'FALLBACK · GUARDED',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: PulseColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  const LegendItem({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class EvidenceRing extends StatelessWidget {
  const EvidenceRing({
    super.key,
    required this.value,
    required this.color,
    required this.size,
    required this.stroke,
    required this.child,
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = WhyPulseScope.of(context).reducedMotion;
    return Semantics(
      label: '${(value.clamp(0, 1) * 100).round()} percent complete',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) => CustomPaint(
            painter: _RingPainter(
              value: animatedValue,
              color: color,
              stroke: stroke,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class MiniFingerprintChart extends StatelessWidget {
  const MiniFingerprintChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _FingerprintPainter(compact: true),
      size: Size.infinite,
    );
  }
}

class MomentFingerprintChart extends StatelessWidget {
  const MomentFingerprintChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _FingerprintPainter(compact: false),
      size: Size.infinite,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.stroke,
  });

  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = PulseColors.borderStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class _FingerprintPainter extends CustomPainter {
  const _FingerprintPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = compact ? 0.0 : 12.0;
    final rect = Rect.fromLTWH(
      inset,
      8,
      size.width - inset * 2,
      size.height - 20,
    );
    final gridPaint = Paint()
      ..color = PulseColors.border.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = rect.top + rect.height * i / 4;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
    final eventX = rect.left + rect.width * 0.34;
    canvas.drawRect(
      Rect.fromLTRB(
        eventX,
        rect.top,
        rect.left + rect.width * 0.66,
        rect.bottom,
      ),
      Paint()..color = PulseColors.lime.withValues(alpha: 0.035),
    );
    canvas.drawLine(
      Offset(eventX, rect.top),
      Offset(eventX, rect.bottom),
      Paint()
        ..color = PulseColors.lime.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );
    final baselineY = rect.top + rect.height * 0.67;
    canvas.drawLine(
      Offset(rect.left, baselineY),
      Offset(rect.right, baselineY),
      Paint()
        ..color = PulseColors.violet.withValues(alpha: 0.7)
        ..strokeWidth = compact ? 1 : 1.5,
    );

    for (var trace = 0; trace < 6; trace++) {
      final path = Path();
      for (var i = 0; i <= 48; i++) {
        final t = i / 48;
        final x = rect.left + rect.width * t;
        final rise = math.exp(-math.pow((t - 0.43) / 0.19, 2));
        final ripple = math.sin((t * 5.8 + trace * 0.7) * math.pi) * 0.018;
        final yFraction = 0.68 - rise * (0.25 + trace * 0.012) + ripple;
        final y = rect.top + rect.height * yFraction;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = PulseColors.cyan.withValues(alpha: compact ? 0.18 : 0.24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = compact ? 1 : 1.2,
      );
    }

    final median = Path();
    for (var i = 0; i <= 64; i++) {
      final t = i / 64;
      final x = rect.left + rect.width * t;
      final rise = math.exp(-math.pow((t - 0.43) / 0.19, 2));
      final recoveryTail = t > 0.55 ? (t - 0.55) * 0.04 : 0;
      final y = rect.top + rect.height * (0.68 - rise * 0.29 + recoveryTail);
      if (i == 0) {
        median.moveTo(x, y);
      } else {
        median.lineTo(x, y);
      }
    }
    canvas.drawPath(
      median,
      Paint()
        ..color = PulseColors.lime
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = compact ? 2.3 : 3,
    );

    if (!compact) {
      final missingPaint = Paint()
        ..color = PulseColors.amber
        ..strokeWidth = 2;
      for (final xFraction in [0.76, 0.79]) {
        final x = rect.left + rect.width * xFraction;
        canvas.drawLine(
          Offset(x, rect.bottom - 12),
          Offset(x + 6, rect.bottom - 12),
          missingPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter oldDelegate) => false;
}

class _BeforeAfterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 20);
    for (var i = 0; i < 4; i++) {
      final y = rect.top + rect.height * i / 3;
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        Paint()
          ..color = PulseColors.border
          ..strokeWidth = 1,
      );
    }
    void drawTrace(
      Color color,
      double amplitude,
      double recovery,
      double width,
    ) {
      final path = Path();
      for (var i = 0; i <= 60; i++) {
        final t = i / 60;
        final x = rect.left + rect.width * t;
        final rise = math.exp(-math.pow((t - 0.39) / width, 2));
        final tail = t > 0.5 ? (t - 0.5) * recovery : 0;
        final y = rect.top + rect.height * (0.7 - rise * amplitude + tail);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    drawTrace(PulseColors.coral, 0.32, 0.12, 0.2);
    drawTrace(PulseColors.mint, 0.24, 0.04, 0.17);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
