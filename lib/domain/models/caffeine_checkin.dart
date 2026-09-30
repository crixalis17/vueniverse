String? caffeineCheckinError({
  required double? servings,
  required DateTime? start,
  required DateTime? end,
  required DateTime reportedAt,
  required DateTime now,
}) {
  if (servings != null && (!servings.isFinite || servings < 0)) {
    return 'Enter a finite amount of zero or more servings.';
  }
  if ((start == null) != (end == null)) {
    return 'Choose both the start and end of the period.';
  }
  if (start != null && end != null) {
    if (servings == null) {
      return 'Enter the intake for the covered period, including zero if applicable.';
    }
    if (!start.isBefore(end)) return 'The period must end after it starts.';
    if (end.isAfter(reportedAt) || end.isAfter(now)) {
      return 'Only report a period that has already ended.';
    }
  }
  if (servings != null && reportedAt.isAfter(now)) {
    return 'The report cannot be in the future.';
  }
  return null;
}
