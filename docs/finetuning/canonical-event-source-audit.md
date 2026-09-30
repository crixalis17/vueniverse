# Canonical event source audit

Audit date: 2026-09-12  
Finding: the repository has an Android Calendar integration, not a direct Google Meet
or Google Calendar web API integration.

## Existing boundary

The Android adapter requests `READ_CALENDAR` permission and reads recurring events via
the Android Calendar provider. It is suitable for Google Calendar events that are
synced to the user's Android device, including recurring meetings, but it does not
access Google Meet call content, attendee lists, descriptions, links, phone logs, or
message content.

The adapter operates in two stages:

1. **Local review.** It reads a recurring series' ID, title, recurrence rule, and time
   zone so the user can select and categorize recurring event series.
2. **Privacy-reduced snapshot.** It reads only recurring event instance ID, series ID,
   start time, end time, timezone offset, recurrence information, and cancellation
   status. Cancelled and invalid-duration events are excluded.

Series identities are transformed to an HMAC before they are persisted as selections.
The existing deterministic analysis consumes category, timing, offset, recurrence key,
and provenance—not the meeting title.

```text
Google Calendar / Meet event synced to Android
                │
                ▼
Android Calendar provider ── READ_CALENDAR permission
                │
                ▼
Local series review: title + recurrence + timezone
                │ user selects category
                ▼
HMAC series identity + category + event timing
                │
                ▼
Encrypted on-device canonical store
                │
                ▼
Future local de-identified training export
```

## What is available now

- The repository has working deterministic meeting-window analytics.
- It currently has only fictional calendar fixtures in the source tree.
- No real calendar events or Google Meet data were found in the repository.
- The real-data workflow needs a connected Android phone with the Vueniverse app,
  calendar synchronization enabled, and user-granted `READ_CALENDAR` permission.

## Intended use in this experiment

For training, the canonical record should contain only:

- opaque event and recurrence identifiers;
- approved event category, initially `recurring_one_to_one`;
- start/end timestamps and UTC offset;
- duration and recurrence grouping;
- deterministic inclusion/exclusion flags; and
- provenance hashes.

It must exclude titles, people, email addresses, descriptions, locations, URLs, meeting
links, and phone/call content. The model receives only aggregated evidence derived from
these records.

## Status for the current experiment

The current fine-tuning work is model-only. Android Calendar is deliberately deferred;
all canonical events in the training and evaluation bundles will be synthetic and
explicitly labelled as such. See `model-only-data-policy.md`.

## Future product-integration action

Use the Android Calendar path if the target Google Calendar is already synchronized to
an Android phone. It preserves the repository's existing privacy model and avoids a
new cloud OAuth integration. The first real calendar sync needs the user's on-device
permission and series categorization.
