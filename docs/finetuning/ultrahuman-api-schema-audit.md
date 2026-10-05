# Ultrahuman API: initial schema and availability audit

Audit date: 2026-09-12  
Public scope: structural field notes only; owner-specific availability is private.
Raw data location: `tooling/medgemma/outputs/ultrahuman/` (Git-ignored, directory
mode `700`, files mode `600`)

## Access boundary

The experiment uses an Ultrahuman personal API token for the token owner's data only.
The token is held in the ignored `tooling/medgemma/.env` file and is not recorded in
this document, source control, generated datasets, command output, or logs.

The official personal-token endpoint used for this audit was:

```text
GET https://partner.ultrahuman.com/api/v1/partner/daily_metrics?date=YYYY-MM-DD
Authorization: <personal API token>
```

No `email` parameter was sent. Per Ultrahuman's documentation, this returns the token
owner's own data and processes day queries in the user's latest timezone.

## Response structure observed

No health measurement, personal sampling-density statistic, timestamp, timezone
value, account identifier or raw output is included in this current public digest.
It preserves structural notes, not an availability claim for another account.

```text
response
├── status
├── error
└── data
    ├── latest_time_zone
    └── metrics
        └── day key
            └── metric records[]
                ├── type
                └── object
```

Metric category names observed during the structural audit included:

```text
active_minutes, avg_sleep_hrv, hr, hrv, inactive_time, morning_alertness,
movement_index, movements, night_rhr, recovery_index, sleep, sleep_rhr, spo2,
steps, temp, vo2_max, weekly_active_minutes
```

## Relevant shapes for Vueniverse

| Metric category | Observed structural fields | Intended use |
| --- | --- | --- |
| `hr` | `day_start_timestamp`, `last_reading`, `title`, `unit`, `values[]` of `timestamp`, `value` | Primary meeting-window signal |
| `hrv` | `avg`, trend metadata, `values[]` of `timestamp`, `value` | Context/recovery signal; not a substitute for heart rate |
| `night_rhr` | `avg`, trend metadata, `values[]` of `timestamp`, `value` | Nightly baseline/context |
| `sleep` | sleep-stage and sleep-window fields plus heart-rate/HRV/movement graphs | Overnight context, exclusions, and recovery windows |
| `recovery_index` | `day_start_timestamp`, `title`, `value` | Daily contextual summary only |

`hr` and `hrv` have timestamp/value arrays, which makes deterministic before, during,
after, recovery, and matched-control windows feasible. The other daily summaries must
remain contextual evidence and not be treated as minute-level observations.

## Availability and coverage boundary

Owner-specific success counts, sample-density ranges and historical availability
checkpoints are retained in the Git-ignored private audit, not this public digest.
Sampling density can vary. The deterministic analytics layer must therefore
resample or aggregate to fixed windows and reject under-covered windows rather than
assuming each calendar minute has a reading.

Field presence never establishes continuous coverage, minute-level sampling or
account-independent historical access. Coverage is measured from records actually
imported for the chosen provider dates. The current live connector normalizes only
verified heart-rate and supported sleep-stage shapes; these older category notes
do not authorize guessing HRV/steps units or importing other schemas.

## Confirmed limitations

- This public document is a schema digest, not an owner's coverage report.
- The actual timezone value was intentionally not copied into documentation; the
  canonical pipeline must read it locally and normalize timestamps consistently.
- No canonical event source has yet been connected, so event/health overlap is unknown.
- API field presence is not a clinical interpretation of any metric.
- The raw files are for local reference only and must not be uploaded before redaction
  and derived-record generation are implemented.

## Privacy minimization and history

October 4, 2026 publication review preserved the earlier owner-derived audit under
the private Git-ignored Ultrahuman output directory (permissions 600) and minimized
this working-tree copy. This does not erase already published Git history; no history
rewrite or force push was performed. No new owner API request was made.

## Original Day 2 follow-up scope

1. Determine historical Ultrahuman coverage and gaps without exporting raw data.
2. Locate and audit the canonical meeting/calendar source.
3. Normalize both sources to one local timeline and calculate overlap.
4. Define windowing, resampling, completeness, and exclusion rules.
