import 'package:why_pulse/platform/generated/notification_api.g.dart';

final class ExperimentReminderScheduler {
  ExperimentReminderScheduler({NotificationApi? api})
    : _api = api ?? NotificationApi();

  final NotificationApi _api;

  Future<bool> requestPermission() async {
    try {
      return await _api.requestPermission();
    } on Object {
      return false;
    }
  }

  Future<void> schedule({
    required String id,
    required DateTime atUtc,
    required String title,
    required String body,
  }) async {
    try {
      await _api.schedule(
        NotificationSchedule(
          id: id,
          atEpochMillis: atUtc.millisecondsSinceEpoch,
          title: title,
          body: body,
        ),
      );
    } on Object {
      // A denied or unavailable notification provider never blocks the experiment.
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _api.cancel(id);
    } on Object {
      // The persisted occurrence remains the source of truth.
    }
  }
}
