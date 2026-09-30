import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/models/caffeine_checkin.dart';

void main() {
  final now = DateTime.utc(2026, 9, 26, 12);
  String? validate({
    double? amount,
    DateTime? start,
    DateTime? end,
    DateTime? reported,
  }) => caffeineCheckinError(
    servings: amount,
    start: start,
    end: end,
    reportedAt: reported ?? now,
    now: now,
  );
  test(
    'unknown stays blank, explicit zero and fractional intake are valid',
    () {
      expect(validate(), isNull);
      expect(validate(amount: 0), isNull);
      expect(
        validate(
          amount: 0.5,
          start: now.subtract(const Duration(hours: 4)),
          end: now,
        ),
        isNull,
      );
    },
  );
  test(
    'negative, nonfinite, incomplete, backwards and future inputs are rejected',
    () {
      for (final amount in [-1.0, double.nan, double.infinity]) {
        expect(validate(amount: amount), isNotNull);
      }
      expect(validate(amount: 0, start: now), isNotNull);
      expect(validate(amount: 0, end: now), isNotNull);
      expect(
        validate(start: now.subtract(const Duration(hours: 4)), end: now),
        isNotNull,
      );
      expect(validate(amount: 0, start: now, end: now), isNotNull);
      expect(
        validate(
          amount: 0,
          start: now,
          end: now.subtract(const Duration(minutes: 1)),
        ),
        isNotNull,
      );
      expect(
        validate(
          amount: 0,
          start: now,
          end: now.add(const Duration(minutes: 1)),
        ),
        isNotNull,
      );
      expect(
        validate(amount: 0, reported: now.add(const Duration(minutes: 1))),
        isNotNull,
      );
    },
  );
}
