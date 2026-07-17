import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:why_pulse/app/app_state.dart';
import 'package:why_pulse/app/theme.dart';
import 'package:why_pulse/data/demo/demo_ui_content.dart';
import 'package:why_pulse/domain/models/app_models.dart';
import 'package:why_pulse/platform/generated/model_download_api.g.dart';

void openPulsePage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var step = 0;
  WhyPulseState? _modelDownloadPollingState;

  void _setStep(int value) {
    if (step != 3 && value == 3) {
      final state = WhyPulseScope.of(context);
      _modelDownloadPollingState = state;
      state.beginModelDownloadPolling();
    } else if (step == 3 && value != 3) {
      _modelDownloadPollingState?.endModelDownloadPolling();
      _modelDownloadPollingState = null;
    }
    setState(() => step = value);
  }

  @override
  void dispose() {
    _modelDownloadPollingState?.endModelDownloadPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: state.reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: switch (step) {
            0 => _WelcomeStep(
              key: const ValueKey('welcome'),
              onContinue: () => _setStep(1),
            ),
            1 => _ChooseModeStep(
              key: const ValueKey('mode'),
              onBack: () => _setStep(0),
              onDemo: () => state.finishOnboarding(AppMode.demo),
              onLive: () {
                _setStep(2);
                unawaited(state.inspectModelDownload());
              },
            ),
            2 => _SourceSetupStep(
              key: const ValueKey('sources'),
              onBack: () => _setStep(1),
              onContinue: () => _setStep(3),
              onDemo: () => state.finishOnboarding(AppMode.demo),
            ),
            _ => _ModelDownloadConsentStep(
              key: const ValueKey('model-download'),
              status: state.modelDownloadStatus,
              operationInProgress: state.modelDownloadOperationInProgress,
              onBack: () => _setStep(2),
              onDownload: () async {
                final current = state.modelDownloadStatus.state;
                final status = switch (current) {
                  ModelDownloadState.available ||
                  ModelDownloadState.queued ||
                  ModelDownloadState.downloading ||
                  ModelDownloadState.verifying => state.modelDownloadStatus,
                  ModelDownloadState.failed || ModelDownloadState.cancelled =>
                    await state.retryModelDownload(),
                  _ => await state.acceptAndStartModelDownload(),
                };
                if (!mounted || !_modelDownloadCanEnterLive(status)) {
                  return;
                }
                state.finishOnboarding(AppMode.live);
              },
            ),
          },
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        const Row(
          children: [
            PulseMark(),
            SizedBox(width: 12),
            Text('WHYPULSE', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 72),
        const StatusPill(
          label: 'PRIVATE · ON DEVICE',
          color: PulseColors.mint,
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 20),
        Text(
          'Understand what repeated moments do to you.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'WhyPulse compares recurring events with your own health baseline, shows what supports the pattern, and helps you test one small change.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onContinue,
          child: const Text('See how it works'),
        ),
        const SizedBox(height: 28),
        Text('How it works', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const SurfaceCard(
          child: Column(
            children: [
              _OnboardingPoint(
                number: '1',
                title: 'Observe',
                detail: 'Bring health signals and selected events together.',
              ),
              Divider(height: 28),
              _OnboardingPoint(
                number: '2',
                title: 'Understand',
                detail: 'See the comparison, limits, and counterevidence.',
              ),
              Divider(height: 28),
              _OnboardingPoint(
                number: '3',
                title: 'Test',
                detail: 'Try a small change and keep the result in History.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'WhyPulse describes personal patterns. It does not diagnose or recommend treatment.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: PulseColors.lime.withValues(alpha: 0.14),
          child: Text(
            number,
            style: const TextStyle(
              color: PulseColors.lime,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
    );
  }
}

class _ChooseModeStep extends StatelessWidget {
  const _ChooseModeStep({
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose how to start',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Both modes use the same app. Their data and encryption keys stay completely separate.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 28),
        SurfaceCard(
          accent: PulseColors.lime,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(label: 'RECOMMENDED', color: PulseColors.lime),
              const SizedBox(height: 16),
              Text(
                'Explore fictional data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'A repeatable 30-day story lets you inspect evidence, ask scoped questions, and try an experiment without permissions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDemo,
                  child: const Text('Explore Demo Data'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(label: 'ANDROID', color: PulseColors.cyan),
              const SizedBox(height: 16),
              Text(
                'Use my own data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Review Health Connect, recurring Calendar events, and Manual check-ins before anything is saved.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onLive,
                  child: const Text('Continue to Sources'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceSetupStep extends StatelessWidget {
  const _SourceSetupStep({
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
    const sources = [
      (
        Icons.health_and_safety_outlined,
        'Health Connect',
        'Heart rate, sleep, steps, and workouts',
      ),
      (
        Icons.calendar_month_outlined,
        'Android Calendar',
        'Only recurring events you review',
      ),
      (
        Icons.edit_note_outlined,
        'Manual check-ins',
        'Caffeine, exercise, illness, mood, and travel',
      ),
      (
        Icons.science_outlined,
        'Demo Data',
        'Fictional data; always separate from Live',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose what WhyPulse can use.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Nothing is connected on this screen. You will review each permission and recurring event next.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 24),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < sources.length; index++) ...[
                ListTile(
                  leading: Icon(sources[index].$1),
                  title: Text(sources[index].$2),
                  subtitle: Text(sources[index].$3),
                  trailing: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: PulseColors.mint,
                  ),
                ),
                if (index != sources.length - 1) const Divider(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NoticeBox(
          icon: Icons.privacy_tip_outlined,
          text:
              'Calendar titles are shown only during review. WhyPulse keeps the category and timing—not names, attendees, or descriptions.',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue with selected sources'),
        ),
        TextButton(onPressed: onDemo, child: const Text('Use Demo instead')),
      ],
    );
  }
}

class _ModelDownloadConsentStep extends StatelessWidget {
  const _ModelDownloadConsentStep({
    super.key,
    required this.status,
    required this.operationInProgress,
    required this.onBack,
    required this.onDownload,
  });

  final ModelDownloadStatus status;
  final bool operationInProgress;
  final VoidCallback onBack;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    final configured = _modelDownloadConfigurationUsable(status);
    final ready = status.state == ModelDownloadState.available;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: operationInProgress ? null : onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 12),
        const StatusPill(
          label: 'ON-DEVICE AI · LIVE',
          color: PulseColors.cyan,
          icon: Icons.memory_rounded,
        ),
        const SizedBox(height: 18),
        Text(
          ready
              ? 'Your on-device model is ready.'
              : 'Prepare private on-device explanations.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'WhyPulse downloads a 2.49 GB MedGemma model on unmetered Wi-Fi. The download continues in the background and Android shows its progress.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 24),
        const SurfaceCard(
          child: Column(
            children: [
              _OnboardingPoint(
                number: '1',
                title: 'Stays on this device',
                detail:
                    'Live evidence is sent only to the phone-local runtime.',
              ),
              Divider(height: 28),
              _OnboardingPoint(
                number: '2',
                title: 'Works after download',
                detail:
                    'Explanations can run offline once model verification finishes.',
              ),
              Divider(height: 28),
              _OnboardingPoint(
                number: '3',
                title: 'Safe fallback remains',
                detail:
                    'WhyPulse stays deterministic while the model is unavailable.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        NoticeBox(
          icon: configured ? Icons.wifi_rounded : Icons.developer_mode_rounded,
          text: configured
              ? _modelDownloadSummary(status)
              : status.detail == 'invalid_url'
              ? 'This build has an invalid model URL. WHYPULSE_MODEL_DOWNLOAD_URL must be a direct HTTPS GGUF file.'
              : 'This build has no model URL. Set WHYPULSE_MODEL_DOWNLOAD_URL to an HTTPS GGUF file before using Live.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: !configured || operationInProgress ? null : onDownload,
          icon: Icon(ready ? Icons.check_rounded : Icons.download_rounded),
          label: Text(
            operationInProgress
                ? 'Preparing download…'
                : ready
                ? 'Continue to Live'
                : 'Download model',
          ),
        ),
      ],
    );
  }
}

class _LiveModelConsentScreen extends StatelessWidget {
  const _LiveModelConsentScreen();

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: _ModelDownloadConsentStep(
          status: state.modelDownloadStatus,
          operationInProgress: state.modelDownloadOperationInProgress,
          onBack: () => Navigator.pop(context),
          onDownload: () async {
            final current = state.modelDownloadStatus.state;
            final status = switch (current) {
              ModelDownloadState.failed ||
              ModelDownloadState.cancelled => await state.retryModelDownload(),
              ModelDownloadState.available ||
              ModelDownloadState.queued ||
              ModelDownloadState.downloading ||
              ModelDownloadState.verifying => state.modelDownloadStatus,
              _ => await state.acceptAndStartModelDownload(),
            };
            if (!context.mounted || !_modelDownloadCanEnterLive(status)) {
              return;
            }
            state.setMode(AppMode.live);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

String _modelDownloadSummary(ModelDownloadStatus status) {
  final downloaded = _formatModelBytes(status.downloadedBytes);
  final total = _formatModelBytes(status.totalBytes);
  return switch (status.state) {
    ModelDownloadState.notConfigured => 'Model download is not configured.',
    ModelDownloadState.requiresConsent =>
      'Ready to download on unmetered Wi-Fi after you confirm.',
    ModelDownloadState.queued =>
      'Queued · waiting for unmetered Wi-Fi, storage, and battery.',
    ModelDownloadState.downloading =>
      '${status.progress.toStringAsFixed(0)}% · $downloaded of $total downloaded.',
    ModelDownloadState.verifying =>
      'Download complete · checking exact size and SHA-256.',
    ModelDownloadState.available =>
      'Verified and ready for private, offline explanations.',
    ModelDownloadState.failed => _modelDownloadFailureDetail(
      status.detail ?? 'download_failed',
    ),
    ModelDownloadState.cancelled =>
      'Download cancelled. The partial file is saved for resume.',
  };
}

String _modelDownloadFailureDetail(String detail) => switch (detail) {
  'insufficient_storage' =>
    'Not enough free storage. Free space, then tap Retry.',
  'unauthorized' => 'The model host rejected access (HTTP 401).',
  'forbidden' => 'The model host rejected access (HTTP 403).',
  'not_found' => 'The configured model file was not found (HTTP 404).',
  'invalid_url' => 'The model URL must be a direct HTTPS file URL.',
  'integrity_failed' ||
  'integrity_check_failed' ||
  'size_mismatch' ||
  'checksum_mismatch' =>
    'The downloaded file failed verification. Tap Retry to start cleanly.',
  'platform_unavailable' =>
    'Android model download services are unavailable in this build.',
  _ => 'Download failed (${detail.replaceAll('_', ' ')}).',
};

bool _modelDownloadConfigurationUsable(ModelDownloadStatus status) =>
    status.state != ModelDownloadState.notConfigured &&
    !(status.state == ModelDownloadState.failed &&
        status.detail == 'invalid_url');

bool _modelDownloadCanEnterLive(ModelDownloadStatus status) =>
    _modelDownloadConfigurationUsable(status) &&
    status.state != ModelDownloadState.requiresConsent;

String _formatModelBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const gb = 1000 * 1000 * 1000;
  const mb = 1000 * 1000;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  return '${(bytes / mb).toStringAsFixed(0)} MB';
}

class WhyPulseShell extends StatelessWidget {
  const WhyPulseShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    const pages = [
      TodayScreen(),
      HistoryScreen(),
      ExperimentsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: state.tabIndex, children: pages),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science_rounded),
            label: 'Experiments',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
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
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('today-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList.list(
              children: [
                PageIntro(
                  title: 'Today',
                  subtitle: state.mode == AppMode.demo
                      ? 'A fictional snapshot, calculated from the Demo store.'
                      : 'Your latest local evidence and anything that needs attention.',
                  trailing: ModeBadge(mode: state.mode),
                ),
                const SizedBox(height: 24),
                _ReadinessCard(state: state),
                const SizedBox(height: 28),
                if (state.finding?.isCurrent ?? false) ...[
                  SectionTitle(
                    title: 'What stands out',
                    subtitle: state.mode == AppMode.demo
                        ? 'One fictional supported pattern, with its limits kept visible.'
                        : 'A current local finding, with its limits kept visible.',
                  ),
                  const SizedBox(height: 12),
                  PrimaryInsightCard(
                    finding: state.finding,
                    onTap: () =>
                        openPulsePage(context, const MomentFingerprintScreen()),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Ask WhyPulse about the recurring 1:1 evidence',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          openPulsePage(context, const AskWhyPulseScreen()),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Ask about this pattern'),
                    ),
                  ),
                ] else ...[
                  const SectionTitle(title: 'What stands out'),
                  const SizedBox(height: 12),
                  EmptyState(
                    icon: Icons.query_stats_rounded,
                    title: state.mode == AppMode.live
                        ? 'No Live finding yet'
                        : 'No current Demo finding',
                    detail: state.mode == AppMode.live
                        ? 'A finding appears only after Live source data passes deterministic analysis and evidence gates. Demo findings never appear here.'
                        : 'Reset Demo to restore its deterministic fictional evidence.',
                  ),
                ],
                const SizedBox(height: 28),
                SectionTitle(
                  title: 'Recent context',
                  subtitle:
                      '${state.checkIns.length} check-ins help explain what sensors cannot see.',
                  actionLabel: 'Add check-in',
                  onAction: () => openPulsePage(context, const CheckInScreen()),
                ),
                const SizedBox(height: 12),
                if (state.checkIns.isEmpty)
                  const EmptyState(
                    icon: Icons.edit_note_rounded,
                    title: 'No check-ins yet',
                    detail:
                        'Add only context that sensors cannot observe, such as caffeine, illness, mood, or travel.',
                  )
                else
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < state.checkIns.take(2).length;
                          index++
                        ) ...[
                          _CheckInRow(checkIn: state.checkIns[index]),
                          if (index != state.checkIns.take(2).length - 1)
                            const Divider(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final readySources = state.sources.where(
      (source) => const {
        SourceStatus.connected,
        SourceStatus.connectedData,
        SourceStatus.connectedEmpty,
        SourceStatus.partiallyPermitted,
      }.contains(source.status),
    );
    final attentionSources = state.sources.where(
      (source) => const {
        SourceStatus.permissionRequired,
        SourceStatus.error,
        SourceStatus.stale,
        SourceStatus.unavailable,
      }.contains(source.status),
    );
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: PulseColors.mint,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.mode == AppMode.demo
                      ? 'Demo is ready'
                      : readySources.isEmpty
                      ? 'Sources need review'
                      : '${readySources.length} ${readySources.length == 1 ? 'source is' : 'sources are'} ready',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  state.mode == AppMode.demo
                      ? '30 days loaded · fixture v1 · no Live data used'
                      : attentionSources.isEmpty
                      ? 'Live sources are stored only in the encrypted Live database'
                      : '${attentionSources.length} ${attentionSources.length == 1 ? 'source needs' : 'sources need'} attention',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        openPulsePage(context, const ObserveScreen()),
                    icon: const Icon(Icons.insights_rounded, size: 19),
                    label: const Text('View source data'),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () =>
                      openPulsePage(context, const SourcesScreen()),
                  icon: const Icon(Icons.tune_rounded, size: 19),
                  label: const Text('Manage sources'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({required this.checkIn});

  final CheckInData checkIn;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => openPulsePage(context, CheckInScreen(existing: checkIn)),
      leading: Icon(checkIn.icon, color: PulseColors.cyan),
      title: Text(checkIn.context),
      subtitle: Text(checkIn.detail),
      trailing: Text(
        '${checkIn.when.hour.toString().padLeft(2, '0')}:${checkIn.when.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class PrimaryInsightCard extends StatelessWidget {
  const PrimaryInsightCard({
    super.key,
    required this.onTap,
    required this.finding,
  });

  final VoidCallback onTap;
  final FindingData? finding;

  @override
  Widget build(BuildContext context) {
    final current = finding;
    if (current == null || !current.isCurrent) {
      return const EmptyState(
        icon: Icons.query_stats_rounded,
        title: 'No current finding',
        detail: 'Deterministic analysis has not produced current evidence yet.',
      );
    }
    final difference =
        '${current.medianDifferenceBpm >= 0 ? '+' : ''}${current.medianDifferenceBpm.toStringAsFixed(0)} bpm';
    return SurfaceCard(
      accent: PulseColors.lime,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusPill(label: 'SUPPORTED', color: PulseColors.lime),
              Icon(
                Icons.arrow_forward_rounded,
                color: PulseColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Your heart rate was usually higher before your recurring 1:1.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '${current.positiveCount} of ${current.includedCount} comparable meetings repeated the pattern. Evidence exclusions stay visible below.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          MetricStrip(
            metrics: [
              MetricValue(label: 'DIFFERENCE', value: difference),
              MetricValue(
                label: 'REPEATED',
                value: '${current.positiveCount} of ${current.includedCount}',
              ),
              MetricValue(
                label: 'DATA',
                value: '${(current.completeness * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          NoticeBox(
            icon: Icons.info_outline_rounded,
            text: current.unresolvedInfluenceCount == 0
                ? 'No unresolved manual influence is attached to this finding.'
                : '${current.unresolvedInfluenceCount} unresolved influence entries remain visible.',
          ),
        ],
      ),
    );
  }
}

enum _ObserveMetric { heartRate, sleep, steps }

class ObserveScreen extends StatefulWidget {
  const ObserveScreen({super.key});

  @override
  State<ObserveScreen> createState() => _ObserveScreenState();
}

class _ObserveScreenState extends State<ObserveScreen> {
  _ObserveMetric metric = _ObserveMetric.heartRate;
  int rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final dashboard = state.observeDashboard;
    final visibleDays = dashboard.days
        .skip(math.max(0, dashboard.days.length - rangeDays))
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observe'),
        actions: [
          if (state.observeRefreshInProgress)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: state.refreshObserveDashboard,
              tooltip: 'Refresh source dashboard',
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshObserveDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            PageIntro(
              title: 'Your data, in one view',
              subtitle:
                  'See what WhyPulse has observed before it turns any of it into a finding.',
              trailing: ModeBadge(mode: state.mode),
            ),
            const SizedBox(height: 22),
            _ObserveHeroCard(dashboard: dashboard),
            if (state.observeRefreshMessage != null) ...[
              const SizedBox(height: 12),
              NoticeBox(
                icon: Icons.info_outline_rounded,
                text: state.observeRefreshMessage!,
              ),
            ],
            if (dashboard.isEmpty) ...[
              const SizedBox(height: 20),
              const EmptyState(
                icon: Icons.monitor_heart_outlined,
                title: 'No source data in this window',
                detail:
                    'Connect a source or add a check-in. Observe will fill in as local records arrive.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => openPulsePage(context, const SourcesScreen()),
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Set up sources'),
              ),
            ] else ...[
              const SizedBox(height: 28),
              _ObserveRangeSelector(
                value: rangeDays,
                onChanged: (value) => setState(() => rangeDays = value),
              ),
              const SizedBox(height: 20),
              const SectionTitle(
                title: 'Signals over time',
                subtitle:
                    'A descriptive view of recorded values—not a health verdict.',
              ),
              const SizedBox(height: 12),
              _ObserveSignalCard(
                days: visibleDays,
                metric: metric,
                onMetricChanged: (value) => setState(() => metric = value),
              ),
              const SizedBox(height: 28),
              const SectionTitle(
                title: 'Data rhythm',
                subtitle: 'Brighter days contain more kinds of source data.',
              ),
              const SizedBox(height: 12),
              _ObserveCoverageCard(days: visibleDays),
            ],
            const SizedBox(height: 28),
            SectionTitle(
              title: 'Source mix',
              subtitle: dashboard.isDemo
                  ? 'Fictional records loaded through the production data path.'
                  : 'Canonical records currently stored on this device.',
              actionLabel: 'Manage',
              onAction: () => openPulsePage(context, const SourcesScreen()),
            ),
            const SizedBox(height: 12),
            _ObserveSourceGrid(dashboard: dashboard),
            if (dashboard.recentActivity.isNotEmpty) ...[
              const SizedBox(height: 28),
              const SectionTitle(
                title: 'Recently observed',
                subtitle: 'Privacy-safe records from the selected data window.',
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < dashboard.recentActivity.length;
                      index++
                    ) ...[
                      _ObserveActivityRow(
                        activity: dashboard.recentActivity[index],
                        asOf: dashboard.asOf,
                      ),
                      if (index != dashboard.recentActivity.length - 1)
                        const Divider(),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            NoticeBox(
              icon: Icons.lock_outline_rounded,
              text: dashboard.isDemo
                  ? 'This dashboard uses only the fictional Demo store. It never reads or mixes Live records.'
                  : 'This view is built on device from normalized records. Calendar titles, attendees, and identities are not retained.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ObserveHeroCard extends StatelessWidget {
  const _ObserveHeroCard({required this.dashboard});

  final ObserveDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseColors.lime.withValues(alpha: 0.16),
            PulseColors.cyan.withValues(alpha: 0.08),
            PulseColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseColors.lime.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: dashboard.isDemo ? '30 DAYS · FICTIONAL' : '30 DAYS · LOCAL',
            color: dashboard.isDemo ? PulseColors.violet : PulseColors.mint,
            icon: dashboard.isDemo
                ? Icons.science_outlined
                : Icons.phone_android_rounded,
          ),
          const SizedBox(height: 20),
          Text(
            dashboard.isEmpty
                ? 'Ready when your data is'
                : '${dashboard.activeDayCount} days tell the story',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            dashboard.isEmpty
                ? 'Your encrypted source overview will appear here.'
                : '${_observeInteger(dashboard.totalRecordCount)} local records are organized into a calm, inspectable overview.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          MetricStrip(
            metrics: [
              MetricValue(
                label: 'RECORDS',
                value: _observeCompact(dashboard.totalRecordCount),
              ),
              MetricValue(
                label: 'STREAMS',
                value: '${dashboard.activeStreamCount}',
              ),
              MetricValue(
                label: 'DAYS',
                value: '${dashboard.activeDayCount}/30',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObserveRangeSelector extends StatelessWidget {
  const _ObserveRangeSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Window', style: Theme.of(context).textTheme.labelSmall),
        ),
        for (final option in const [7, 30]) ...[
          ChoiceChip(
            label: Text('$option days'),
            selected: value == option,
            onSelected: (_) => onChanged(option),
          ),
          if (option == 7) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ObserveSignalCard extends StatelessWidget {
  const _ObserveSignalCard({
    required this.days,
    required this.metric,
    required this.onMetricChanged,
  });

  final List<ObserveDayData> days;
  final _ObserveMetric metric;
  final ValueChanged<_ObserveMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final values = [for (final day in days) _observeValue(day, metric)];
    final available = values.whereType<double>().toList(growable: false);
    final average = available.isEmpty
        ? null
        : available.reduce((a, b) => a + b) / available.length;
    final minimum = available.isEmpty ? null : available.reduce(math.min);
    final maximum = available.isEmpty ? null : available.reduce(math.max);
    final color = _observeMetricColor(metric);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in _ObserveMetric.values) ...[
                  ChoiceChip(
                    avatar: Icon(
                      _observeMetricIcon(option),
                      size: 17,
                      color: metric == option
                          ? _observeMetricColor(option)
                          : PulseColors.textTertiary,
                    ),
                    label: Text(_observeMetricLabel(option)),
                    selected: metric == option,
                    onSelected: (_) => onMetricChanged(option),
                  ),
                  if (option != _ObserveMetric.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Semantics(
            label: _observeChartSemantics(metric, available),
            image: true,
            child: SizedBox(
              height: 164,
              width: double.infinity,
              child: CustomPaint(
                painter: _ObserveChartPainter(values: values, color: color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                days.isEmpty ? '—' : _observeShortDate(days.first.day),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                days.isEmpty ? '—' : _observeShortDate(days.last.day),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 18),
          MetricStrip(
            metrics: [
              MetricValue(
                label: 'DAILY AVG',
                value: _observeMetricValue(metric, average),
              ),
              MetricValue(
                label: 'LOW',
                value: _observeMetricValue(metric, minimum),
              ),
              MetricValue(
                label: 'HIGH',
                value: _observeMetricValue(metric, maximum),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObserveChartPainter extends CustomPainter {
  const _ObserveChartPainter({required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = PulseColors.border.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final available = values.whereType<double>().toList(growable: false);
    if (available.isEmpty) return;
    var minimum = available.reduce(math.min);
    var maximum = available.reduce(math.max);
    if ((maximum - minimum).abs() < 0.001) {
      minimum -= 1;
      maximum += 1;
    }
    const inset = 7.0;
    final usableHeight = size.height - inset * 2;
    final denominator = math.max(1, values.length - 1);
    final line = Path();
    var started = false;
    Offset? lastPoint;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value == null) continue;
      final point = Offset(
        size.width * index / denominator,
        inset + (1 - (value - minimum) / (maximum - minimum)) * usableHeight,
      );
      if (!started) {
        line.moveTo(point.dx, point.dy);
        started = true;
      } else {
        line.lineTo(point.dx, point.dy);
      }
      lastPoint = point;
    }
    final glow = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(line, glow)
      ..drawPath(line, stroke);
    if (lastPoint != null) {
      canvas
        ..drawCircle(lastPoint, 6, Paint()..color = PulseColors.surface)
        ..drawCircle(lastPoint, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ObserveChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _ObserveCoverageCard extends StatelessWidget {
  const _ObserveCoverageCard({required this.days});

  final List<ObserveDayData> days;

  @override
  Widget build(BuildContext context) {
    final activeDays = days.where((day) => day.recordCount > 0).length;
    return Semantics(
      label:
          '$activeDays of ${days.length} days contain source data. Brighter bars contain more data types.',
      child: SurfaceCard(
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: 10 + day.visibleStreamCount * 8,
                          decoration: BoxDecoration(
                            color: day.visibleStreamCount == 0
                                ? PulseColors.elevated
                                : PulseColors.lime.withValues(
                                    alpha: 0.2 + day.visibleStreamCount * 0.14,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days.isEmpty ? '—' : _observeShortDate(days.first.day),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Row(
                  children: [
                    Text('LESS', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(width: 6),
                    for (var index = 1; index <= 4; index++) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: PulseColors.lime.withValues(
                            alpha: 0.12 + index * 0.17,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (index != 4) const SizedBox(width: 3),
                    ],
                    const SizedBox(width: 6),
                    Text('MORE', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                Text(
                  days.isEmpty ? '—' : _observeShortDate(days.last.day),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ObserveSourceGrid extends StatelessWidget {
  const _ObserveSourceGrid({required this.dashboard});

  final ObserveDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final sources = [
      (
        Icons.monitor_heart_rounded,
        'Health signals',
        dashboard.heartRateRecords +
            dashboard.hrvRecords +
            dashboard.stepRecords,
        '${dashboard.heartRateRecords} heart · ${dashboard.stepRecords} step',
        PulseColors.coral,
      ),
      (
        Icons.bedtime_rounded,
        'Rest & movement',
        dashboard.sleepRecords +
            dashboard.workoutRecords +
            dashboard.activityRecords,
        '${dashboard.sleepRecords} sleep · ${dashboard.workoutRecords + dashboard.activityRecords} movement',
        PulseColors.violet,
      ),
      (
        Icons.calendar_month_rounded,
        'Recurring events',
        dashboard.eventRecords,
        'Categorized, identity removed',
        PulseColors.cyan,
      ),
      (
        Icons.edit_note_rounded,
        'Manual context',
        dashboard.checkInRecords,
        'Check-ins you chose to add',
        PulseColors.mint,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final source in sources)
              SizedBox(
                width: itemWidth,
                child: _ObserveSourceCard(
                  icon: source.$1,
                  title: source.$2,
                  count: source.$3,
                  detail: source.$4,
                  color: source.$5,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ObserveSourceCard extends StatelessWidget {
  const _ObserveSourceCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int count;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            _observeCompact(count),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 3),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ObserveActivityRow extends StatelessWidget {
  const _ObserveActivityRow({required this.activity, required this.asOf});

  final ObserveActivityData activity;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    final color = _observeActivityColor(activity.kind);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _observeActivityIcon(activity.kind),
          color: color,
          size: 21,
        ),
      ),
      title: Text(activity.title),
      subtitle: Text(activity.detail),
      trailing: Text(
        _observeWhen(activity.occurredAt, asOf),
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

double? _observeValue(ObserveDayData day, _ObserveMetric metric) =>
    switch (metric) {
      _ObserveMetric.heartRate => day.heartRateMedianBpm,
      _ObserveMetric.sleep =>
        day.sleepMinutes == null ? null : day.sleepMinutes! / 60,
      _ObserveMetric.steps => day.steps,
    };

String _observeMetricLabel(_ObserveMetric metric) => switch (metric) {
  _ObserveMetric.heartRate => 'Heart rate',
  _ObserveMetric.sleep => 'Sleep',
  _ObserveMetric.steps => 'Steps',
};

IconData _observeMetricIcon(_ObserveMetric metric) => switch (metric) {
  _ObserveMetric.heartRate => Icons.monitor_heart_rounded,
  _ObserveMetric.sleep => Icons.bedtime_rounded,
  _ObserveMetric.steps => Icons.directions_walk_rounded,
};

Color _observeMetricColor(_ObserveMetric metric) => switch (metric) {
  _ObserveMetric.heartRate => PulseColors.coral,
  _ObserveMetric.sleep => PulseColors.violet,
  _ObserveMetric.steps => PulseColors.mint,
};

String _observeMetricValue(_ObserveMetric metric, double? value) {
  if (value == null) return '—';
  return switch (metric) {
    _ObserveMetric.heartRate => '${value.round()} bpm',
    _ObserveMetric.sleep => '${value.toStringAsFixed(1)} h',
    _ObserveMetric.steps => _observeCompact(value.round()),
  };
}

String _observeChartSemantics(_ObserveMetric metric, List<double> values) {
  if (values.isEmpty) return 'No ${_observeMetricLabel(metric)} data.';
  final low = values.reduce(math.min);
  final high = values.reduce(math.max);
  return '${_observeMetricLabel(metric)} chart with ${values.length} recorded days, from ${_observeMetricValue(metric, low)} to ${_observeMetricValue(metric, high)}.';
}

IconData _observeActivityIcon(ObserveActivityKind kind) => switch (kind) {
  ObserveActivityKind.sleep => Icons.bedtime_rounded,
  ObserveActivityKind.workout => Icons.directions_run_rounded,
  ObserveActivityKind.calendar => Icons.calendar_month_rounded,
  ObserveActivityKind.checkIn => Icons.edit_note_rounded,
  ObserveActivityKind.steps => Icons.directions_walk_rounded,
};

Color _observeActivityColor(ObserveActivityKind kind) => switch (kind) {
  ObserveActivityKind.sleep => PulseColors.violet,
  ObserveActivityKind.workout => PulseColors.mint,
  ObserveActivityKind.calendar => PulseColors.cyan,
  ObserveActivityKind.checkIn => PulseColors.amber,
  ObserveActivityKind.steps => PulseColors.lime,
};

String _observeInteger(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _observeCompact(int value) {
  if (value < 1000) return '$value';
  final compact = value / 1000;
  return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
}

const _observeMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _observeShortDate(DateTime value) =>
    '${_observeMonths[value.month - 1]} ${value.day}';

String _observeWhen(DateTime value, DateTime asOf) {
  final local = value.toLocal();
  final reference = asOf.toLocal();
  final sameDay =
      local.year == reference.year &&
      local.month == reference.month &&
      local.day == reference.day;
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return sameDay ? 'Today\n$time' : '${_observeShortDate(local)}\n$time';
}

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Control what evidence WhyPulse can use',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Each source shows what it contributes, what is stored, and whether it needs attention.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          NoticeBox(
            icon: state.mode == AppMode.demo
                ? Icons.science_outlined
                : Icons.lock_outline_rounded,
            text: state.mode == AppMode.demo
                ? 'Demo mode reads only the fictional Demo store. Live integrations stay off.'
                : 'Live mode never reads Demo records, findings, experiments, or exports.',
          ),
          if (state.sourceOperationMessage != null) ...[
            const SizedBox(height: 12),
            NoticeBox(
              icon: Icons.info_outline_rounded,
              text: state.sourceOperationMessage!,
            ),
          ],
          const SizedBox(height: 20),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < state.sources.length; index++) ...[
                  _SourceRow(source: state.sources[index], state: state),
                  if (index != state.sources.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (state.mode == AppMode.live)
            OutlinedButton.icon(
              onPressed: state.sourceOperationInProgress
                  ? null
                  : state.refreshSources,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh connected sources'),
            )
          else
            OutlinedButton.icon(
              onPressed: state.resetDemo,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset Demo data'),
            ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.state});

  final SourceData source;
  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final isDemoSource = source.id == 'demo';
    final active = state.mode == AppMode.demo ? isDemoSource : !isDemoSource;
    final status = active
        ? _sourceStatusLabel(source.status)
        : (isDemoSource ? 'Available in Demo' : 'Available in Live');
    return ListTile(
      onTap: () => openPulsePage(context, SourceDetailScreen(source: source)),
      leading: Icon(
        source.icon,
        color: active ? PulseColors.cyan : PulseColors.textTertiary,
      ),
      title: Text(source.name),
      subtitle: Text(source.description),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            status,
            style: TextStyle(
              color: active
                  ? _sourceStatusColor(source.status)
                  : PulseColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

String _sourceStatusLabel(SourceStatus status) => switch (status) {
  SourceStatus.connected => 'Connected',
  SourceStatus.available => 'Ready to connect',
  SourceStatus.limited => 'Needs attention',
  SourceStatus.paused => 'Paused',
  SourceStatus.unavailable => 'Unavailable',
  SourceStatus.permissionRequired => 'Permission required',
  SourceStatus.partiallyPermitted => 'Partially permitted',
  SourceStatus.syncing => 'Syncing',
  SourceStatus.connectedEmpty => 'Connected · no data',
  SourceStatus.connectedData => 'Connected',
  SourceStatus.error => 'Error',
  SourceStatus.disconnected => 'Disconnected',
  SourceStatus.deleting => 'Deleting',
  SourceStatus.stale => 'Refresh needed',
  SourceStatus.demoFixtureLoaded => 'Fixture loaded',
  SourceStatus.availableInLive => 'Available in Live',
};

Color _sourceStatusColor(SourceStatus status) => switch (status) {
  SourceStatus.connected ||
  SourceStatus.connectedData ||
  SourceStatus.demoFixtureLoaded => PulseColors.mint,
  SourceStatus.syncing => PulseColors.cyan,
  SourceStatus.error || SourceStatus.unavailable => PulseColors.coral,
  SourceStatus.permissionRequired ||
  SourceStatus.partiallyPermitted ||
  SourceStatus.stale => PulseColors.amber,
  _ => PulseColors.textTertiary,
};

class SourceDetailScreen extends StatelessWidget {
  const SourceDetailScreen({super.key, required this.source});

  final SourceData source;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final current = state.sources.cast<SourceData?>().firstWhere(
      (item) => item?.id == source.id,
      orElse: () => source,
    )!;
    final isDemo = current.id == 'demo';
    final active = state.mode == AppMode.demo ? isDemo : !isDemo;
    return Scaffold(
      appBar: AppBar(title: Text(current.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: PulseColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(current.icon, color: PulseColors.cyan),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    StatusPill(
                      label: active
                          ? (isDemo
                                ? 'LOADED'
                                : _sourceStatusLabel(
                                    current.status,
                                  ).toUpperCase())
                          : 'OTHER MODE',
                      color: active
                          ? _sourceStatusColor(current.status)
                          : PulseColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (active && !isDemo) ...[
            const SectionTitle(title: 'Current state'),
            const SizedBox(height: 10),
            SurfaceCard(
              child: Column(
                children: [
                  InfoLine(
                    label: 'Stored records',
                    value: '${current.recordCount}',
                  ),
                  if (current.permissionsTotal > 0) ...[
                    const Divider(height: 24),
                    InfoLine(
                      label: 'Permissions',
                      value:
                          '${current.permissionsGranted}/${current.permissionsTotal} granted',
                    ),
                  ],
                  if (current.lastSync != null) ...[
                    const Divider(height: 24),
                    InfoLine(label: 'Last sync', value: current.lastSync!),
                  ],
                ],
              ),
            ),
            if (current.statusDetail != null) ...[
              const SizedBox(height: 10),
              NoticeBox(
                icon: Icons.info_outline_rounded,
                text: current.statusDetail!,
              ),
            ],
            const SizedBox(height: 24),
          ],
          const SectionTitle(title: 'Why it matters'),
          const SizedBox(height: 10),
          SurfaceCard(child: Text(current.contribution)),
          const SizedBox(height: 24),
          const SectionTitle(title: 'What WhyPulse keeps'),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: _sourcePrivacyLines(current.id)
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: BulletLine(text: line),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (!active)
            NoticeBox(
              icon: Icons.swap_horiz_rounded,
              text: isDemo
                  ? 'Switch to Demo mode to use this fictional source.'
                  : 'Switch to Live mode to review and connect this source.',
            )
          else if (isDemo)
            OutlinedButton.icon(
              onPressed: state.resetDemo,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset Demo source'),
            )
          else
            ..._sourceActions(context, state, current),
        ],
      ),
    );
  }

  List<Widget> _sourceActions(
    BuildContext context,
    WhyPulseState state,
    SourceData current,
  ) {
    if (current.id == 'checkins') {
      return [
        FilledButton.icon(
          onPressed: () => openPulsePage(context, const CheckInScreen()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add check-in'),
        ),
      ];
    }

    final busy =
        state.sourceOperationInProgress ||
        current.status == SourceStatus.syncing ||
        current.status == SourceStatus.deleting;
    final connectLabel = current.id == 'calendar'
        ? 'Review recurring series'
        : current.status == SourceStatus.partiallyPermitted
        ? 'Request missing permissions'
        : 'Connect Health Connect';
    final disconnected = const {
      SourceStatus.disconnected,
      SourceStatus.permissionRequired,
      SourceStatus.partiallyPermitted,
      SourceStatus.available,
    }.contains(current.status);
    if (current.status == SourceStatus.unavailable) {
      return [
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => state.performSourceAction(
                  current.id,
                  SourceAction.openSettings,
                ),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Open Android settings'),
        ),
      ];
    }
    if (disconnected) {
      return [
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  if (current.id == 'calendar') {
                    final series = await state.discoverCalendarSeries();
                    if (!context.mounted || series.isEmpty) return;
                    openPulsePage(
                      context,
                      CalendarReviewScreen(series: series),
                    );
                  } else {
                    await state.performSourceAction(
                      current.id,
                      SourceAction.connect,
                    );
                  }
                },
          child: Text(connectLabel),
        ),
        if (current.status == SourceStatus.permissionRequired)
          TextButton(
            onPressed: busy
                ? null
                : () => state.performSourceAction(
                    current.id,
                    SourceAction.openSettings,
                  ),
            child: const Text('Open permission settings'),
          ),
      ];
    }
    if (current.status == SourceStatus.paused) {
      return [
        FilledButton(
          onPressed: busy
              ? null
              : () =>
                    state.performSourceAction(current.id, SourceAction.resume),
          child: const Text('Resume and refresh'),
        ),
        TextButton(
          onPressed: busy
              ? null
              : () => _confirmDelete(context, state, current),
          child: const Text('Delete stored source data'),
        ),
      ];
    }
    return [
      if (current.id == 'calendar')
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final series = await state.discoverCalendarSeries();
                  if (!context.mounted || series.isEmpty) return;
                  openPulsePage(context, CalendarReviewScreen(series: series));
                },
          icon: const Icon(Icons.event_repeat_rounded),
          label: const Text('Review selected series'),
        ),
      FilledButton.icon(
        onPressed: busy
            ? null
            : () => state.performSourceAction(current.id, SourceAction.refresh),
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
        label: Text(busy ? 'Working…' : 'Refresh source'),
      ),
      TextButton(
        onPressed: busy
            ? null
            : () => state.performSourceAction(current.id, SourceAction.pause),
        child: const Text('Pause syncing'),
      ),
      TextButton(
        onPressed: busy
            ? null
            : () => state.performSourceAction(
                current.id,
                SourceAction.disconnect,
              ),
        child: const Text('Disconnect'),
      ),
      TextButton(
        onPressed: busy ? null : () => _confirmDelete(context, state, current),
        child: const Text('Delete stored source data'),
      ),
    ];
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WhyPulseState state,
    SourceData current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${current.name} data?'),
        content: const Text(
          'Stored records from this source will be removed and dependent evidence will be marked stale. Other sources are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete source data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.performSourceAction(current.id, SourceAction.deleteData);
    if (context.mounted) Navigator.pop(context);
  }
}

class CalendarReviewScreen extends StatefulWidget {
  const CalendarReviewScreen({super.key, required this.series});

  final List<CalendarSeriesData> series;

  @override
  State<CalendarReviewScreen> createState() => _CalendarReviewScreenState();
}

class _CalendarReviewScreenState extends State<CalendarReviewScreen> {
  final selected = <String, String>{};

  @override
  void initState() {
    super.initState();
    for (final item in widget.series) {
      if (item.category case final category?) {
        selected[item.transientId] = category;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review recurring series')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Choose only the series that matter',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'WhyPulse uses the title only on this screen. After saving, it keeps only your category and event times.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final item in widget.series) ...[
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(
                  selected[item.transientId] == null
                      ? 'Not included'
                      : _calendarCategoryLabel(selected[item.transientId]!),
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Choose category',
                  onSelected: (value) {
                    setState(() {
                      if (value == 'not_included') {
                        selected.remove(item.transientId);
                      } else {
                        selected[item.transientId] = value;
                      }
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'recurring_one_to_one',
                      child: Text('Recurring 1:1'),
                    ),
                    PopupMenuItem(
                      value: 'team_meeting',
                      child: Text('Team meeting'),
                    ),
                    PopupMenuItem(
                      value: 'other_recurring_meeting',
                      child: Text('Other recurring meeting'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'not_included',
                      child: Text('Do not include'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: selected.isEmpty || state.sourceOperationInProgress
                ? null
                : () async {
                    await state.saveCalendarReview(selected);
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
            child: Text(
              selected.isEmpty
                  ? 'Choose at least one series'
                  : 'Save ${selected.length} reviewed ${selected.length == 1 ? 'series' : 'series'}',
            ),
          ),
        ],
      ),
    );
  }
}

String _calendarCategoryLabel(String value) => switch (value) {
  'recurring_one_to_one' => 'Recurring 1:1',
  'team_meeting' => 'Team meeting',
  _ => 'Other recurring meeting',
};

List<String> _sourcePrivacyLines(String id) => switch (id) {
  'calendar' => [
    'Meeting category, start, end, and recurrence key',
    'No title, description, location, organizer, or attendees',
  ],
  'health' => [
    'Normalized heart rate, sleep, steps, activity, and workouts',
    'Source identity is replaced with a private hash',
  ],
  'checkins' => [
    'Only the category, time, and value you enter',
    'Every edit or deletion triggers evidence review',
  ],
  _ => [
    'Fictional 30-day records in the Demo database only',
    'Resetting Demo never changes Live data',
  ],
};

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final items = state.mode == AppMode.live
        ? state.history
        : filter == 'All'
        ? state.history
        : state.history
              .where(
                (item) => item.status.toLowerCase() == filter.toLowerCase(),
              )
              .toList();
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('history-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList.list(
              children: [
                const PageIntro(
                  title: 'Your evidence over time',
                  subtitle:
                      'See what changed, why it changed, and whether older evidence is still current.',
                ),
                const SizedBox(height: 20),
                if (state.mode == AppMode.demo)
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final label in const [
                          'All',
                          'Supported',
                          'Developing',
                          'Null finding',
                          'Weakened',
                          'Expired',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: filter == label,
                              onSelected: (_) => setState(() => filter = label),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  EmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: state.mode == AppMode.live
                        ? 'No Live history yet'
                        : 'No items in this state',
                    detail: state.mode == AppMode.live
                        ? 'Findings will appear here only after Live evidence passes its analysis gates.'
                        : 'Choose another filter to see the evidence history.',
                  )
                else
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          _HistoryRow(item: items[index]),
                          if (index != items.length - 1) const Divider(),
                        ],
                      ],
                    ),
                  ),
                if (state.mode == AppMode.demo) ...[
                  const SizedBox(height: 24),
                  SurfaceCard(
                    onTap: () =>
                        openPulsePage(context, const DemoEvidenceCasesScreen()),
                    child: const ActionSummary(
                      icon: Icons.fact_check_outlined,
                      title: 'Demo evidence cases',
                      detail:
                          'Compare supported, null, contradictory, and missing-data outcomes.',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final HistoryItemData item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => openPulsePage(context, FindingStatusScreen(item: item)),
      leading: Icon(item.icon, color: item.accent),
      title: Text(item.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text('${item.subtitle}\n${item.date}'),
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.status.toUpperCase(),
            style: TextStyle(
              color: item.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

class FindingStatusScreen extends StatelessWidget {
  const FindingStatusScreen({super.key, required this.item});

  final HistoryItemData item;

  @override
  Widget build(BuildContext context) {
    final statusMeaning = switch (item.status) {
      'Weakened' =>
        'The original difference became smaller after illness days were excluded.',
      'Expired' =>
        'The supporting source was deleted, so this evidence is no longer current.',
      'Null finding' =>
        'The available comparisons did not show a repeatable difference.',
      'Developing' =>
        'The direction repeats, but more comparable observations are needed.',
      _ =>
        'The pattern passed the current repeatability and data-quality gates.',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('History detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          StatusPill(label: item.status.toUpperCase(), color: item.accent),
          const SizedBox(height: 16),
          Text(item.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            item.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'What this status means'),
          const SizedBox(height: 10),
          SurfaceCard(child: Text(statusMeaning)),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              children: [
                InfoLine(label: 'Last changed', value: item.date),
                const Divider(height: 24),
                const InfoLine(
                  label: 'Analysis',
                  value: 'Meeting comparison v1',
                ),
                const Divider(height: 24),
                InfoLine(
                  label: 'Current',
                  value: item.invalidated ? 'No' : 'Yes',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoEvidenceCasesScreen extends StatelessWidget {
  const DemoEvidenceCasesScreen({super.key});

  static const cases = [
    _EvidenceCase(
      'Supported repeated pattern',
      '6 of 8 comparable meetings repeated',
      'SUPPORTED',
      PulseColors.lime,
      'Evidence promoted',
    ),
    _EvidenceCase(
      'Null finding',
      'No repeatable difference in 3 comparisons',
      'NULL',
      PulseColors.nullBlue,
      'No repeatable association',
    ),
    _EvidenceCase(
      'Contradictory evidence',
      'Comparable windows moved in mixed directions',
      'STOPPED',
      PulseColors.amber,
      'Promotion stopped',
    ),
    _EvidenceCase(
      'Missing-data result',
      'Too little complete context to compare safely',
      'INSUFFICIENT',
      PulseColors.textTertiary,
      'Evidence gate not reached',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo evidence cases')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Same pipeline, different honest outcomes',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'A result is useful even when evidence is null, contradictory, or incomplete.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final evidenceCase in cases) ...[
            SurfaceCard(
              onTap: () => openPulsePage(
                context,
                _DemoEvidenceCaseDetailScreen(evidenceCase: evidenceCase),
              ),
              child: ActionSummary(
                icon: Icons.analytics_outlined,
                title: evidenceCase.title,
                detail: evidenceCase.detail,
                trailing: StatusPill(
                  label: evidenceCase.badge,
                  color: evidenceCase.color,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _EvidenceCase {
  const _EvidenceCase(
    this.title,
    this.detail,
    this.badge,
    this.color,
    this.outcome,
  );

  final String title;
  final String detail;
  final String badge;
  final Color color;
  final String outcome;
}

class _DemoEvidenceCaseDetailScreen extends StatelessWidget {
  const _DemoEvidenceCaseDetailScreen({required this.evidenceCase});

  final _EvidenceCase evidenceCase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(evidenceCase.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          StatusPill(label: evidenceCase.badge, color: evidenceCase.color),
          const SizedBox(height: 18),
          Text(
            evidenceCase.outcome,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            evidenceCase.detail,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  _caseReason(evidenceCase.badge),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _caseReason(String badge) => switch (badge) {
  'SUPPORTED' =>
    'Enough comparable windows repeated in one direction after exclusions.',
  'NULL' => 'The completed comparisons stayed near the matched baseline.',
  'STOPPED' => 'Counterevidence was too strong to promote a single pattern.',
  _ =>
    'Required signal or context coverage did not reach the evidence threshold.',
};

class MomentFingerprintScreen extends StatelessWidget {
  const MomentFingerprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final finding = state.finding;
    if (finding == null || !finding.isCurrent) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moment Fingerprint')),
        body: const EmptyState(
          icon: Icons.query_stats_rounded,
          title: 'No current fingerprint',
          detail:
              'A fingerprint appears after deterministic evidence is current.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Moment Fingerprint')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(
            label: 'REPEATED ASSOCIATION',
            color: PulseColors.lime,
          ),
          const SizedBox(height: 16),
          Text(
            'Recurring 1:1',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Heart rate was usually higher in the 30 minutes before this meeting than in matched no-meeting windows.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          MetricStrip(
            metrics: [
              MetricValue(
                label: 'DIFFERENCE',
                value:
                    '${finding.medianDifferenceBpm >= 0 ? '+' : ''}${finding.medianDifferenceBpm.toStringAsFixed(0)} bpm',
              ),
              MetricValue(
                label: 'REPEATED',
                value: '${finding.positiveCount} / ${finding.includedCount}',
              ),
              MetricValue(
                label: 'RECOVERY',
                value:
                    '${finding.recoveryDurationMinutes.toStringAsFixed(0)} min',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            title: 'Repeated traces',
            subtitle:
                'Included meetings are overlaid against the matched no-meeting baseline.',
          ),
          const SizedBox(height: 10),
          if (state.replay case final replay? when replay.isUsable)
            _RepeatedTraceCard(replay: replay)
          else
            const NoticeBox(
              icon: Icons.show_chart_rounded,
              text:
                  'Trace metrics are not available for this evidence version. No sample trace is substituted in Live mode.',
            ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Why it is shown'),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                BulletLine(
                  text:
                      '${finding.candidateCount} candidate meetings were found',
                ),
                SizedBox(height: 10),
                BulletLine(
                  text:
                      '${finding.candidateCount - finding.includedCount} were excluded by the evidence gates',
                ),
                SizedBox(height: 10),
                BulletLine(
                  text:
                      '${finding.positiveCount} of the remaining ${finding.includedCount} moved in the same direction',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoticeBox(
            icon: Icons.warning_amber_rounded,
            text:
                'This supports a repeated association—not a diagnosis or causal claim. Two comparable meetings disagreed.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const EvidenceScreen()),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Challenge the evidence'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => openPulsePage(context, const AskWhyPulseScreen()),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Ask about this pattern'),
          ),
        ],
      ),
    );
  }
}

class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Challenge the recurring 1:1 finding',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start with the verified measures. Open the comparison details only when you need them.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            onTap: () => openPulsePage(context, const InfluenceEditorScreen()),
            child: ActionSummary(
              icon: Icons.tune_rounded,
              title: 'Review influences',
              detail:
                  'Add or correct caffeine, exercise, illness, mood, travel, and custom context.',
              trailing: StatusPill(
                label: '${state.checkIns.length} LOGGED',
                color: PulseColors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const NoticeBox(
            icon: Icons.refresh_rounded,
            text:
                'Every influence edit is persisted and reruns deterministic evidence review. Prior evidence remains in History.',
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'VERIFIED MEASURES'),
          const SizedBox(height: 10),
          for (final fact in _findingFacts(
            WhyPulseScope.of(context).finding,
          )) ...[
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 54,
                    decoration: BoxDecoration(
                      color: fact.accent,
                      borderRadius: BorderRadius.circular(4),
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
                        const SizedBox(height: 5),
                        Text(
                          fact.value,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          fact.detail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          const _EvidenceExpansion(
            title: 'How were windows compared?',
            children: [
              BulletLine(
                text:
                    'Same person, similar time of day, no meeting in the control window',
              ),
              SizedBox(height: 10),
              BulletLine(
                text:
                    'Recent exercise, travel, illness, and weak signal windows were excluded',
              ),
              SizedBox(height: 10),
              BulletLine(
                text: 'Every number keeps its source and analysis version',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _EvidenceExpansion(
            title: 'What disagrees?',
            children: [
              BulletLine(
                text: '2 of 8 comparable meetings did not show the rise',
              ),
              SizedBox(height: 10),
              BulletLine(text: 'Caffeine context is missing on 2 meeting days'),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const ExplanationScreen()),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Explain this evidence'),
          ),
        ],
      ),
    );
  }
}

class _RepeatedTraceCard extends StatelessWidget {
  const _RepeatedTraceCard({required this.replay});

  final MomentReplayData replay;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label:
                'Repeated trace chart with ${replay.traces.length} included meetings and a matched baseline',
            image: true,
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: CustomPaint(painter: _RepeatedTracePainter(replay)),
            ),
          ),
          Row(
            children: [
              for (final phase in replay.phases)
                Expanded(
                  child: Text(
                    phase,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _TraceLegend(color: PulseColors.coral, label: 'Included repeat'),
              _TraceLegend(color: PulseColors.lime, label: 'Matched baseline'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            replay.sourceLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TraceLegend extends StatelessWidget {
  const _TraceLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RepeatedTracePainter extends CustomPainter {
  const _RepeatedTracePainter(this.replay);

  final MomentReplayData replay;

  @override
  void paint(Canvas canvas, Size size) {
    final values = <double>[
      ...replay.matchedBaselineBpm,
      for (final trace in replay.traces) ...trace.valuesBpm,
    ];
    final minimum = values.reduce(math.min) - 3;
    final maximum = values.reduce(math.max) + 3;
    final span = math.max(1.0, maximum - minimum);
    const horizontalInset = 12.0;
    const verticalInset = 12.0;
    final plotWidth = size.width - horizontalInset * 2;
    final plotHeight = size.height - verticalInset * 2;
    Offset point(int index, double value) => Offset(
      horizontalInset + plotWidth * index / (replay.phases.length - 1),
      verticalInset + plotHeight * (maximum - value) / span,
    );

    final gridPaint = Paint()
      ..color = PulseColors.border.withValues(alpha: .65)
      ..strokeWidth = 1;
    for (var row = 0; row < 4; row++) {
      final y = verticalInset + plotHeight * row / 3;
      canvas.drawLine(
        Offset(horizontalInset, y),
        Offset(size.width - horizontalInset, y),
        gridPaint,
      );
    }

    final tracePaint = Paint()
      ..color = PulseColors.coral.withValues(alpha: .48)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (final trace in replay.traces) {
      final path = Path()
        ..moveTo(
          point(0, trace.valuesBpm.first).dx,
          point(0, trace.valuesBpm.first).dy,
        );
      for (var index = 1; index < trace.valuesBpm.length; index++) {
        final next = point(index, trace.valuesBpm[index]);
        path.lineTo(next.dx, next.dy);
      }
      canvas.drawPath(path, tracePaint);
    }

    final baselinePaint = Paint()
      ..color = PulseColors.lime
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final baselinePath = Path();
    for (var index = 0; index < replay.matchedBaselineBpm.length; index++) {
      final next = point(index, replay.matchedBaselineBpm[index]);
      if (index == 0) {
        baselinePath.moveTo(next.dx, next.dy);
      } else {
        baselinePath.lineTo(next.dx, next.dy);
      }
      canvas.drawCircle(next, 3.5, Paint()..color = PulseColors.lime);
    }
    canvas.drawPath(baselinePath, baselinePaint);
  }

  @override
  bool shouldRepaint(covariant _RepeatedTracePainter oldDelegate) =>
      oldDelegate.replay != replay;
}

class InfluenceEditorScreen extends StatelessWidget {
  const InfluenceEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review influences')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Correct the context used by evidence',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'These entries are direct evidence inputs. Open one to correct it, or add context that was missing.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const CheckInScreen()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add influence'),
          ),
          const SizedBox(height: 18),
          if (state.checkIns.isEmpty)
            const EmptyState(
              icon: Icons.tune_rounded,
              title: 'No influences logged',
              detail:
                  'Add caffeine, exercise, illness, mood, travel, or reviewed custom context.',
            )
          else
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < state.checkIns.length;
                    index++
                  ) ...[
                    ListTile(
                      leading: Icon(state.checkIns[index].icon),
                      title: Text(state.checkIns[index].context),
                      subtitle: Text(state.checkIns[index].detail),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => openPulsePage(
                        context,
                        CheckInScreen(existing: state.checkIns[index]),
                      ),
                    ),
                    if (index != state.checkIns.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          const NoticeBox(
            icon: Icons.history_rounded,
            text:
                'Saving or deleting an influence recomputes affected evidence. A changed finding becomes a new version; the older version stays in History.',
          ),
        ],
      ),
    );
  }
}

List<EvidenceFact> _findingFacts(FindingData? finding) {
  final current = finding;
  if (current == null) return const [];
  final range =
      '${current.effectLowerBpm.toStringAsFixed(0)}–${current.effectUpperBpm.toStringAsFixed(0)} bpm';
  return [
    EvidenceFact(
      label: 'PRE-EVENT DIFFERENCE',
      value:
          '${current.medianDifferenceBpm >= 0 ? '+' : ''}${current.medianDifferenceBpm.toStringAsFixed(0)} bpm',
      detail: 'Median difference from matched no-meeting windows',
      source: 'Stored evidence · ${current.includedCount} included windows',
      accent: PulseColors.coral,
    ),
    EvidenceFact(
      label: 'REPEATABILITY',
      value: '${current.positiveCount} of ${current.includedCount}',
      detail: 'Comparable meetings followed the same direction',
      source: 'Stored evidence · ${current.candidateCount} candidates',
      accent: PulseColors.lime,
    ),
    EvidenceFact(
      label: 'EFFECT RANGE',
      value: range,
      detail: 'Observed range among materially consistent meetings',
      source:
          'Stored evidence · ${(current.completeness * 100).round()}% complete',
      accent: PulseColors.cyan,
    ),
  ];
}

class _EvidenceExpansion extends StatelessWidget {
  const _EvidenceExpansion({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class ExplanationScreen extends StatefulWidget {
  const ExplanationScreen({super.key});

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  var _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WhyPulseScope.of(context).loadExplanation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final finding = state.finding;
    if (finding == null || !finding.isCurrent) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explanation')),
        body: const EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'No current explanation',
          detail: 'An explanation is available only for current evidence.',
        ),
      );
    }
    final explanation = state.currentExplanation;
    return Scaffold(
      appBar: AppBar(title: const Text('Explanation')),
      body: explanation == null
          ? _ExplanationLoadingState(state: state)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const StatusPill(
                  label: 'Bounded to this evidence bundle',
                  color: PulseColors.violet,
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(height: 18),
                Text(
                  'What the comparison supports',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  explanation.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                for (final paragraph in explanation.paragraphs) ...[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paragraph.text),
                        if (paragraph.citations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final citation in paragraph.citations)
                                Chip(label: Text(citation)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                NoticeBox(
                  icon: Icons.info_outline_rounded,
                  text: explanation.uncertainty,
                ),
                if (explanation.nextObservation != null) ...[
                  const SizedBox(height: 12),
                  NoticeBox(
                    icon: Icons.visibility_outlined,
                    text: explanation.nextObservation!,
                  ),
                ],
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLine(
                        label: 'Runtime',
                        value: explanation.runtimeLabel,
                      ),
                      const Divider(height: 24),
                      InfoLine(
                        label: 'Result',
                        value: explanation.fromCache
                            ? 'Validated local cache'
                            : 'Validated now',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      openPulsePage(context, const AskWhyPulseScreen()),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Ask about this evidence'),
                ),
              ],
            ),
    );
  }
}

class _ExplanationLoadingState extends StatelessWidget {
  const _ExplanationLoadingState({required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    if (state.explanationMessage != null) {
      return EmptyState(
        icon: Icons.shield_outlined,
        title: 'No validated explanation',
        detail: state.explanationMessage!,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Preparing a bounded explanation…'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: state.explanationInProgress
                  ? state.cancelExplanation
                  : null,
              child: const Text('Cancel'),
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

  static const questions = [
    'Why was this promoted?',
    'What evidence is missing?',
    'What disagrees with this pattern?',
    'What should I observe next?',
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ask WhyPulse')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const StatusPill(
                  label: 'Recurring 1:1 evidence only',
                  color: PulseColors.violet,
                  icon: Icons.filter_alt_outlined,
                ),
                const SizedBox(height: 14),
                Text(
                  'Ask about the comparison, missing context, or counterevidence.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Diagnosis, treatment, and unrelated questions are blocked.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final question in questions)
                      ActionChip(
                        label: Text(question),
                        onPressed: state.askInProgress
                            ? null
                            : () => state.ask(question),
                      ),
                  ],
                ),
                if (state.chatMessages.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  for (final message in state.chatMessages) ...[
                    _ChatBubble(message: message),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
          if (state.askInProgress) const LinearProgressIndicator(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask about this evidence',
                      ),
                      onSubmitted: (value) {
                        if (state.askInProgress) return;
                        state.ask(value);
                        controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: state.askInProgress
                        ? null
                        : () {
                            state.ask(controller.text);
                            controller.clear();
                          },
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessageData message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.fromUser
              ? PulseColors.lime.withValues(alpha: 0.14)
              : PulseColors.surface,
          border: Border.all(color: PulseColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text),
            if (!message.fromUser && message.uncertainty != null) ...[
              const SizedBox(height: 10),
              Text(
                'Limit: ${message.uncertainty}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (!message.fromUser && message.evidence.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final citation in message.evidence)
                    Chip(label: Text(citation)),
                ],
              ),
            ],
            if (!message.fromUser && message.runtimeLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                message.runtimeLabel!,
                style: Theme.of(context).textTheme.labelSmall,
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
    final isDraft =
        state.experimentStatus == ExperimentStatus.draft ||
        state.experimentStatus == ExperimentStatus.invalidated;
    final isEnded =
        state.experimentStatus == ExperimentStatus.cancelled ||
        state.experimentStatus == ExperimentStatus.stopped;
    final eligibleFinding = state.finding?.isCurrent ?? false;
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('experiments-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList.list(
              children: [
                const PageIntro(
                  title: 'Test one small change',
                  subtitle:
                      'Experiments stay tied to one finding and use the same evidence rules.',
                ),
                const SizedBox(height: 24),
                if (state.mode == AppMode.live && !eligibleFinding)
                  const EmptyState(
                    icon: Icons.science_outlined,
                    title: 'No experiment is ready',
                    detail:
                        'A Live experiment can start only from an eligible Live finding. Demo proposals never appear here.',
                  )
                else ...[
                  if (isDraft)
                    _ProposedExperimentCard(
                      onReview: () =>
                          openPulsePage(context, const ExperimentSetupScreen()),
                    )
                  else if (isEnded)
                    _EndedExperimentCard(state: state)
                  else
                    _ActiveExperimentCard(state: state),
                  if (state.experimentOperationMessage case final message?) ...[
                    const SizedBox(height: 12),
                    NoticeBox(icon: Icons.error_outline_rounded, text: message),
                  ],
                  const SizedBox(height: 28),
                  const SectionTitle(
                    title: 'How results are described',
                    subtitle:
                        'The outcome can strengthen, weaken, stay unchanged, or remain inconclusive.',
                  ),
                  const SizedBox(height: 12),
                  SurfaceCard(
                    onTap: () => openPulsePage(
                      context,
                      const ExperimentOutcomeCasesScreen(),
                    ),
                    child: const ActionSummary(
                      icon: Icons.grid_view_rounded,
                      title: 'Deterministic result cases',
                      detail: 'See all four outcomes before starting a test.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const NoticeBox(
                    icon: Icons.health_and_safety_outlined,
                    text:
                        'Experiments are personal observations, not treatment. Stop if the change feels unsafe or unhelpful.',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposedExperimentCard extends StatelessWidget {
  const _ProposedExperimentCard({required this.onReview});

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      accent: PulseColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusPill(label: 'PROPOSED', color: PulseColors.cyan),
          const SizedBox(height: 16),
          Text(
            'Add a 10-minute quiet buffer before your recurring 1:1.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Keep the meeting and normal routine the same. Record caffeine, exercise, illness, and travel.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const InfoLine(label: 'Length', value: '3 eligible meetings'),
          const SizedBox(height: 8),
          const InfoLine(label: 'Compare', value: 'Pre-event heart rate'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onReview,
              child: const Text('Review proposed test'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveExperimentCard extends StatelessWidget {
  const _ActiveExperimentCard({required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final complete = state.experimentStatus == ExperimentStatus.completed;
    final paused = state.experimentStatus == ExperimentStatus.paused;
    return SurfaceCard(
      accent: complete ? PulseColors.mint : PulseColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: complete
                ? 'COMPLETE'
                : paused
                ? 'PAUSED'
                : 'ACTIVE',
            color: complete
                ? PulseColors.mint
                : paused
                ? PulseColors.amber
                : PulseColors.cyan,
          ),
          const SizedBox(height: 16),
          Text(
            'Quiet buffer before recurring 1:1',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Text(
            '${state.experimentCheckIns}/3 eligible meetings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.experimentCheckIns / 3,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 18),
          if (!complete && !paused)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.completeExperimentOccurrence,
                child: const Text('Complete occurrence check-in'),
              ),
            )
          else if (complete)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    openPulsePage(context, const ExperimentResultScreen()),
                child: const Text('View result'),
              ),
            ),
          if (paused)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.experimentOperationInProgress
                    ? null
                    : state.toggleExperimentPause,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume experiment'),
              ),
            ),
          if (!complete && !paused) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.experimentOperationInProgress
                    ? null
                    : state.toggleExperimentPause,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause experiment'),
              ),
            ),
          ],
          if (!complete) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: state.experimentOperationInProgress
                        ? null
                        : () => _confirmEnd(
                            context,
                            title: 'Cancel this experiment?',
                            detail:
                                'Scheduled reminders will be cancelled. The protocol and completed check-ins stay in History.',
                            actionLabel: 'Cancel experiment',
                            action: state.cancelExperiment,
                          ),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: state.experimentOperationInProgress
                        ? null
                        : () => _confirmEnd(
                            context,
                            title: 'Stop early?',
                            detail:
                                'The partial test will be preserved as stopped and no conclusion will be forced.',
                            actionLabel: 'Stop early',
                            action: state.stopExperiment,
                          ),
                    child: const Text('Stop early'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmEnd(
    BuildContext context, {
    required String title,
    required String detail,
    required String actionLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep experiment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }
}

class _EndedExperimentCard extends StatelessWidget {
  const _EndedExperimentCard({required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final cancelled = state.experimentStatus == ExperimentStatus.cancelled;
    return SurfaceCard(
      accent: PulseColors.textTertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: cancelled ? 'CANCELLED' : 'STOPPED',
            color: PulseColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Quiet buffer before recurring 1:1',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${state.experimentCheckIns}/3 eligible meetings were recorded. The partial protocol remains preserved without a forced result.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  openPulsePage(context, const ExperimentSetupScreen()),
              child: const Text('Review a new test'),
            ),
          ),
        ],
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
  var consent = false;

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review experiment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '10-minute quiet buffer',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'A small test linked only to the recurring 1:1 finding.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const SurfaceCard(
            child: Column(
              children: [
                InfoLine(
                  label: 'Change',
                  value: '10 quiet minutes before start',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Keep stable',
                  value: 'Meeting and normal routine',
                ),
                Divider(height: 24),
                InfoLine(label: 'Duration', value: '3 eligible meetings'),
                Divider(height: 24),
                InfoLine(
                  label: 'Primary measure',
                  value: 'Pre-event heart rate',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NoticeBox(
            icon: Icons.stop_circle_outlined,
            text:
                'Stop at any time. Missed or confounded meetings remain visible and are not forced into the result.',
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: (value) => setState(() => consent = value ?? false),
            title: const Text(
              'I understand this is a personal test, not treatment.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: consent
                ? () {
                    state.activateExperiment();
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Start 3-meeting experiment'),
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
    return const ExperimentOutcomeScreen(
      outcome: ExperimentOutcome.strengthened,
    );
  }
}

class ExperimentOutcomeCasesScreen extends StatelessWidget {
  const ExperimentOutcomeCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const outcomes = ExperimentOutcome.values;
    return Scaffold(
      appBar: AppBar(title: const Text('Deterministic result cases')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Four possible outcomes',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No result is upgraded just to make the experiment feel successful.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final outcome in outcomes) ...[
            SurfaceCard(
              onTap: () => openPulsePage(
                context,
                ExperimentOutcomeScreen(outcome: outcome),
              ),
              child: ActionSummary(
                icon: _outcomeIcon(outcome),
                title: _outcomeTitle(outcome),
                detail: _outcomeShort(outcome),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class ExperimentOutcomeScreen extends StatelessWidget {
  const ExperimentOutcomeScreen({super.key, required this.outcome});

  final ExperimentOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final inconclusive = outcome == ExperimentOutcome.inconclusive;
    return Scaffold(
      appBar: AppBar(title: Text(_outcomeTitle(outcome))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          StatusPill(
            label: _outcomeTitle(outcome).toUpperCase(),
            color: _outcomeColor(outcome),
          ),
          const SizedBox(height: 18),
          Text(
            _outcomeHeadline(outcome),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            _outcomeDetail(outcome),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (inconclusive)
            const NoticeBox(
              icon: Icons.hourglass_empty_rounded,
              text: 'Evidence gate not reached',
            )
          else
            const SurfaceCard(
              child: Column(
                children: [
                  InfoLine(label: 'Eligible meetings', value: '3'),
                  Divider(height: 24),
                  InfoLine(label: 'Context complete', value: '3 of 3'),
                  Divider(height: 24),
                  InfoLine(label: 'Analysis', value: 'Experiment v1'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _outcomeTitle(ExperimentOutcome outcome) => switch (outcome) {
  ExperimentOutcome.strengthened => 'Strengthened',
  ExperimentOutcome.weakened => 'Weakened',
  ExperimentOutcome.unchanged => 'Unchanged',
  ExperimentOutcome.inconclusive => 'Inconclusive',
};

String _outcomeShort(ExperimentOutcome outcome) => switch (outcome) {
  ExperimentOutcome.strengthened =>
    'The pattern became clearer during the test.',
  ExperimentOutcome.weakened => 'The original difference became smaller.',
  ExperimentOutcome.unchanged =>
    'The test did not materially change the measure.',
  ExperimentOutcome.inconclusive =>
    'Too little complete evidence to resolve the test.',
};

String _outcomeHeadline(ExperimentOutcome outcome) => switch (outcome) {
  ExperimentOutcome.strengthened =>
    'Recovery was faster with the quiet buffer.',
  ExperimentOutcome.weakened => 'The pre-event difference narrowed.',
  ExperimentOutcome.unchanged => 'The measured pattern stayed similar.',
  ExperimentOutcome.inconclusive =>
    'There is not enough complete evidence to resolve the test.',
};

String _outcomeDetail(ExperimentOutcome outcome) => switch (outcome) {
  ExperimentOutcome.strengthened =>
    'All three eligible meetings had complete context, and recovery returned toward baseline sooner.',
  ExperimentOutcome.weakened =>
    'The difference moved closer to matched controls, but the result remains a personal observation.',
  ExperimentOutcome.unchanged =>
    'The measured difference stayed within the pre-test range.',
  ExperimentOutcome.inconclusive =>
    'One meeting was missed and another lacked enough heart-rate coverage. WhyPulse will not force a conclusion.',
};

IconData _outcomeIcon(ExperimentOutcome outcome) => switch (outcome) {
  ExperimentOutcome.strengthened => Icons.trending_up_rounded,
  ExperimentOutcome.weakened => Icons.trending_down_rounded,
  ExperimentOutcome.unchanged => Icons.trending_flat_rounded,
  ExperimentOutcome.inconclusive => Icons.question_mark_rounded,
};

Color _outcomeColor(ExperimentOutcome outcome) => switch (outcome) {
  ExperimentOutcome.strengthened => PulseColors.mint,
  ExperimentOutcome.weakened => PulseColors.amber,
  ExperimentOutcome.unchanged => PulseColors.nullBlue,
  ExperimentOutcome.inconclusive => PulseColors.textTertiary,
};

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  WhyPulseState? _modelDownloadPollingState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = WhyPulseScope.of(context);
    final shouldPoll = state.tabIndex == 3;
    if (shouldPoll && !identical(_modelDownloadPollingState, state)) {
      _modelDownloadPollingState?.endModelDownloadPolling();
      _modelDownloadPollingState = state;
      state.beginModelDownloadPolling();
    } else if (!shouldPoll && _modelDownloadPollingState != null) {
      _modelDownloadPollingState?.endModelDownloadPolling();
      _modelDownloadPollingState = null;
    }
  }

  @override
  void dispose() {
    _modelDownloadPollingState?.endModelDownloadPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('settings-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList.list(
              children: [
                const PageIntro(
                  title: 'Settings',
                  subtitle:
                      'Data mode, privacy, proof, and accessibility in one place.',
                ),
                const SizedBox(height: 20),
                SurfaceCard(
                  onTap: () => _showModeSheet(state),
                  child: ActionSummary(
                    icon: state.mode == AppMode.demo
                        ? Icons.science_outlined
                        : Icons.person_outline_rounded,
                    title: state.mode == AppMode.demo
                        ? 'Demo Data'
                        : 'Live evidence',
                    detail: state.mode == AppMode.demo
                        ? 'Fictional encrypted store only'
                        : 'Your encrypted local store',
                    trailing: ModeBadge(mode: state.mode),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Data and privacy'),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ModelDownloadSettingsRow(state: state),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.auto_graph_rounded,
                        title: 'Preview Lab',
                        subtitle:
                            'Weekly Digest, What-if Lab, and clinician layout',
                        onTap: () => openPulsePage(
                          context,
                          const PreviewGalleryScreen(),
                        ),
                      ),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.hub_outlined,
                        title: 'Sources',
                        subtitle: 'Connections, permissions, and stored fields',
                        onTap: () =>
                            openPulsePage(context, const SourcesScreen()),
                      ),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy',
                        subtitle:
                            'Encryption, separation, and model boundaries',
                        onTap: () =>
                            openPulsePage(context, const PrivacyScreen()),
                      ),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.verified_outlined,
                        title: 'Proof & exports',
                        subtitle: 'Evidence receipt and export readiness',
                        onTap: () =>
                            openPulsePage(context, const ProofScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Experience'),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsRow(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Expansion',
                        subtitle: 'Future capabilities · clearly marked Later',
                        onTap: () =>
                            openPulsePage(context, const ExpansionScreen()),
                      ),
                      const Divider(),
                      SwitchListTile(
                        value: state.reducedMotion,
                        onChanged: state.setReducedMotion,
                        secondary: const Icon(Icons.motion_photos_off_outlined),
                        title: const Text('Reduced motion'),
                        subtitle: const Text(
                          'Use immediate page and state changes',
                        ),
                      ),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About WhyPulse',
                        subtitle: 'Version, analysis boundary, and safety',
                        onTap: () =>
                            openPulsePage(context, const AboutScreen()),
                      ),
                    ],
                  ),
                ),
                if (state.mode == AppMode.demo) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: state.resetDemo,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset deterministic demo'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showModeSheet(WhyPulseState state) async {
    final selected = await showModalBottomSheet<AppMode>(
      context: context,
      backgroundColor: PulseColors.elevated,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                'Switching closes the current repository before the other encrypted store opens.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              RadioGroup<AppMode>(
                groupValue: state.mode,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
                child: const Column(
                  children: [
                    RadioListTile<AppMode>(
                      value: AppMode.live,
                      title: Text('Live evidence'),
                      subtitle: Text('Your reviewed Android sources'),
                    ),
                    RadioListTile<AppMode>(
                      value: AppMode.demo,
                      title: Text('Demo Data'),
                      subtitle: Text('Fictional deterministic history'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null || selected == state.mode) return;
    if (selected == AppMode.demo) {
      state.setMode(AppMode.demo);
      return;
    }

    final status = await state.inspectModelDownload();
    if (!mounted) return;
    if (!_modelDownloadConfigurationUsable(status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live needs a configured model URL in this build.'),
        ),
      );
      return;
    }
    if (status.state == ModelDownloadState.requiresConsent) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const _LiveModelConsentScreen(),
        ),
      );
      return;
    }
    state.setMode(AppMode.live);
  }
}

class _ModelDownloadSettingsRow extends StatelessWidget {
  const _ModelDownloadSettingsRow({required this.state});

  final WhyPulseState state;

  @override
  Widget build(BuildContext context) {
    final status = state.modelDownloadStatus;
    final active = switch (status.state) {
      ModelDownloadState.queued ||
      ModelDownloadState.downloading ||
      ModelDownloadState.verifying => true,
      _ => false,
    };
    final canRetry =
        state.mode == AppMode.live &&
        status.retryable &&
        (status.state == ModelDownloadState.failed ||
            status.state == ModelDownloadState.cancelled);
    final canDownload =
        state.mode == AppMode.live &&
        status.state == ModelDownloadState.requiresConsent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.memory_rounded),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'On-device AI model',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modelDownloadSummary(status),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PulseColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.state == ModelDownloadState.downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: status.progress / 100),
          ],
          if (active || canRetry || canDownload) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: active
                  ? TextButton.icon(
                      onPressed: state.modelDownloadOperationInProgress
                          ? null
                          : () => unawaited(state.cancelModelDownload()),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                    )
                  : TextButton.icon(
                      onPressed: state.modelDownloadOperationInProgress
                          ? null
                          : () => unawaited(
                              canRetry
                                  ? state.retryModelDownload()
                                  : state.acceptAndStartModelDownload(),
                            ),
                      icon: Icon(
                        canRetry
                            ? Icons.refresh_rounded
                            : Icons.download_rounded,
                      ),
                      label: Text(canRetry ? 'Retry' : 'Download model'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleInfoScreen(
      title: 'Privacy',
      headline: 'Local by default, separated by design',
      intro:
          'WhyPulse keeps Live and Demo in different encrypted databases with different Android Keystore keys.',
      sections: [
        (
          'Live and Demo',
          'Repositories can open only one store at a time. Switching modes never copies records.',
        ),
        (
          'Calendar',
          'Only reviewed category and timing are stored. Titles, people, locations, and descriptions are discarded.',
        ),
        (
          'Model boundary',
          'Only structured evidence may reach an explanation runtime. Raw identities and private event text do not.',
        ),
        (
          'Recovery',
          'If a key cannot be recovered, WhyPulse fails closed and asks before deleting or recreating data.',
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleInfoScreen(
      title: 'About WhyPulse',
      headline: 'Evidence before explanation',
      intro:
          'WhyPulse aligns repeated moments with personal health signals, calculates comparisons deterministically, and keeps uncertainty visible.',
      sections: [
        ('App', 'WhyPulse 0.1.0 · Android-first'),
        (
          'Current phase',
          'Encrypted Live and Demo stores are implemented. Native sources and deterministic meeting analytics come next.',
        ),
        (
          'Safety',
          'WhyPulse does not diagnose conditions, recommend treatment, or label you healthy or unhealthy.',
        ),
      ],
    );
  }
}

class _SimpleInfoScreen extends StatelessWidget {
  const _SimpleInfoScreen({
    required this.title,
    required this.headline,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String headline;
  final String intro;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(headline, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            intro,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          for (final section in sections) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.$1,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    section.$2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, this.existing});

  final CheckInData? existing;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late String category;
  late final TextEditingController detailController;
  late final TextEditingController customLabelController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    category = existing == null
        ? 'Caffeine'
        : '${existing.category[0].toUpperCase()}${existing.category.substring(1)}';
    detailController = TextEditingController(text: existing?.detail);
    customLabelController = TextEditingController(text: existing?.customLabel);
  }

  @override
  void dispose() {
    detailController.dispose();
    customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    const categories = [
      'Caffeine',
      'Exercise',
      'Illness',
      'Mood',
      'Travel',
      'Custom',
    ];
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit check-in' : 'Add check-in')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'What context matters right now?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose one category. A short detail is optional.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in categories)
                ChoiceChip(
                  label: Text(item),
                  selected: category == item,
                  onSelected: (_) => setState(() => category = item),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (category == 'Custom') ...[
            TextField(
              controller: customLabelController,
              decoration: const InputDecoration(
                labelText: 'Reviewed category name',
                hintText: 'For example: Medication timing',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: detailController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '$category detail',
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          const NoticeBox(
            icon: Icons.refresh_rounded,
            text:
                'Adding, editing, or deleting a check-in schedules evidence recomputation.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final detail = detailController.text.trim();
              final customLabel = customLabelController.text.trim();
              if (category == 'Custom' && customLabel.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name the custom category before saving.'),
                  ),
                );
                return;
              }
              final checkIn = CheckInData(
                id:
                    widget.existing?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                when: widget.existing?.when ?? DateTime.now(),
                context: category == 'Custom'
                    ? customLabel
                    : '$category check-in',
                detail: detail.isEmpty ? 'No extra detail' : detail,
                icon: _checkInIcon(category),
                category: category.toLowerCase(),
                customLabel: category == 'Custom' ? customLabel : null,
              );
              if (editing) {
                state.editCheckIn(checkIn);
              } else {
                state.addCheckIn(checkIn);
              }
              Navigator.pop(context);
            },
            child: Text(editing ? 'Save changes' : 'Save check-in'),
          ),
          if (editing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete this check-in?'),
                    content: const Text(
                      'The check-in will be removed and affected evidence will be recomputed.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete check-in'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                state.deleteCheckIn(widget.existing!.id);
                Navigator.pop(context);
              },
              child: const Text('Delete check-in'),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _checkInIcon(String category) => switch (category) {
  'Caffeine' => Icons.coffee_outlined,
  'Exercise' => Icons.directions_run_rounded,
  'Illness' => Icons.sick_outlined,
  'Mood' => Icons.sentiment_satisfied_alt_outlined,
  'Travel' => Icons.flight_outlined,
  _ => Icons.edit_note_rounded,
};

class ProofScreen extends StatelessWidget {
  const ProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final finding = state.finding;
    if (finding == null || !finding.isCurrent) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proof & Export')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            StatusPill(
              label: state.mode == AppMode.live
                  ? 'NO LIVE RECEIPT'
                  : 'NO CURRENT RECEIPT',
              color: PulseColors.textTertiary,
            ),
            const SizedBox(height: 20),
            const EmptyState(
              icon: Icons.verified_outlined,
              title: 'No Live evidence to export',
              detail:
                  'A receipt will appear only after a Live finding passes deterministic analysis and evidence gates.',
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Proof & Export')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          StatusPill(
            label: state.mode == AppMode.demo
                ? 'DEMO RECEIPT'
                : 'LOCAL RECEIPT',
            color: PulseColors.lime,
          ),
          const SizedBox(height: 16),
          Text(
            'Recurring 1:1 evidence receipt',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'A compact record of the claim, measures, sources, and versions used.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              children: [
                InfoLine(label: 'Finding', value: finding.title),
                Divider(height: 24),
                InfoLine(
                  label: 'Difference',
                  value:
                      '${finding.medianDifferenceBpm >= 0 ? '+' : ''}${finding.medianDifferenceBpm.toStringAsFixed(0)} bpm',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Comparable',
                  value: '${finding.includedCount} meetings',
                ),
                Divider(height: 24),
                InfoLine(label: 'Analysis', value: finding.evidenceVersion),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: 'INTEGRITY HASH'),
          const SizedBox(height: 10),
          SurfaceCard(
            child: SelectableText(
              finding.evidenceHash,
              style: TextStyle(
                fontFamily: 'monospace',
                color: PulseColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            onTap: () => openPulsePage(context, const PreviewScreen()),
            child: const ActionSummary(
              icon: Icons.description_outlined,
              title: 'Reviewed Clinician Report',
              detail: 'Preview layout using sample data',
              trailing: StatusPill(label: 'PREVIEW', color: PulseColors.violet),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Export status'),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              final path = await state.exportEvidence();
              if (!context.mounted || path == null) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Exported JSON and PDF beside the local store.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Export PDF + JSON'),
          ),
          const SizedBox(height: 10),
          const NoticeBox(
            icon: Icons.schedule_outlined,
            text:
                'PDF and canonical JSON exports are generated from this evidence version and carry the same integrity hash.',
          ),
        ],
      ),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinician report preview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(
            label: 'PREVIEW · SAMPLE DATA',
            color: PulseColors.violet,
          ),
          const SizedBox(height: 18),
          Text(
            'A one-page evidence summary',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Designed for review, with the claim, measures, limitations, and provenance visible together.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLine(
                  label: 'Observed',
                  value: 'Higher pre-event heart rate',
                ),
                Divider(height: 24),
                InfoLine(label: 'Repeated', value: '6 of 8 meetings'),
                Divider(height: 24),
                InfoLine(label: 'Limit', value: 'Missing caffeine context'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewGalleryScreen extends StatelessWidget {
  const PreviewGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(label: 'PREVIEW', color: PulseColors.violet),
          const SizedBox(height: 16),
          Text(
            'Explore the next evidence views',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'These views are interactive previews. They do not send reports, schedule digests, or alter verified evidence.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          SurfaceCard(
            onTap: () => openPulsePage(context, const WeeklyDigestScreen()),
            child: const ActionSummary(
              icon: Icons.calendar_view_week_rounded,
              title: 'Weekly Digest',
              detail: 'A seven-day evidence and source-readiness summary',
              trailing: StatusPill(label: 'PREVIEW', color: PulseColors.violet),
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            onTap: () => openPulsePage(context, const WhatIfLabScreen()),
            child: const ActionSummary(
              icon: Icons.tune_rounded,
              title: 'What-if Lab',
              detail: 'Explore a simulated change without editing evidence',
              trailing: StatusPill(label: 'PREVIEW', color: PulseColors.violet),
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            onTap: () => openPulsePage(context, const PreviewScreen()),
            child: const ActionSummary(
              icon: Icons.description_outlined,
              title: 'Reviewed Clinician Report',
              detail: 'A sample one-page review layout',
              trailing: StatusPill(label: 'PREVIEW', color: PulseColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyDigestScreen extends StatelessWidget {
  const WeeklyDigestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WhyPulseScope.of(context);
    final finding = state.finding;
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Digest preview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          StatusPill(
            label: state.mode == AppMode.demo
                ? 'PREVIEW · SAMPLE DATA'
                : 'PREVIEW · LOCAL SNAPSHOT',
            color: PulseColors.violet,
          ),
          const SizedBox(height: 18),
          Text(
            'Your week in evidence',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'A compact view of what was observed, what changed, and what still needs context.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          if (finding == null || !finding.isCurrent)
            const EmptyState(
              icon: Icons.calendar_view_week_rounded,
              title: 'No current evidence for this preview',
              detail:
                  'The digest preview will not invent a finding when Live evidence is unavailable.',
            )
          else ...[
            SurfaceCard(
              accent: PulseColors.lime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusPill(
                    label: 'CURRENT FINDING',
                    color: PulseColors.lime,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    finding.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${finding.positiveCount} of ${finding.includedCount} comparable observations repeated in the promoted direction.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                children: [
                  InfoLine(
                    label: 'Source records',
                    value: '${state.observeDashboard.totalRecordCount}',
                  ),
                  const Divider(height: 24),
                  InfoLine(
                    label: 'Active days',
                    value: '${state.observeDashboard.activeDayCount}',
                  ),
                  const Divider(height: 24),
                  InfoLine(
                    label: 'Influences logged',
                    value: '${state.checkIns.length}',
                  ),
                  const Divider(height: 24),
                  InfoLine(
                    label: 'Still unresolved',
                    value: '${finding.unresolvedInfluenceCount}',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const NoticeBox(
            icon: Icons.notifications_off_outlined,
            text:
                'Preview only: no weekly notification or automatic report delivery is enabled.',
          ),
        ],
      ),
    );
  }
}

class WhatIfLabScreen extends StatefulWidget {
  const WhatIfLabScreen({super.key});

  @override
  State<WhatIfLabScreen> createState() => _WhatIfLabScreenState();
}

class _WhatIfLabScreenState extends State<WhatIfLabScreen> {
  double quietMinutes = 10;

  @override
  Widget build(BuildContext context) {
    final finding = WhyPulseScope.of(context).finding;
    final originalRecovery = finding?.recoveryDurationMinutes ?? 42;
    final originalDifference = finding?.medianDifferenceBpm ?? 11;
    final projectedRecovery = math.max(
      0,
      originalRecovery - quietMinutes * .45,
    );
    final projectedDifference = math.max(
      0,
      originalDifference - quietMinutes * .2,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('What-if Lab preview')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(
            label: 'PREVIEW · SIMULATION',
            color: PulseColors.violet,
          ),
          const SizedBox(height: 18),
          Text(
            'Explore, without changing evidence',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust a hypothetical quiet buffer. The projection below is illustrative—not measured, verified, or saved.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quietMinutes.round()} quiet minutes before the meeting',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Slider(
                  value: quietMinutes,
                  min: 0,
                  max: 20,
                  divisions: 4,
                  label: '${quietMinutes.round()} minutes',
                  onChanged: (value) => setState(() => quietMinutes = value),
                ),
                const SizedBox(height: 8),
                InfoLine(
                  label: 'Illustrative recovery',
                  value: '${projectedRecovery.round()} min',
                ),
                const Divider(height: 24),
                InfoLine(
                  label: 'Illustrative difference',
                  value: '+${projectedDifference.toStringAsFixed(0)} bpm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const NoticeBox(
            icon: Icons.science_outlined,
            text:
                'Simulation only. Start an eligible experiment to measure a change; this control never edits the Evidence screen or History.',
          ),
        ],
      ),
    );
  }
}

class ExpansionScreen extends StatelessWidget {
  const ExpansionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expansion')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(label: 'LATER', color: PulseColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Future capabilities · no unfinished integrations',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'These ideas are outside the current Android implementation. They are shown only to make the boundary clear.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final source in expansionSources) ...[
            SurfaceCard(
              child: ActionSummary(
                icon: source.icon,
                title: source.name,
                detail: source.description,
                trailing: const StatusPill(
                  label: 'LATER',
                  color: PulseColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class PulseMark extends StatelessWidget {
  const PulseMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PulseColors.lime,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.monitor_heart_rounded,
        size: size * 0.58,
        color: PulseColors.canvas,
      ),
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
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
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: accent?.withValues(alpha: 0.5) ?? PulseColors.border,
      ),
    );
    return Material(
      color: PulseColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Semantics(
              button: true,
              child: InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: color, size: 14),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ModeBadge extends StatelessWidget {
  const ModeBadge({super.key, required this.mode});

  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: mode == AppMode.demo ? 'DEMO' : 'LIVE',
      color: mode == AppMode.demo ? PulseColors.violet : PulseColors.mint,
    );
  }
}

class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PulseColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PulseColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class MetricValue {
  const MetricValue({required this.label, required this.value});

  final String label;
  final String value;
}

class MetricStrip extends StatelessWidget {
  const MetricStrip({super.key, required this.metrics});

  final List<MetricValue> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metrics[index].value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  metrics[index].label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (index != metrics.length - 1)
            const SizedBox(height: 38, child: VerticalDivider(width: 20)),
        ],
      ],
    );
  }
}

class BulletLine extends StatelessWidget {
  const BulletLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: CircleAvatar(radius: 3, backgroundColor: PulseColors.lime),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class ActionSummary extends StatelessWidget {
  const ActionSummary({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: PulseColors.cyan),
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
        const SizedBox(width: 10),
        trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: PulseColors.textTertiary,
            ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: PulseColors.textTertiary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
