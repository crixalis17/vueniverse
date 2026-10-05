# Ultrahuman personal live connector

Scope: supervised personal Android prototype, Ultrahuman health observations and
manual check-ins only. No Calendar, fictional events, cloud relay, hosted LLM,
or inferred health measurements are required by this connector.

## Access and credential boundary

`UltrahumanClient.fetchDay(localDate: 'YYYY-MM-DD', token: sessionToken)` uses the
[official personal-token endpoint](https://vision.ultrahuman.com/developer-docs):
`GET https://partner.ultrahuman.com/api/v1/partner/daily_metrics?date=YYYY-MM-DD`.
Authorization is the token as documented, without an added Bearer prefix. No
email or other person's account selector is sent. Personal tokens are intended
for personal/developer use; a multi-user release needs the separately documented
[OAuth authorization flow](https://vision.ultrahuman.com/developer-docs?type=oauth).

The client does not store tokens, log requests/responses, or cache raw health
payloads. The UI clears the credential text controller immediately on a valid
submission and on disposal. Only the active foreground call retains the token;
an invalid date is corrected locally before submission. Credentials must not be
put in analytics, preferences or crash reports. The app does not record clipboard
history, but cannot control the keyboard/operating system clipboard.
Session-only strings cannot
promise cryptographic memory erasure in Dart; reconnecting requires re-entry.
If persistent credentials become necessary, use a reviewed Android Keystore
credential design rather than plaintext preferences or the app database.
This personal prototype assumes one token owner's account per Live store. The
source stores an HMAC-SHA256 credential binding using the local source-identity
key, **not** the token itself. Binding and the first canonical day commit in one
transaction; failed authentication does not establish a binding. Concurrent
imports on the same database are refused, and each commit rechecks the binding.
A different key is refused while the source history remains, including a rotated
key for the same owner: the personal endpoint does not provide verified account
identity, so a credential binding is not an account-authentication guarantee.

To change keys, use the explicit source-data deletion flow, which removes that
source's records and clears its credential binding, then reconnect. This is a
destructive reset, not a way to retain or merge accounts. A non-destructive
same-owner key migration or separate-owner store requires a future verified
account-identity flow. Never share another person's token with this Live store.

Pause/disconnect/delete increments the collection generation. Each day checks
that generation inside its transaction, preventing an outstanding request from
repopulating a revoked source. Earlier successfully committed days remain after
a later request failure; they are not silently rolled back. No background token
refresh or scheduled personal-token import is implemented.

Default request bounds: 30 seconds, 8 MiB decoded response per day. Redirects are
disabled to prevent credential forwarding. Both declared and streamed body size
are checked. The HTTP client is closed on completion/deadline. No automatic
retry occurs: authorization/rate limit/failure is visible as a safe error code;
the caller can allow an explicit retry. The app must have Internet permission.
The network request contacts Ultrahuman only; the canonical store/model remains
on-device.

## Requested provider dates

The import form explicitly asks for **Last provider date (YYYY-MM-DD)** and a
period of 1, 7 or 14 provider days, ending on that date. The initial date is only
a suggestion from the phone. Confirm or change it to match Ultrahuman when the
phone and provider show different dates. These are requested daily API dates,
not timestamps converted from the phone timezone or proof of historical travel.

The selected date travels through the UI/state callback into
`UltrahumanImportService.importRecentDays(token: token, days: days, endDate: date)`.
Calendar validity, the entire supported range (2000–2100) and an upper bound of
the next UTC calendar day are checked before any request. The upper bound allows
a provider zone ahead of UTC; it does not assert that the provider already has
data for that day. Source metadata retains requested start/end dates, number of
days and `explicit_provider_daily_dates`; every successful day receipt retains
its requested date and reported timezone.

Older non-UI callers that omit `endDate` still use the device date, explicitly
labeled `device_date_default_provider_timezone_unconfirmed`. They do not discover
or infer “today” in the provider's timezone. The user-facing form always submits
an explicit end date. Each received response uses a fresh observation/import
clock so current-day measurements arriving during an import are not compared
against the earlier session-start time.

## Mapping contract

`UltrahumanRecordMapper(offsetResolver: resolver).mapDay(day, observedAt: fetchedAt)`
returns canonical source envelopes, rejection counts and deliberately skipped
metric categories. Import the envelopes through `CanonicalRecordRepository`,
not directly into database tables. `SourceKind.ultrahuman` is retained in
provenance; source IDs are HMAC-normalized by the existing normalizer.

| API observation | Canonical representation | Policy |
| --- | --- | --- |
| `hr.object.values[].timestamp/value`, unit `BPM` | `heart_rate`, bpm | Actual UNIX-second instant only; no resampling/imputation here |
| `sleep.object.sleep_graph.data[].start/end/type` | Exact sleep-stage interval | awake/deep_sleep/light_sleep/rem_sleep mapped to awake/deep/light/rem |
| `hrv` | Not imported yet | Existing personal payload lacks an explicit unit/algorithm contract; do not assert rMSSD |
| `steps` | Not imported yet | Floating graph series and daily totals need verified bucket/cumulative semantics; do not manufacture integer counts |
| Other scores/trends | Not imported | Summaries are not minute observations |

Only structural field shapes and non-personal unit/stage labels from the ignored
September API schema probes were used to develop this mapper. No new personal
request was made during implementation. Private values were not copied into
source, documentation, test fixtures or datasets. Tests use fabricated protocol
fixtures, not the user's measurements.

Stable HR identity is source plus observation epoch; sleep identity is source
plus segment start epoch. A corrected value/end retains identity for repository
upsert. Identical duplicate observations collapse; conflicting same-identity
observations within a response are rejected, not averaged or first/last-wins.
Duplicate metric objects and overlapping sleep-stage intervals fail closed.
Bedtime endpoints are **not** substituted for measured sleep. Unknown stage,
future/invalid timestamp, nonfinite/impossible HR and missing arrays are rejected.
Rejected observations differ from unsupported metric categories, so unsupported
HRV/steps do not inflate malformed-HR counts.

## Receipt counters and provenance

`UltrahumanMappingResult` separates actual supported raw observations from
diagnostic events:

- `inputObservationCount`: entries in HR arrays and supported sleep-graph arrays.
- `duplicateObservationCount`: identical valid rows collapsed within a response.
- `rejectedObservationCount`: all unusable raw rows, including every member of a
  conflicting group and duplicates belonging to overlapping sleep segments.
- `rejectedCounts`: diagnostic tallies, including metric-level failures. Do not
  sum these to reconstruct a raw-row denominator.
- `skippedMetricTypes`: unsupported metric categories, excluded from the above
  supported-observation denominator.

At the mapper boundary, input rows equal mapped envelopes plus duplicate rows
plus rejected rows. A wrong-unit metric containing 100 readings therefore has
100 seen/rejected rows, not one. A conflicting group of four same-instant HR
readings rejects all four, regardless of order. Missing-array metadata generates
a diagnostic but does not fabricate an unseen observation.

Successful persisted receipts store supported raw rows seen; accepted unique
normalized envelopes; raw/normalization rejection counts; and separate inserted,
changed and duplicate counts. Duplicate details combine within-response collapsed
rows with canonical records already present from earlier imports. Accepted rows
can therefore include previously retained records: **do not add accepted and
duplicate counts as disjoint categories**. For a successful import, seen rows
equal inserted plus changed plus duplicate plus rejected rows. The retained-store
count is separate and does not increase simply because data was imported twice.
Receipts contain safe diagnostics, dates/timezone and counts, not health values,
journal text, raw response bodies or credentials. Receipt counts are not evidence
of continuous wearable coverage or an event/health association.

## Timezone and travel limitation

The caller must resolve `latest_time_zone` using an IANA timezone database at
each UTC observation. Never use the phone's current zone as a substitute. A
`timezone` package implementation can return
`TZDateTime.from(utc, getLocation(zone)).timeZoneOffset.inMinutes`; unresolved
zones return null and reject the affected observations. HR must land within the
requested local day. Sleep can cross midnight but must overlap that local day.
Segments spanning an offset transition are rejected because canonical sleep
currently carries only one offset.

**Important:** the API exposes the user's *latest* timezone, not a guaranteed
historical zone at every measurement. IANA resolution handles DST within that
reported zone but cannot reconstruct travel history. Imported offsets therefore
mean “reported API-zone offset”, not proof of historical location. The service
retains the reported timezone in source metadata and each successful receipt;
the import form surfaces the travel/timezone limitation. Do not make local-time
causal claims across travel until resolved. Nothing here
establishes an association with a manual check-in: those require downstream
coverage, repeated-event and uncertainty rules.

## Verification and scope limits

Focused unit tests cover endpoint/query/authentication, safe failures, timeout,
size/date bounds, explicit requested-date ranges and UI propagation, canonical
provenance, malformed/future/out-of-day data,
duplicate conflicts, omitted HRV/steps, exact sleep boundaries, overlap and
offset transitions, raw accounting, same-store concurrency, credential binding,
and revocation during an outstanding request. Tests use an injectable transport
and require no token or
network. Actual Android TLS/network import, timezone UX, credential lifetime,
deletion, and resumed imports must still be verified on the physical phone.
Import success is not a clinically validated measurement or an independent
real-user benchmark. Preserve live data separately from synthetic experiments.
