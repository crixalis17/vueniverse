import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/model_download_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/whypulse/why_pulse/modeldownload/ModelDownloadApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.whypulse.why_pulse.modeldownload',
    ),
    dartPackageName: 'why_pulse',
  ),
)
enum ModelDownloadState {
  notConfigured,
  requiresConsent,
  queued,
  downloading,
  verifying,
  available,
  failed,
  cancelled,
}

class ModelDownloadStatus {
  ModelDownloadStatus({
    required this.state,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
    required this.retryable,
    this.detail,
  });

  ModelDownloadState state;
  int downloadedBytes;
  int totalBytes;

  /// A percentage in the inclusive range 0 through 100.
  double progress;
  bool retryable;
  String? detail;
}

@HostApi()
abstract class ModelDownloadApi {
  @async
  ModelDownloadStatus inspectDownload();

  @async
  ModelDownloadStatus acceptAndStart();

  @async
  ModelDownloadStatus ensureScheduled();

  @async
  ModelDownloadStatus retryDownload();

  @async
  ModelDownloadStatus cancelDownload();
}
