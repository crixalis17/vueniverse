import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/notification_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/vueniverse/vueniverse/notifications/NotificationApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.vueniverse.vueniverse.notifications',
    ),
    dartPackageName: 'vueniverse',
  ),
)
class NotificationSchedule {
  NotificationSchedule({
    required this.id,
    required this.atEpochMillis,
    required this.title,
    required this.body,
  });

  String id;
  int atEpochMillis;
  String title;
  String body;
}

@HostApi()
abstract class NotificationApi {
  @async
  bool requestPermission();

  void schedule(NotificationSchedule schedule);

  void cancel(String id);
}
