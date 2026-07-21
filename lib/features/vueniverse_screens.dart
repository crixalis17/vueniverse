import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/app/theme.dart';
import 'package:vueniverse/data/demo/demo_scenario_analysis_repository.dart';
import 'package:vueniverse/data/demo/demo_ui_content.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/platform/generated/model_download_api.g.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

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
  AppMode? selectedMode;
  VueniverseState? _modelDownloadPollingState;

  Future<void> _finishOrShowModelDownload(AppMode mode) async {
    selectedMode = mode;
    final state = VueniverseScope.of(context);
    final status = await state.inspectModelDownload();
    if (!mounted) return;
    if (_modelDownloadIsReady(status)) {
      state.finishOnboarding(mode);
      return;
    }
    _setStep(3);
  }

  void _setStep(int value) {
    if (step != 3 && value == 3) {
      final state = VueniverseScope.of(context);
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
    final state = VueniverseScope.of(context);
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
              onDemo: () {
                unawaited(_finishOrShowModelDownload(AppMode.demo));
              },
              onLive: () {
                selectedMode = AppMode.live;
                _setStep(2);
                unawaited(state.inspectModelDownload());
              },
            ),
            2 => _SourceSetupStep(
              key: const ValueKey('sources'),
              onBack: () => _setStep(1),
              onContinue: () {
                unawaited(_finishOrShowModelDownload(AppMode.live));
              },
              onDemo: () {
                unawaited(_finishOrShowModelDownload(AppMode.demo));
              },
            ),
            _ => _ModelDownloadConsentStep(
              key: const ValueKey('model-download'),
              status: state.modelDownloadStatus,
              operationInProgress: state.modelDownloadOperationInProgress,
              continueLabel: selectedMode == AppMode.demo
                  ? 'Continue to Snapshot'
                  : 'Continue to Live',
              onBack: () => _setStep(selectedMode == AppMode.demo ? 1 : 2),
              onDownload: () async {
                final current = state.modelDownloadStatus.state;
                final status = switch (current) {
                  ModelDownloadState.available => state.modelDownloadStatus,
                  ModelDownloadState.failed || ModelDownloadState.cancelled =>
                    await state.retryModelDownload(),
                  ModelDownloadState.queued ||
                  ModelDownloadState.downloading ||
                  ModelDownloadState.verifying => state.modelDownloadStatus,
                  _ => await state.acceptAndStartModelDownload(),
                };
                if (!mounted || !_modelDownloadIsReady(status)) {
                  return;
                }
                state.finishOnboarding(selectedMode ?? AppMode.live);
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
            Text('VUENIVERSE', style: TextStyle(fontWeight: FontWeight.w700)),
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
          'Vueniverse compares repeated events with your usual health data, shows the numbers behind any pattern, and helps you test one small change.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
        ),
        const SizedBox(height: 20),
        const NoticeBox(
          icon: Icons.science_outlined,
          text:
              'Start with Snapshot (Demo) to try the complete app. Its health data is fictional, but it uses the real MedGemma inference path after the model download—not a prewritten AI answer.',
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
                detail:
                    'See the numbers, what was left out, and which results did not match.',
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
          'Vueniverse describes personal patterns. It does not diagnose or recommend treatment.',
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
                'Explore your Snapshot',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'A complete 30-day Snapshot is ready, so you can review a pattern, ask questions, and try a small test without connecting sources. The data is fictional, but MedGemma inference is real after the model download.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDemo,
                  child: const Text('Explore Snapshot'),
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
        'Snapshot',
        'A ready-to-explore health timeline; always separate from Live',
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
          'Choose what Vueniverse can use.',
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
              'Calendar titles are shown only during review. Vueniverse keeps the category and timing—not names, attendees, or descriptions.',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue with selected sources'),
        ),
        TextButton(
          onPressed: onDemo,
          child: const Text('Use Snapshot instead'),
        ),
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
    this.continueLabel = 'Continue to Live',
  });

  final ModelDownloadStatus status;
  final bool operationInProgress;
  final VoidCallback onBack;
  final Future<void> Function() onDownload;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final configured = _modelDownloadConfigurationUsable(status);
    final ready = status.state == ModelDownloadState.available;
    final downloadActive =
        status.state == ModelDownloadState.queued ||
        status.state == ModelDownloadState.downloading ||
        status.state == ModelDownloadState.verifying;
    final canAct =
        configured && !operationInProgress && (!downloadActive || ready);
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
          label: 'ON-DEVICE AI · REQUIRED',
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
          'Vueniverse downloads a 2.49 GB MedGemma model on unmetered Wi-Fi and verifies it before you continue. Android also shows the download progress.',
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
                    'Only the numbers needed for an explanation are sent to the model running on this phone.',
              ),
              Divider(height: 28),
              _OnboardingPoint(
                number: '2',
                title: 'Works after download',
                detail:
                    'Explanations can run offline after Vueniverse checks the downloaded file.',
              ),
              Divider(height: 28),
              _OnboardingPoint(
                number: '3',
                title: 'Required before continuing',
                detail:
                    'The next step unlocks only after the complete model finishes downloading to this device.',
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
              ? 'This app build has an invalid download link for the AI model. A developer needs to fix it before Live can be used.'
              : 'This app build is missing the download link for the AI model. A developer needs to add it before Live can be used.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: canAct ? onDownload : null,
          icon: Icon(_modelDownloadActionIcon(status)),
          label: Text(
            operationInProgress
                ? 'Preparing download…'
                : _modelDownloadActionLabel(status, continueLabel),
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
    final state = VueniverseScope.of(context);
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
              ModelDownloadState.available => state.modelDownloadStatus,
              ModelDownloadState.queued ||
              ModelDownloadState.downloading ||
              ModelDownloadState.verifying => state.modelDownloadStatus,
              _ => await state.acceptAndStartModelDownload(),
            };
            if (!context.mounted || !_modelDownloadIsReady(status)) {
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
      'Download complete · checking the file size and security code.',
    ModelDownloadState.available =>
      'Checked and ready for private, offline explanations.',
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
    'The downloaded file did not pass its safety check. Tap Retry to download it again.',
  'platform_unavailable' =>
    'Android model download services are unavailable in this build.',
  _ => 'Download failed (${detail.replaceAll('_', ' ')}).',
};

bool _modelDownloadConfigurationUsable(ModelDownloadStatus status) =>
    status.state != ModelDownloadState.notConfigured &&
    !(status.state == ModelDownloadState.failed &&
        status.detail == 'invalid_url');

bool _modelDownloadIsReady(ModelDownloadStatus status) =>
    status.state == ModelDownloadState.available;

String _modelDownloadActionLabel(
  ModelDownloadStatus status,
  String continueLabel,
) => switch (status.state) {
  ModelDownloadState.available => continueLabel,
  ModelDownloadState.failed || ModelDownloadState.cancelled => 'Retry download',
  ModelDownloadState.queued => 'Waiting for Wi-Fi…',
  ModelDownloadState.downloading => 'Downloading model…',
  ModelDownloadState.verifying => 'Verifying model…',
  _ => 'Download model',
};

IconData _modelDownloadActionIcon(ModelDownloadStatus status) =>
    switch (status.state) {
      ModelDownloadState.available => Icons.check_rounded,
      ModelDownloadState.failed ||
      ModelDownloadState.cancelled => Icons.refresh_rounded,
      ModelDownloadState.queued => Icons.schedule_rounded,
      ModelDownloadState.downloading => Icons.downloading_rounded,
      ModelDownloadState.verifying => Icons.verified_outlined,
      _ => Icons.download_rounded,
    };

String _formatModelBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const gb = 1000 * 1000 * 1000;
  const mb = 1000 * 1000;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  return '${(bytes / mb).toStringAsFixed(0)} MB';
}

class VueniverseShell extends StatelessWidget {
  const VueniverseShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
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
    final state = VueniverseScope.of(context);
    final hasCurrentFinding = state.hasDisplayableCurrentFinding;
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
                      ? 'A personal health Snapshot, calculated locally.'
                      : state.observeDashboard.isEmpty &&
                            state.checkIns.isEmpty &&
                            !hasCurrentFinding
                      ? 'Connect a source to start building your private timeline.'
                      : 'Your latest results from data stored on this phone.',
                ),
                const SizedBox(height: 24),
                _ReadinessCard(state: state),
                if (!hasCurrentFinding) ...[
                  const SizedBox(height: 20),
                  _EvidenceReadinessCard(state: state),
                ] else ...[
                  const SizedBox(height: 28),
                  SectionTitle(
                    title: 'What stands out',
                    subtitle: state.mode == AppMode.demo
                        ? 'One supported Snapshot pattern, with its limits kept visible.'
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
                    label: 'Ask Vueniverse about the recurring 1:1 pattern',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          openPulsePage(context, const AskVueniverseScreen()),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Ask about this pattern'),
                    ),
                  ),
                  if (state.mode == AppMode.demo) ...[
                    const SizedBox(height: 12),
                    JourneyCard(
                      onTap: () =>
                          openPulsePage(context, const DemoVideoTourScreen()),
                      child: const JourneySummary(
                        icon: Icons.movie_filter_outlined,
                        title: 'Run the guided Snapshot',
                        detail:
                            'A focused 90-second path through source data, deterministic evidence, MedGemma, and a personal test.',
                        trailing: StatusPill(
                          label: 'VIDEO PATH',
                          color: PulseColors.cyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    JourneyCard(
                      onTap: () => openPulsePage(
                        context,
                        const DemoEvidenceCasesScreen(),
                      ),
                      child: JourneySummary(
                        icon: Icons.view_carousel_outlined,
                        title:
                            'Explore ${demoScenarios.length} Snapshot scenarios',
                        detail:
                            'Compare 5 engine-calculated outcomes with lifecycle, experiment, and clearly marked illustrative stories.',
                        trailing: StatusPill(
                          label:
                              '${demoScenarios.where((scenario) => scenario.usesCalculatedEvidence).length} CALCULATED',
                          color: PulseColors.violet,
                        ),
                      ),
                    ),
                  ],
                ],
                if (state.checkIns.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  SectionTitle(
                    title: 'Recent context',
                    subtitle:
                        '${state.checkIns.length} check-ins help explain what sensors cannot see.',
                    actionLabel: 'Add check-in',
                    onAction: () =>
                        openPulsePage(context, const CheckInScreen()),
                  ),
                  const SizedBox(height: 12),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoVideoTourScreen extends StatelessWidget {
  const DemoVideoTourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guided recording')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(
            label: '58-SECOND APP PATH',
            color: PulseColors.cyan,
            icon: Icons.play_circle_outline_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'Tell one complete evidence story',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Open each scene in order. The recurring 1:1 is the current calculated finding; the wider gallery is there for a short outcome montage.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const NoticeBox(
            icon: Icons.verified_outlined,
            text:
                'The numbers come from privacy-safe Snapshot records. MedGemma only explains the checked aggregate, and the receipt names the runtime that actually answered.',
          ),
          const SizedBox(height: 20),
          _DemoTourStep(
            number: 1,
            timecode: '0:00–0:07',
            icon: Icons.monitor_heart_outlined,
            title: 'Establish data trust',
            detail:
                'Show 30 populated days, 2,990 records, eight streams, and the SQLCipher plus Android Keystore storage receipt.',
            actionLabel: 'Open Observe',
            onOpen: () => openPulsePage(context, const ObserveScreen()),
          ),
          const SizedBox(height: 12),
          _DemoTourStep(
            number: 2,
            timecode: '0:07–0:18',
            icon: Icons.fingerprint_rounded,
            title: 'Reveal the repeated moment',
            detail:
                'Overlay the included 1:1 traces against matched no-meeting windows and show recovery.',
            actionLabel: 'Open Moment Fingerprint',
            onOpen: () =>
                openPulsePage(context, const MomentFingerprintScreen()),
          ),
          const SizedBox(height: 12),
          _DemoTourStep(
            number: 3,
            timecode: '0:18–0:29',
            icon: Icons.fact_check_outlined,
            title: 'Challenge the result',
            detail:
                'Show 12 checked, 8 fairly compared, 2 counterexamples, and the explicit exclusions.',
            actionLabel: 'Open Evidence',
            onOpen: () => openPulsePage(context, const EvidenceScreen()),
          ),
          const SizedBox(height: 12),
          _DemoTourStep(
            number: 4,
            timecode: '0:29–0:43',
            icon: Icons.auto_awesome_rounded,
            title: 'Use bounded MedGemma',
            detail:
                'Generate the explanation, show citations and uncertainty, then linger on the local development machine, model, latency, and validation receipt.',
            actionLabel: 'Open Explanation',
            onOpen: () => openPulsePage(context, const ExplanationScreen()),
          ),
          const SizedBox(height: 12),
          _DemoTourStep(
            number: 5,
            timecode: '0:43–0:48',
            icon: Icons.science_outlined,
            title: 'Start a reversible test',
            detail:
                'Show the ten-minute quiet buffer, three-meeting plan, eligibility rules, and stop-any-time boundary.',
            actionLabel: 'Review Test This',
            onOpen: () => openPulsePage(context, const ExperimentSetupScreen()),
          ),
          const SizedBox(height: 12),
          _DemoTourStep(
            number: 6,
            timecode: '0:48–0:55',
            icon: Icons.trending_down_rounded,
            title: 'Show the measured result',
            detail:
                'Show three of three eligible meetings and median recovery moving from 54 to 45 minutes: nine minutes faster.',
            actionLabel: 'Open completed result',
            onOpen: () => openPulsePage(
              context,
              const ExperimentOutcomeScreen(
                outcome: ExperimentOutcome.strengthened,
                showSeededMetrics: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DemoTourStep(
            number: 7,
            timecode: '0:55–0:58',
            icon: Icons.receipt_long_outlined,
            title: 'End with the receipt',
            detail:
                'Show the Snapshot receipt, result version, evidence fingerprint, and matching local exports.',
            actionLabel: 'Open Proof & Export',
            onOpen: () => openPulsePage(context, const ProofScreen()),
          ),
          const SizedBox(height: 20),
          JourneyCard(
            onTap: () =>
                openPulsePage(context, const DemoEvidenceCasesScreen()),
            child: const JourneySummary(
              icon: Icons.view_carousel_outlined,
              title: 'Optional outcome montage',
              detail:
                  'Finish with calculated null, contradictory, developing, and insufficient-data cases plus clearly labelled lifecycle stories.',
              trailing: StatusPill(
                label: 'EXTRA SHOTS',
                color: PulseColors.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTourStep extends StatelessWidget {
  const _DemoTourStep({
    required this.number,
    required this.timecode,
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onOpen,
  });

  final int number;
  final String timecode;
  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PulseColors.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: PulseColors.cyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: PulseColors.cyan),
              const Spacer(),
              Text(timecode, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.state});

  final VueniverseState state;

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
    final isLive = state.mode == AppMode.live;
    final dashboardMatchesMode =
        state.observeDashboard.isDemo == (state.mode == AppMode.demo);
    final hasObservedData =
        dashboardMatchesMode && !state.observeDashboard.isEmpty;
    final needsSourceReview =
        isLive && !hasObservedData && attentionSources.isNotEmpty;
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            needsSourceReview
                ? Icons.add_link_rounded
                : hasObservedData || !isLive
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: needsSourceReview
                ? PulseColors.cyan
                : hasObservedData || !isLive
                ? PulseColors.mint
                : PulseColors.amber,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.mode == AppMode.demo
                      ? 'Snapshot is ready'
                      : needsSourceReview
                      ? 'Connect your data sources'
                      : !hasObservedData
                      ? 'Waiting for source data'
                      : readySources.isEmpty
                      ? 'Source data is available'
                      : '${readySources.length} ${readySources.length == 1 ? 'source is' : 'sources are'} ready',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  state.mode == AppMode.demo
                      ? '30 days loaded · encrypted locally'
                      : needsSourceReview
                      ? 'Review Health Connect and Calendar to start building your private timeline.'
                      : !hasObservedData
                      ? 'Vueniverse will show observations after your connected sources provide records.'
                      : attentionSources.isEmpty
                      ? 'Live sources are stored only in the encrypted Live database'
                      : '${attentionSources.length} ${attentionSources.length == 1 ? 'source needs' : 'sources need'} attention',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                if (hasObservedData || !isLive)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          openPulsePage(context, const ObserveScreen()),
                      icon: const Icon(Icons.insights_rounded, size: 19),
                      label: const Text('View source data'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          openPulsePage(context, const SourcesScreen()),
                      icon: const Icon(Icons.add_link_rounded, size: 19),
                      label: const Text('Manage sources'),
                    ),
                  ),
                if (hasObservedData || !isLive)
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
                if (isLive && state.checkIns.isEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () =>
                        openPulsePage(context, const CheckInScreen()),
                    icon: const Icon(Icons.edit_note_rounded, size: 19),
                    label: const Text('Add a check-in'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceReadinessCard extends StatelessWidget {
  const _EvidenceReadinessCard({
    required this.state,
    this.forExperiment = false,
  });

  final VueniverseState state;
  final bool forExperiment;

  @override
  Widget build(BuildContext context) {
    final dashboardMatchesMode =
        state.observeDashboard.isDemo == (state.mode == AppMode.demo);
    final hasComparisonInputs =
        dashboardMatchesMode &&
        state.observeDashboard.heartRateRecords > 0 &&
        state.observeDashboard.eventRecords > 0;
    final analysis = hasComparisonInputs ? state.finding : null;
    final usableRepeats = analysis?.includedCount ?? 0;
    final matchedBaselines = analysis?.controlsCount ?? 0;
    final completeness = analysis?.completeness ?? 0;
    final hasStartedAnalysis = analysis != null;

    final title = switch (analysis?.status) {
      'developing' => 'More comparable data is needed',
      'nullFinding' => 'The current comparison found no clear pattern',
      'contradictory' => 'The current comparison is mixed',
      'stale' => 'Updated data needs a fresh check',
      _ =>
        hasStartedAnalysis
            ? 'More usable data is needed'
            : 'What Vueniverse needs before it can compare',
    };

    return SurfaceCard(
      accent: PulseColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: PulseColors.cyan,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            forExperiment
                ? 'An experiment is suggested only after the same evidence checks produce a supported result.'
                : 'An insight appears only after enough Live data can be compared fairly.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _ReadinessRequirement(
            label: 'Usable repeats',
            value: '$usableRepeats of 4',
            progress: usableRepeats / 4,
          ),
          const SizedBox(height: 14),
          _ReadinessRequirement(
            label: 'Matched baselines',
            value: '$matchedBaselines of 4',
            progress: matchedBaselines / 4,
          ),
          const SizedBox(height: 14),
          _ReadinessRequirement(
            label: 'Health-data coverage',
            value: '${(completeness * 100).round()}% of 75%',
            progress: completeness / .75,
          ),
          const SizedBox(height: 16),
          Text(
            'After these minimums are met, the result may be a repeated pattern, no clear pattern, or a mixed result. Vueniverse does not force an insight.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (forExperiment) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: hasComparisonInputs
                  ? OutlinedButton.icon(
                      onPressed: () =>
                          openPulsePage(context, const ObserveScreen()),
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('View available data'),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          openPulsePage(context, const SourcesScreen()),
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Manage sources'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessRequirement extends StatelessWidget {
  const _ReadinessRequirement({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final complete = progress >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(width: 12),
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: complete ? PulseColors.mint : PulseColors.textTertiary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(value, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: progress.clamp(0, 1),
          minHeight: 5,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
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
        title: 'No current result',
        detail: 'Vueniverse has not found a clear repeated pattern yet.',
      );
    }
    final difference =
        '${current.medianDifferenceBpm >= 0 ? '+' : ''}${current.medianDifferenceBpm.toStringAsFixed(0)} bpm';
    return JourneyCard(
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
            '${current.positiveCount} of ${current.includedCount} meetings we could fairly compare showed the pattern. ${current.candidateCount - current.includedCount} ${current.candidateCount - current.includedCount == 1 ? 'meeting was' : 'meetings were'} left out because the data was missing or unreliable.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          MetricStrip(
            metrics: [
              MetricValue(label: 'USUAL DIFFERENCE', value: difference),
              MetricValue(
                label: 'SHOWED PATTERN',
                value: '${current.positiveCount} of ${current.includedCount}',
              ),
              MetricValue(
                label: 'DATA AVAILABLE',
                value: '${(current.completeness * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          NoticeBox(
            icon: Icons.info_outline_rounded,
            text: current.unresolvedInfluenceCount == 0
                ? 'All logged context has been reviewed for this pattern.'
                : '${current.unresolvedInfluenceCount} context ${current.unresolvedInfluenceCount == 1 ? 'detail still needs' : 'details still need'} review.',
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
    final state = VueniverseScope.of(context);
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
                  'See what Vueniverse has observed before it turns any of it into a finding.',
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
                  ? 'Snapshot records loaded through the production data path.'
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
                  ? 'This dashboard uses only the encrypted Snapshot store. It never reads or mixes Live records.'
                  : 'This view is built on this phone from records saved in one consistent format. Calendar titles, attendees, and identities are not kept.',
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
            label: dashboard.isDemo ? '30-DAY SNAPSHOT' : '30 DAYS · LOCAL',
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
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: PulseColors.mint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dashboard.isDemo
                      ? 'Snapshot records · SQLCipher-encrypted · separate Android Keystore key'
                      : 'Local records · SQLCipher-encrypted · Android Keystore-wrapped key',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PulseColors.textSecondary,
                  ),
                ),
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
    final state = VueniverseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Control which data Vueniverse can use',
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
                ? 'Snapshot mode reads only the encrypted Snapshot store. Live integrations stay off.'
                : 'Live mode never uses Snapshot records, results, personal tests, or downloads.',
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
              label: const Text('Reset Snapshot'),
            ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.state});

  final SourceData source;
  final VueniverseState state;

  @override
  Widget build(BuildContext context) {
    final isDemoSource = source.id == 'demo';
    final active = state.mode == AppMode.demo ? isDemoSource : !isDemoSource;
    final status = active
        ? _sourceStatusLabel(source.status)
        : (isDemoSource ? 'Available in Snapshot' : 'Available in Live');
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
    final state = VueniverseScope.of(context);
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
          const SectionTitle(title: 'What Vueniverse keeps'),
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
                  ? 'Switch to Snapshot mode to use this source.'
                  : 'Switch to Live mode to review and connect this source.',
            )
          else if (isDemo)
            OutlinedButton.icon(
              onPressed: state.resetDemo,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset Snapshot source'),
            )
          else
            ..._sourceActions(context, state, current),
        ],
      ),
    );
  }

  List<Widget> _sourceActions(
    BuildContext context,
    VueniverseState state,
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
    VueniverseState state,
    SourceData current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${current.name} data?'),
        content: const Text(
          'Saved records from this source will be removed. Results that used this data will be marked out of date. Other sources will not change.',
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
    final state = VueniverseScope.of(context);
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
            'Vueniverse uses the title only on this screen. After saving, it keeps only your category and event times.',
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
    'Heart rate, sleep, steps, activity, and workouts in one consistent format',
    'The source name is stored as a private code',
  ],
  'checkins' => [
    'Only the category, time, and value you enter',
    'Every edit or deletion makes Vueniverse check affected results again',
  ],
  _ => [
    '30-day records in the encrypted Snapshot database only',
    'Resetting Snapshot never changes Live data',
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
    final state = VueniverseScope.of(context);
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
                  title: 'Your results over time',
                  subtitle:
                      'See what changed, what data changed it, and whether an older result is still current.',
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
                          'Mixed',
                          'Weakened',
                          'Expired',
                          'Strengthened',
                          'Inconclusive',
                          'Needs data',
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
                        ? 'Results will appear after there is enough reliable Live data.'
                        : 'Choose another filter to see past results.',
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
                  JourneyCard(
                    onTap: () =>
                        openPulsePage(context, const DemoEvidenceCasesScreen()),
                    child: const JourneySummary(
                      icon: Icons.fact_check_outlined,
                      title: 'Snapshot scenario library',
                      detail:
                          'Explore 5 calculated outcomes plus lifecycle, experiment, and illustrative stories.',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SectionTitle(
                  title: 'Preview',
                  subtitle:
                      'Optional views stay attached to the journey they extend.',
                ),
                const SizedBox(height: 12),
                JourneyCard(
                  onTap: () =>
                      openPulsePage(context, const WeeklyDigestScreen()),
                  child: const JourneySummary(
                    icon: Icons.calendar_view_week_rounded,
                    title: 'Weekly Digest',
                    detail:
                        'Preview a seven-day summary of your data and sources.',
                    trailing: StatusPill(
                      label: 'PREVIEW',
                      color: PulseColors.violet,
                    ),
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
      'Mixed' =>
        'Comparable windows moved in opposing directions, so no repeated pattern was promoted.',
      'Needs data' =>
        'The engine found the event, but exclusions or missing coverage left too little usable evidence.',
      'Weakened' =>
        'The original difference became smaller after illness days were excluded.',
      'Expired' =>
        'The source used for this result was deleted, so the result is no longer current.',
      'Null finding' =>
        'The available comparisons did not show a repeatable difference.',
      'Developing' =>
        'The same direction has appeared more than once, but more similar events are needed before this is a clear pattern.',
      'Strengthened' =>
        'The completed personal test moved the measured result in the expected direction.',
      'Inconclusive' =>
        'Missing or ineligible occurrences left too little complete evidence to resolve the test.',
      _ =>
        'The pattern appeared often enough in good-quality data to stay visible.',
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
                InfoLine(
                  label: 'Analysis / provenance',
                  value: item.analysisLabel,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snapshot scenario library')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '${demoScenarios.length} Snapshot scenarios',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Five cases are recalculated by the recurring-meeting engine. Lifecycle receipts, completed-test stories, and future detectors are labelled separately.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const NoticeBox(
            icon: Icons.verified_outlined,
            text:
                '“Fixture-calculated” means the case was executed against canonical Snapshot v4 records and checked against exact expected metrics. Check-in edits can change current History; reset Snapshot before recording these exact cases. “Illustrative” never appears as current evidence.',
          ),
          const SizedBox(height: 20),
          const SectionTitle(
            title: 'Fixture-calculated',
            subtitle:
                'The same deterministic engine returns supported, null, mixed, developing, and insufficient-data states.',
          ),
          const SizedBox(height: 12),
          for (final evidenceCase in demoScenarios.where(
            (scenario) => scenario.kind == DemoScenarioKind.calculated,
          )) ...[
            _DemoScenarioCard(evidenceCase: evidenceCase),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const SectionTitle(
            title: 'Lifecycle & completed tests',
            subtitle:
                'Seeded receipts show what happens after invalidation or a small personal test.',
          ),
          const SizedBox(height: 12),
          for (final evidenceCase in demoScenarios.where(
            (scenario) =>
                scenario.kind == DemoScenarioKind.lifecycle ||
                scenario.kind == DemoScenarioKind.experiment,
          )) ...[
            _DemoScenarioCard(evidenceCase: evidenceCase),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const SectionTitle(
            title: 'Illustrative next detectors',
            subtitle:
                'Populated records make these future questions possible, but this build does not claim to calculate them.',
          ),
          const SizedBox(height: 12),
          for (final evidenceCase in demoScenarios.where(
            (scenario) => scenario.kind == DemoScenarioKind.illustrative,
          )) ...[
            _DemoScenarioCard(evidenceCase: evidenceCase),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DemoScenarioCard extends StatelessWidget {
  const _DemoScenarioCard({required this.evidenceCase});

  final DemoScenarioData evidenceCase;

  @override
  Widget build(BuildContext context) {
    return JourneyCard(
      onTap: () => openPulsePage(
        context,
        _DemoEvidenceCaseDetailScreen(evidenceCase: evidenceCase),
      ),
      child: JourneySummary(
        icon: evidenceCase.icon,
        title: evidenceCase.title,
        detail: evidenceCase.detail,
        trailing: StatusPill(
          label: evidenceCase.badge,
          color: evidenceCase.color,
        ),
      ),
    );
  }
}

class _DemoEvidenceCaseDetailScreen extends StatelessWidget {
  const _DemoEvidenceCaseDetailScreen({required this.evidenceCase});

  final DemoScenarioData evidenceCase;

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
          const SizedBox(height: 16),
          NoticeBox(
            icon: evidenceCase.usesCalculatedEvidence
                ? Icons.verified_outlined
                : evidenceCase.kind == DemoScenarioKind.illustrative
                ? Icons.visibility_outlined
                : Icons.receipt_long_outlined,
            text: evidenceCase.sourceDisclosure,
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  evidenceCase.reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scenario data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (
                  var index = 0;
                  index < evidenceCase.signals.length;
                  index++
                ) ...[
                  BulletLine(text: evidenceCase.signals[index]),
                  if (index != evidenceCase.signals.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            accent: PulseColors.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to show this in the video',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  evidenceCase.videoGuidance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (evidenceCase.id == 'supported-recurring-pattern') ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  openPulsePage(context, const ExplanationScreen()),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Explain the current result'),
            ),
          ] else if (evidenceCase.id == 'demo-experiment-strengthened' ||
              evidenceCase.id == 'demo-experiment-inconclusive') ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => openPulsePage(
                context,
                ExperimentOutcomeScreen(
                  outcome: evidenceCase.id == 'demo-experiment-strengthened'
                      ? ExperimentOutcome.strengthened
                      : ExperimentOutcome.inconclusive,
                  showSeededMetrics: true,
                ),
              ),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Open sample test result'),
            ),
          ],
        ],
      ),
    );
  }
}

class MomentFingerprintScreen extends StatelessWidget {
  const MomentFingerprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
    final finding = state.finding;
    if (!state.hasDisplayableCurrentFinding || finding == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pattern detail')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [_EvidenceReadinessCard(state: state)],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pattern detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const StatusPill(label: 'SEEN REPEATEDLY', color: PulseColors.lime),
          const SizedBox(height: 16),
          Text(
            'Recurring 1:1',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'In the 30 minutes before this meeting, heart rate was usually higher than at similar times with no meeting.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          MetricStrip(
            metrics: [
              MetricValue(
                label: 'USUAL DIFFERENCE',
                value:
                    '${finding.medianDifferenceBpm >= 0 ? '+' : ''}${finding.medianDifferenceBpm.toStringAsFixed(0)} bpm',
              ),
              MetricValue(
                label: 'SHOWED PATTERN',
                value: '${finding.positiveCount} of ${finding.includedCount}',
              ),
              MetricValue(
                label: 'BACK TO USUAL',
                value:
                    '${finding.recoveryDurationMinutes.toStringAsFixed(0)} min',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            title: 'Heart rate across the meetings',
            subtitle:
                'Each meeting line is shown beside heart rate at similar times with no meeting.',
          ),
          const SizedBox(height: 10),
          if (state.replay case final replay? when replay.isUsable)
            _RepeatedTraceCard(replay: replay)
          else
            const NoticeBox(
              icon: Icons.show_chart_rounded,
              text:
                  'Meeting-by-meeting heart-rate lines are not available for this result. Vueniverse will not insert example data in Live mode.',
            ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Why it is shown'),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                BulletLine(
                  text: '${finding.candidateCount} meetings were checked',
                ),
                SizedBox(height: 10),
                BulletLine(
                  text:
                      '${finding.candidateCount - finding.includedCount} ${finding.candidateCount - finding.includedCount == 1 ? 'was' : 'were'} left out because data was missing or unreliable',
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
            text: 'This is a pattern in the data, not a medical conclusion.',
          ),
          const SizedBox(height: 10),
          NoticeBox(
            icon: Icons.compare_arrows_rounded,
            text:
                '${finding.counterevidenceCount} of ${finding.includedCount} meetings did not show the same pattern.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const EvidenceScreen()),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review the data'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                openPulsePage(context, const AskVueniverseScreen()),
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
    final state = VueniverseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Data behind the pattern')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Review the recurring 1:1 pattern',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start with the numbers. Then check what was compared, what was left out, and which meetings did not match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          JourneyCard(
            onTap: () => openPulsePage(context, const InfluenceEditorScreen()),
            child: JourneySummary(
              icon: Icons.tune_rounded,
              title: 'Review missing context',
              detail:
                  'Add or correct details such as caffeine, exercise, illness, mood, or travel.',
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
                'When you change a detail, Vueniverse saves it and checks the pattern again. The older result stays in History.',
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'NUMBERS BEHIND THIS PATTERN'),
          const SizedBox(height: 10),
          for (final fact in _findingFacts(
            VueniverseScope.of(context).finding,
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
                        const SizedBox(height: 4),
                        Text(
                          fact.source,
                          style: Theme.of(context).textTheme.bodySmall,
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
          const _EvidenceDetailsCard(
            title: 'How were meetings compared?',
            children: [
              BulletLine(
                text:
                    'Your meeting data was compared with your own data at similar times with no meeting',
              ),
              SizedBox(height: 10),
              BulletLine(
                text:
                    'Times with recent exercise, travel, illness, or unreliable heart-rate data were left out',
              ),
              SizedBox(height: 10),
              BulletLine(
                text: 'Every number keeps a link to its source and app version',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EvidenceDetailsCard(
            title: 'Which meetings did not match?',
            children: [
              BulletLine(
                text:
                    '${state.finding?.counterevidenceCount ?? 0} of ${state.finding?.includedCount ?? 0} meetings did not show the same rise',
              ),
              const SizedBox(height: 10),
              BulletLine(
                text:
                    '${state.finding?.unresolvedInfluenceCount ?? 0} meeting ${state.finding?.unresolvedInfluenceCount == 1 ? 'day is' : 'days are'} still missing context such as caffeine or exercise',
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const ExplanationScreen()),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Explain this pattern'),
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
                'Heart-rate chart with ${replay.traces.length} meetings and the usual range at similar times',
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
    final state = VueniverseScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review context')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Check the details used in this pattern',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Open a detail to correct it, or add something that was missing when this pattern was checked.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => openPulsePage(context, const CheckInScreen()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add context'),
          ),
          const SizedBox(height: 18),
          if (state.checkIns.isEmpty)
            const EmptyState(
              icon: Icons.tune_rounded,
              title: 'No context logged',
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
                'Saving or deleting context checks the affected pattern again. If the result changes, the older result stays in History.',
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
      label: 'USUAL HEART-RATE DIFFERENCE',
      value:
          '${current.medianDifferenceBpm >= 0 ? '+' : ''}${current.medianDifferenceBpm.toStringAsFixed(0)} bpm',
      detail: 'Compared with similar times when no meeting happened',
      source:
          'Based on ${current.includedCount} meetings used in the comparison',
      accent: PulseColors.coral,
    ),
    EvidenceFact(
      label: 'MEETINGS SHOWING THE PATTERN',
      value: '${current.positiveCount} of ${current.includedCount}',
      detail: 'Meetings where heart rate moved in the same direction',
      source: '${current.candidateCount} meetings checked in total',
      accent: PulseColors.lime,
    ),
    EvidenceFact(
      label: 'RANGE SEEN IN THE DATA',
      value: range,
      detail: 'Lowest to highest difference among meetings showing the pattern',
      source:
          '${(current.completeness * 100).round()}% of the needed data was available',
      accent: PulseColors.cyan,
    ),
  ];
}

String _plainCitationLabel(String citation) => switch (citation) {
  'finding_state' => 'Pattern status',
  'median_difference_bpm' => 'Usual heart-rate difference',
  'included_count' => 'Meetings compared',
  'candidate_count' => 'Meetings checked',
  'positive_count' => 'Meetings showing the pattern',
  'counterevidence_count' => 'Meetings not matching',
  'completeness' => 'Data available',
  'unresolved_influence_count' ||
  'unresolved_influences' => 'Context still missing',
  'exclusions' => 'Meetings left out',
  'control_count' => 'Similar times compared',
  'recovery_duration_minutes' => 'Time to return to usual range',
  _ => 'Current pattern data',
};

String _plainContributorLabel(String contributor) => switch (contributor) {
  'caffeine_timing' => 'Caffeine timing',
  'recent_exercise' => 'Recent exercise',
  'unusual_stress' => 'Unusual stress or schedule pressure',
  _ => 'Context to record next time',
};

class _EvidenceDetailsCard extends StatelessWidget {
  const _EvidenceDetailsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
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
      if (mounted) VueniverseScope.of(context).loadExplanation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
    final finding = state.finding;
    if (!state.hasDisplayableCurrentFinding || finding == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('MedGemma interpretation')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [_EvidenceReadinessCard(state: state)],
        ),
      );
    }
    final explanation = state.currentExplanation;
    final summaryCitations = explanation == null
        ? const <String>{}
        : <String>{
            for (final paragraph in explanation.paragraphs)
              if (paragraph.text.trim() == explanation.summary.trim())
                ...paragraph.citations,
          };
    return Scaffold(
      appBar: AppBar(title: const Text('MedGemma interpretation')),
      body: explanation == null
          ? _ExplanationLoadingState(state: state)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const StatusPill(
                  label: 'USES ONLY THIS PATTERN’S DATA',
                  color: PulseColors.violet,
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(height: 18),
                Text(
                  'What happened',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  explanation.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (summaryCitations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data used for this answer',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final citation in summaryCitations)
                              Chip(label: Text(_plainCitationLabel(citation))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                for (final paragraph in explanation.paragraphs.where(
                  (paragraph) =>
                      paragraph.text.trim() != explanation.summary.trim(),
                )) ...[
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
                                Chip(
                                  label: Text(_plainCitationLabel(citation)),
                                ),
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
                const SizedBox(height: 20),
                Text(
                  'Possible contributors — not proven causes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This pattern cannot identify a cause. These reviewed context details can separate competing explanations in the next observations.',
                      ),
                      const SizedBox(height: 14),
                      if (explanation.possibleContributorIds.isEmpty)
                        const Text(
                          'No specific contributor was supported strongly enough to highlight from the checked data.',
                        )
                      else
                        for (final contributor
                            in explanation.possibleContributorIds) ...[
                          _ProtocolChecklistItem(
                            icon: Icons.help_outline_rounded,
                            text: _plainContributorLabel(contributor),
                          ),
                          if (contributor !=
                              explanation.possibleContributorIds.last)
                            const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
                if (explanation.nextObservation != null) ...[
                  const SizedBox(height: 20),
                  NoticeBox(
                    icon: Icons.visibility_outlined,
                    text: explanation.nextObservation!,
                  ),
                ],
                const SizedBox(height: 20),
                SurfaceCard(
                  accent: PulseColors.cyan,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusPill(
                        label: 'REVIEWED PERSONAL TEST',
                        color: PulseColors.cyan,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Test this pattern',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use a 10-minute quiet buffer before the next three eligible recurring 1:1 meetings, then compare post-meeting recovery time.',
                      ),
                      const SizedBox(height: 14),
                      const _ProtocolChecklistItem(
                        icon: Icons.timer_outlined,
                        text: 'Begin exactly 10 minutes before the meeting.',
                      ),
                      const SizedBox(height: 10),
                      const _ProtocolChecklistItem(
                        icon: Icons.pause_circle_outline_rounded,
                        text:
                            'Sit in your usual place and pause email and other work.',
                      ),
                      const SizedBox(height: 10),
                      const _ProtocolChecklistItem(
                        icon: Icons.monitor_heart_outlined,
                        text:
                            'Keep the sensor on; Vueniverse measures recovery automatically.',
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => openPulsePage(
                            context,
                            const ExperimentSetupScreen(),
                          ),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Review full 3-meeting plan'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MedGemma explains the bounded hypothesis. Vueniverse calculates the result from stored measurements.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLine(
                        label: 'How this was written',
                        value: explanation.runtimeLabel,
                      ),
                      if (explanation.modelName != null) ...[
                        const Divider(height: 24),
                        InfoLine(
                          label: explanation.deterministicFallback
                              ? 'Backup'
                              : 'Model',
                          value: _plainModelName(explanation.modelName!),
                        ),
                      ],
                      if (!explanation.deterministicFallback &&
                          explanation.latencyMillis != null) ...[
                        const Divider(height: 24),
                        InfoLine(
                          label: 'Inference time',
                          value: _formatInferenceTime(
                            explanation.latencyMillis!,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      InfoLine(
                        label: 'Evidence check',
                        value: explanation.fromCache
                            ? 'Checked earlier on this device'
                            : explanation.deterministicFallback
                            ? 'Checked backup used; no model text shown'
                            : 'Model answer matched the current data',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: state.explanationInProgress
                      ? null
                      : () => state.loadExplanation(refresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Generate a fresh explanation'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      openPulsePage(context, const AskVueniverseScreen()),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Ask about this pattern'),
                ),
              ],
            ),
    );
  }
}

class _ExplanationLoadingState extends StatelessWidget {
  const _ExplanationLoadingState({required this.state});

  final VueniverseState state;

  @override
  Widget build(BuildContext context) {
    if (state.explanationMessage != null) {
      return EmptyState(
        icon: Icons.shield_outlined,
        title: 'No checked explanation available',
        detail: state.explanationMessage!,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        _InferenceActivityCard(progress: state.inferenceProgress),
        const SizedBox(height: 12),
        TextButton(
          onPressed: state.explanationInProgress
              ? state.cancelExplanation
              : null,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _InferenceActivityCard extends StatelessWidget {
  const _InferenceActivityCard({required this.progress});

  final InferenceProgress? progress;

  @override
  Widget build(BuildContext context) {
    final current =
        progress ??
        const InferenceProgress(
          stage: InferenceProgressStage.preparingEvidence,
        );
    final activeStep = switch (current.stage) {
      InferenceProgressStage.preparingEvidence ||
      InferenceProgressStage.checkingCache => 0,
      InferenceProgressStage.selectingRuntime ||
      InferenceProgressStage.runningInference ||
      InferenceProgressStage.usingFallback => 1,
      InferenceProgressStage.validatingOutput => 2,
      InferenceProgressStage.completed => 3,
    };
    return SurfaceCard(
      accent: PulseColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _inferenceProgressTitle(current),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This shows the processing steps, not private model reasoning.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          _InferenceStep(
            label: 'Prepare the current pattern data',
            state: _stepState(0, activeStep),
          ),
          const SizedBox(height: 12),
          _InferenceStep(
            label: _runtimeStepLabel(current.runtime),
            state: _stepState(1, activeStep),
          ),
          const SizedBox(height: 12),
          _InferenceStep(
            label: 'Check every claim against the data',
            state: _stepState(2, activeStep),
          ),
        ],
      ),
    );
  }
}

enum _InferenceStepState { waiting, active, complete }

_InferenceStepState _stepState(int step, int activeStep) => step < activeStep
    ? _InferenceStepState.complete
    : step == activeStep
    ? _InferenceStepState.active
    : _InferenceStepState.waiting;

class _InferenceStep extends StatelessWidget {
  const _InferenceStep({required this.label, required this.state});

  final String label;
  final _InferenceStepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _InferenceStepState.complete => PulseColors.mint,
      _InferenceStepState.active => PulseColors.violet,
      _InferenceStepState.waiting => PulseColors.textTertiary,
    };
    return Row(
      children: [
        Icon(
          state == _InferenceStepState.complete
              ? Icons.check_circle_rounded
              : state == _InferenceStepState.active
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    );
  }
}

String _inferenceProgressTitle(InferenceProgress progress) =>
    switch (progress.stage) {
      InferenceProgressStage.preparingEvidence => 'Preparing the evidence…',
      InferenceProgressStage.checkingCache =>
        'Checking for a current explanation…',
      InferenceProgressStage.selectingRuntime =>
        'Finding an available private model…',
      InferenceProgressStage.runningInference => switch (progress.runtime) {
        InferenceRuntime.phoneMedGemma => 'MedGemma is thinking on this phone…',
        InferenceRuntime.developmentMachine =>
          'MedGemma is thinking on the local runtime…',
        _ => 'Writing a checked explanation…',
      },
      InferenceProgressStage.validatingOutput =>
        'Checking the answer against the evidence…',
      InferenceProgressStage.usingFallback =>
        'Using the checked backup explanation…',
      InferenceProgressStage.completed => 'Explanation ready',
    };

String _runtimeStepLabel(InferenceRuntime? runtime) => switch (runtime) {
  InferenceRuntime.phoneMedGemma => 'Run MedGemma privately on this phone',
  InferenceRuntime.developmentMachine => 'Run the local MedGemma model',
  InferenceRuntime.deterministic => 'Write the checked backup explanation',
  null => 'Run the available MedGemma model',
};

String _plainModelName(String modelName) {
  if (modelName.contains('medgemma-1.5-4b-it')) return 'MedGemma 1.5 4B';
  if (modelName == 'deterministic-fallback' ||
      modelName == 'Checked local explanation rules') {
    return 'Checked local explanation rules';
  }
  return modelName;
}

String _formatInferenceTime(int latencyMillis) {
  if (latencyMillis < 1000) return '$latencyMillis ms';
  return '${(latencyMillis / 1000).toStringAsFixed(1)} seconds';
}

class AskVueniverseScreen extends StatefulWidget {
  const AskVueniverseScreen({super.key});

  @override
  State<AskVueniverseScreen> createState() => _AskVueniverseScreenState();
}

class _AskVueniverseScreenState extends State<AskVueniverseScreen> {
  final controller = TextEditingController();

  static const questions = [
    'Why is this pattern shown?',
    'Which numbers support this result?',
    'What data is missing?',
    'What data was left out?',
    'Which meetings do not match?',
    'How much disagreement is there?',
    'What should I track next?',
    'What could make this result change?',
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
    if (!state.hasDisplayableCurrentFinding) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ask Vueniverse')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [_EvidenceReadinessCard(state: state)],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Vueniverse')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const StatusPill(
                  label: 'THIS PATTERN ONLY',
                  color: PulseColors.violet,
                  icon: Icons.filter_alt_outlined,
                ),
                const SizedBox(height: 14),
                Text(
                  'Ask about the numbers, missing context, or meetings that did not match.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vueniverse does not answer medical diagnosis or treatment questions here.',
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
                if (state.askInProgress) ...[
                  const SizedBox(height: 14),
                  _InferenceActivityCard(progress: state.inferenceProgress),
                ],
              ],
            ),
          ),
          if (state.askInProgress) ...[
            const LinearProgressIndicator(),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                child: TextButton.icon(
                  onPressed: state.cancelExplanation,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Cancel answer'),
                ),
              ),
            ),
          ],
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
                        hintText: 'Ask about this pattern',
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
                'Keep in mind: ${message.uncertainty}',
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
                    Chip(label: Text(_plainCitationLabel(citation))),
                ],
              ),
            ],
            if (!message.fromUser && message.runtimeLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  message.runtimeLabel!,
                  if (message.modelName != null)
                    _plainModelName(message.modelName!),
                  if (message.latencyMillis case final latency?)
                    _formatInferenceTime(latency),
                ].join(' · '),
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
    final state = VueniverseScope.of(context);
    final isDraft =
        state.experimentStatus == ExperimentStatus.draft ||
        state.experimentStatus == ExperimentStatus.invalidated;
    final isEnded =
        state.experimentStatus == ExperimentStatus.cancelled ||
        state.experimentStatus == ExperimentStatus.stopped;
    final eligibleFinding = state.hasDisplayableCurrentFinding;
    final hasExperimentData = eligibleFinding;
    final isGettingStarted = !hasExperimentData;
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('experiments-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList.list(
              children: [
                PageIntro(
                  title: isGettingStarted
                      ? 'Experiments'
                      : 'Test one small change',
                  subtitle: isGettingStarted
                      ? 'A personal test becomes available only after Vueniverse has enough data for a supported result.'
                      : 'Each test stays tied to one pattern and uses the same data checks.',
                ),
                const SizedBox(height: 24),
                if (isGettingStarted)
                  _EvidenceReadinessCard(state: state, forExperiment: true)
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
                  JourneyCard(
                    onTap: () => openPulsePage(
                      context,
                      const ExperimentOutcomeCasesScreen(),
                    ),
                    child: const JourneySummary(
                      icon: Icons.grid_view_rounded,
                      title: 'See every possible result',
                      detail:
                          'Review the four honest outcomes before starting a test.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  JourneyCard(
                    onTap: () =>
                        openPulsePage(context, const WhatIfLabScreen()),
                    child: const JourneySummary(
                      icon: Icons.tune_rounded,
                      title: 'What-if Lab',
                      detail:
                          'Preview a possible change without editing saved data or results.',
                      trailing: StatusPill(
                        label: 'PREVIEW',
                        color: PulseColors.violet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const NoticeBox(
                    icon: Icons.health_and_safety_outlined,
                    text:
                        'These are personal tests, not treatment. Stop if a change feels unsafe or unhelpful.',
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
            'Pause email and other work while staying in your usual place. Record context that could make a meeting hard to compare.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const InfoLine(label: 'Length', value: '3 eligible meetings'),
          const SizedBox(height: 8),
          const InfoLine(label: 'Compare', value: 'Post-meeting recovery time'),
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

class _ProtocolChecklistItem extends StatelessWidget {
  const _ProtocolChecklistItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: PulseColors.cyan),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ProtocolStep extends StatelessWidget {
  const _ProtocolStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: PulseColors.cyan,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: PulseColors.canvas,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ActiveExperimentCard extends StatelessWidget {
  const _ActiveExperimentCard({required this.state});

  final VueniverseState state;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'When a scheduled meeting is due, confirm the quiet buffer and record any caffeine, exercise, illness, travel, or unusual stress.',
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: state.experimentOperationInProgress
                      ? null
                      : () => _showOccurrenceCheckIn(context),
                  child: const Text('Complete occurrence check-in'),
                ),
              ],
            )
          else if (complete)
            const NoticeBox(
              icon: Icons.receipt_long_outlined,
              text:
                  'The protocol is complete, but no result is shown until a deterministic experiment receipt is calculated and saved.',
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

  Future<void> _showOccurrenceCheckIn(BuildContext context) async {
    var bufferCompleted = false;
    var caffeine = false;
    var exercise = false;
    var illnessOrTravel = false;
    var unusualStress = false;
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record this meeting',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Confirm what happened so Vueniverse can decide whether this meeting is comparable.',
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: bufferCompleted,
                    onChanged: (value) =>
                        setSheetState(() => bufferCompleted = value ?? false),
                    title: const Text('I completed the 10-minute quiet buffer'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const Divider(),
                  Text(
                    'Did any of these apply?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: caffeine,
                    onChanged: (value) =>
                        setSheetState(() => caffeine = value ?? false),
                    title: const Text('Caffeine shortly before the meeting'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: exercise,
                    onChanged: (value) =>
                        setSheetState(() => exercise = value ?? false),
                    title: const Text('Recent exercise'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: illnessOrTravel,
                    onChanged: (value) =>
                        setSheetState(() => illnessOrTravel = value ?? false),
                    title: const Text('Illness or travel'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: unusualStress,
                    onChanged: (value) =>
                        setSheetState(() => unusualStress = value ?? false),
                    title: const Text('Unusual stress or schedule pressure'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: !bufferCompleted
                          ? null
                          : () {
                              final contexts = <String>[
                                if (caffeine) 'caffeine',
                                if (exercise) 'recent exercise',
                                if (illnessOrTravel) 'illness or travel',
                                if (unusualStress) 'unusual stress',
                              ];
                              Navigator.pop(
                                sheetContext,
                                contexts.isEmpty
                                    ? 'Quiet buffer completed; no listed context changes.'
                                    : 'Quiet buffer completed; context: ${contexts.join(', ')}.',
                              );
                            },
                      child: const Text('Save occurrence'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (note != null && context.mounted) {
      await state.completeExperimentOccurrence(note: note);
    }
  }
}

class _EndedExperimentCard extends StatelessWidget {
  const _EndedExperimentCard({required this.state});

  final VueniverseState state;

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
    final state = VueniverseScope.of(context);
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
            'Test whether reducing stimulation just before the meeting is followed by faster recovery afterward.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Your 3-meeting plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          const SurfaceCard(
            accent: PulseColors.cyan,
            child: Column(
              children: [
                _ProtocolStep(
                  number: 1,
                  text:
                      'Ten minutes before the scheduled start, sit in your usual place and pause email and other work.',
                ),
                SizedBox(height: 16),
                _ProtocolStep(
                  number: 2,
                  text:
                      'Breathe normally and do not deliberately change caffeine, exercise, or the rest of your routine for this test.',
                ),
                SizedBox(height: 16),
                _ProtocolStep(
                  number: 3,
                  text:
                      'Keep your sensor on through the meeting and recovery period. Vueniverse records heart rate automatically.',
                ),
                SizedBox(height: 16),
                _ProtocolStep(
                  number: 4,
                  text:
                      'Afterward, confirm the buffer and record caffeine, exercise, illness, travel, or unusual stress.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SurfaceCard(
            child: Column(
              children: [
                InfoLine(
                  label: 'Change',
                  value: 'Pause work for 10 minutes before start',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Keep stable',
                  value: 'Meeting, location, and normal routine',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Eligible meeting',
                  value:
                      'Recurring 1:1 with usable heart-rate coverage and a completed context check-in',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Primary measure',
                  value: 'Post-meeting recovery time',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Comparison',
                  value: 'Matched earlier recurring 1:1 meetings',
                ),
                Divider(height: 24),
                InfoLine(label: 'Duration', value: '3 eligible meetings'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is recorded',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 14),
                _ProtocolChecklistItem(
                  icon: Icons.auto_graph_rounded,
                  text:
                      'Automatic: meeting timing, heart rate, sensor coverage, and time to return to the usual range.',
                ),
                SizedBox(height: 12),
                _ProtocolChecklistItem(
                  icon: Icons.edit_note_rounded,
                  text:
                      'You record: whether the buffer was completed and any caffeine, exercise, illness, travel, or unusual stress.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NoticeBox(
            icon: Icons.stop_circle_outlined,
            text:
                'Stop at any time. Missed meetings or meetings with other major changes stay visible and are not forced into the result.',
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

class ExperimentOutcomeCasesScreen extends StatelessWidget {
  const ExperimentOutcomeCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const outcomes = ExperimentOutcome.values;
    return Scaffold(
      appBar: AppBar(title: const Text('Possible test results')),
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
            JourneyCard(
              onTap: () => openPulsePage(
                context,
                ExperimentOutcomeScreen(outcome: outcome),
              ),
              child: JourneySummary(
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
  const ExperimentOutcomeScreen({
    super.key,
    required this.outcome,
    this.showSeededMetrics = false,
  });

  final ExperimentOutcome outcome;
  final bool showSeededMetrics;

  @override
  Widget build(BuildContext context) {
    final inconclusive = outcome == ExperimentOutcome.inconclusive;
    return Scaffold(
      appBar: AppBar(title: Text(_outcomeTitle(outcome))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          StatusPill(
            label: showSeededMetrics
                ? '${_outcomeTitle(outcome).toUpperCase()} · SNAPSHOT'
                : _outcomeTitle(outcome).toUpperCase(),
            color: _outcomeColor(outcome),
          ),
          const SizedBox(height: 18),
          Text(
            showSeededMetrics && outcome == ExperimentOutcome.strengthened
                ? 'Recovery was 9 minutes faster.'
                : _outcomeHeadline(outcome),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            showSeededMetrics && outcome == ExperimentOutcome.strengthened
                ? 'Median recovery moved from 54 to 45 minutes across three eligible meetings. This remains a personal observation, not treatment.'
                : _outcomeDetail(outcome),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: PulseColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (showSeededMetrics && outcome == ExperimentOutcome.strengthened)
            const SurfaceCard(
              child: Column(
                children: [
                  InfoLine(label: 'Eligible meetings', value: '3 of 3'),
                  Divider(height: 24),
                  InfoLine(label: 'Comparison recovery', value: '54 min'),
                  Divider(height: 24),
                  InfoLine(label: 'Observed recovery', value: '45 min'),
                  Divider(height: 24),
                  InfoLine(label: 'Measured change', value: '9 min faster'),
                  Divider(height: 24),
                  InfoLine(label: 'Analysis', value: 'Experiment v1'),
                ],
              ),
            )
          else if (inconclusive)
            const NoticeBox(
              icon: Icons.hourglass_empty_rounded,
              text: 'Not enough complete data for a fair result',
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
    'One planned change was skipped even though the meeting occurred, and another occurrence lacked enough heart-rate coverage. Vueniverse will not force a conclusion.',
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
  VueniverseState? _modelDownloadPollingState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = VueniverseScope.of(context);
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
    final state = VueniverseScope.of(context);
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
                JourneyCard(
                  onTap: () => _showModeSheet(state),
                  child: JourneySummary(
                    icon: state.mode == AppMode.demo
                        ? Icons.science_outlined
                        : Icons.person_outline_rounded,
                    title: 'Change data mode',
                    detail: state.mode == AppMode.demo
                        ? 'Currently using the encrypted Snapshot store'
                        : 'Currently using your encrypted local Live store',
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
                            'How data is locked, separated, and kept private from the AI',
                        onTap: () =>
                            openPulsePage(context, const PrivacyScreen()),
                      ),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.verified_outlined,
                        title: 'Proof & exports',
                        subtitle: 'File details and report download status',
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
                      InformationSettingsRow(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Expansion',
                        subtitle:
                            '${expansionSources.map((source) => source.name).join(' · ')}. Informational only; all are Later.',
                        trailing: const StatusPill(
                          label: 'LATER',
                          color: PulseColors.textTertiary,
                        ),
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
                      const InformationSettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About Vueniverse',
                        subtitle:
                            '0.1.0 · Android-first · evidence before explanation · not diagnosis or treatment',
                      ),
                    ],
                  ),
                ),
                if (state.mode == AppMode.demo) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: state.resetDemo,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset Snapshot'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showModeSheet(VueniverseState state) async {
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
                'Choose which data to use',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Snapshot and Live data stay in separate encrypted stores. Switching never mixes them.',
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
                      title: Text('Snapshot'),
                      subtitle: Text(
                        'A ready health timeline that resets the same way',
                      ),
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
          content: Text(
            'Live cannot start because this app build is missing the AI model download link.',
          ),
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

  final VueniverseState state;

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
        status.retryable &&
        (status.state == ModelDownloadState.failed ||
            status.state == ModelDownloadState.cancelled);
    final canDownload = status.state == ModelDownloadState.requiresConsent;

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

class InformationSettingsRow extends StatelessWidget {
  const InformationSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
    return _SimpleInfoScreen(
      title: 'Privacy',
      headline: 'Encrypted locally, separated by design',
      intro:
          'Vueniverse keeps Live and Snapshot records in separate encrypted stores on this device.',
      sections: [
        const (
          'Encrypted storage',
          'Each mode uses its own SQLCipher database. Its random passphrase is wrapped by a separate key held in Android Keystore.',
        ),
        const (
          'Store separation',
          'Only one store can be open at a time. Switching modes never copies or mixes records.',
        ),
        const (
          'Calendar',
          'Only reviewed category and timing are stored. Titles, people, locations, and descriptions are discarded.',
        ),
        (
          'What the AI sees',
          state.mode == AppMode.demo
              ? 'Only bounded aggregate evidence reaches MedGemma through a loopback service on the local development machine. Raw records, names, and event text are not sent.'
              : 'Only bounded aggregate evidence reaches the on-device model. Raw records, names, attendees, and private event text are not sent.',
        ),
        const (
          'Recovery',
          'If the app cannot unlock your data, it stops and asks before deleting or creating anything.',
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
    final state = VueniverseScope.of(context);
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
              final createdAt = state.mode == AppMode.demo
                  ? state.observeDashboard.asOf
                  : DateTime.now();
              final checkIn = CheckInData(
                id:
                    widget.existing?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                when: widget.existing?.when ?? createdAt,
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
    final state = VueniverseScope.of(context);
    final finding = state.finding;
    if (!state.hasDisplayableCurrentFinding || finding == null) {
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
            _EvidenceReadinessCard(state: state),
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
                ? 'SNAPSHOT RECEIPT'
                : 'LOCAL RECEIPT',
            color: PulseColors.lime,
          ),
          const SizedBox(height: 16),
          Text(
            'Saved record for the recurring 1:1 pattern',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This record shows the result, the numbers behind it, where the data came from, and which app version checked it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              children: [
                InfoLine(label: 'Pattern', value: finding.title),
                Divider(height: 24),
                InfoLine(
                  label: 'Difference',
                  value:
                      '${finding.medianDifferenceBpm >= 0 ? '+' : ''}${finding.medianDifferenceBpm.toStringAsFixed(0)} bpm',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Meetings compared',
                  value: '${finding.includedCount} meetings',
                ),
                Divider(height: 24),
                InfoLine(
                  label: 'Result version',
                  value: finding.evidenceVersion,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: 'FILE FINGERPRINT'),
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
          JourneyCard(
            onTap: () => openPulsePage(context, const PreviewScreen()),
            child: const JourneySummary(
              icon: Icons.description_outlined,
              title: 'Reviewed Clinician Report',
              detail: 'Preview layout using Snapshot data',
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
            label: const Text('Export report + data file'),
          ),
          const SizedBox(height: 10),
          const NoticeBox(
            icon: Icons.schedule_outlined,
            text:
                'The PDF and data export come from this exact result and carry the same fingerprint, so changes can be detected.',
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

class WeeklyDigestScreen extends StatelessWidget {
  const WeeklyDigestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = VueniverseScope.of(context);
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
            'What your data showed this week',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'A compact view of what was observed, what changed, and what still needs context.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          if (!state.hasDisplayableCurrentFinding || finding == null)
            _EvidenceReadinessCard(state: state)
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
                    '${finding.positiveCount} of ${finding.includedCount} meetings we could fairly compare showed the pattern.',
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
    final finding = VueniverseScope.of(context).finding;
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
            'Try an idea without changing saved results',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust a pretend quiet break. The example below was not measured, checked, or saved.',
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;

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
      child: Padding(padding: padding, child: child),
    );
  }
}

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.accent,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Color? accent;

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
      child: Semantics(
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

class JourneySummary extends StatelessWidget {
  const JourneySummary({
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
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
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
