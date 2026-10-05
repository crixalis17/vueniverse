# Local collection history

The collection view accounts for data retained in the currently open encrypted
store. Live and Demo databases remain separate; the projection includes their
store identity and refuses an unidentified database. It makes no health-effect,
causal, statistical-completeness, or wearable API-success claim.

`CollectionHistoryRepository.loadCoverage()` aggregates the retained index joined
to existing canonical rows, grouped by source, canonical kind and signal/interval/
check-in category. Counts reflect **current retained records**, not unique days or
events ever collected. First/last timestamps refer to observed starts, not interval
end times. The indexed timestamp is the last successful local write, not the last
provider upload. Dangling index rows do not count as retained measurements.

`loadReceipts(limit: 30, before: cursor)` merges committed sync-run and deletion
receipts using `(timestamp, kind, ID)` descending keyset pagination. Limits are
1–100. Concurrent new receipts belong at the front of a refreshed view rather than
shifting subsequent pages. Completed receipt IDs must not be reused by writers.
The repository reads aggregate columns and bounded receipt rows, never entire raw
measurement series, journal text, titles, payloads, provider IDs, or error messages.
Known normalization reason codes are allowlisted; unrecognized keys are redacted.

Accepted counts mean normalization accepted records, **including repeats**. Seen
and accepted may use different units if upstream mapping expands provider records.
Legacy sync rows do not persist inserted/updated/duplicate counts. These are
explicitly unavailable; subtracting current coverage from historical accepted
counts would produce false accounting after edits and deletion. Versioned receipt
details expose persisted counters when present, without inferring them. Manual saves
already create sync runs; deletions create audit receipts without retaining deleted
text. Old manual revisions cannot be reconstructed from metadata alone. A failed
transaction with no committed sync row has no durable receipt today.

## Versioned writer metadata

The supported details envelope in `sync_runs.error_details` is:

```json
{"receipt_schema":1,"rejections":{"malformed_time":1},"inserted":4,"changed":1,"duplicates":2,"reportedTimezone":"Asia/Kolkata","requestedLocalDate":"2026-10-03"}
```

Counters must be JSON integers in 0–9,007,199,254,740,991. Negative, floating,
boolean, excessive and absent values remain unknown. Flat legacy rejection maps
remain supported, whereas unknown envelope versions fail closed. Details exceeding
4 KiB are not read into the projection. Timezone metadata accepts UTC/GMT or bounded
IANA-style names under known region prefixes; this is syntax validation, not a
timezone database lookup. Local dates require a real, zero-padded Gregorian date.
Unknown rejection names are replaced by `other_rejection`; arbitrary exception
strings are not exposed. None of these metadata fields grants upload permission.

For Ultrahuman imports, `recordsSeen` describes supported provider observation
count; `recordsAccepted` describes accepted mapped canonical records, including
canonical duplicates but excluding provider observations discarded during mapping.
`duplicates` combines canonical duplicates with mapper observation duplicates.
Do not require `seen = accepted + rejected`: these stages may have different units.

## Remaining limits before claiming complete action accounting

Current writers persist versioned inserted, changed, duplicate and bounded rejection
metadata transactionally with ingestion. Explicit normalization-version and unit
labels, and a durable receipt for every attempted/failed operation, remain future
extensions; a rolled-back transaction leaves no committed import receipt. Never
store tokens, API responses, arbitrary exception messages or journal text in receipts.
Retain metadata for explicit edits/deletes according to the user's chosen retention
and erase it with the store when requested. Old receipts retain unknown counters
rather than backfilled guesses. Whole-store erase removes local history too; it
must not recreate a hidden shadow ledger.

Collection history is separate from pattern analysis and model-training consent.
Later analysis may use retained, permissioned local records, but the history itself
does not authorize exports, upload, causal attribution or retraining.
