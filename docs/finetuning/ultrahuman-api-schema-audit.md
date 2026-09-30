# Ultrahuman API: initial schema and availability audit

Audit date: 2026-09-12  
Scope: one schema probe and the most recent seven local days  
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

The API returned HTTP 200 for every requested day. No health measurement, timestamp,
timezone value, account identifier, or raw output is included here.

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

Each day returned 17 metric records. The present metric categories were:

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

## Initial seven-day availability result

The API returned successful payloads for 7/7 requested days, with all 17 metric
categories present each day.

| Series | Days present | Samples/day, minimum–maximum | Mean samples/day |
| --- | ---: | ---: | ---: |
| Heart rate (`hr`) | 7 | 175–2,852 | 583.3 |
| HRV (`hrv`) | 7 | 175–1,555 | 397.7 |
| Night resting heart rate (`night_rhr`) | 7 | 1–7 | 4.0 |
| SpO2 (`spo2`) | 7 | 175–1,557 | 406.3 |
| Steps (`steps`) | 7 | 175–1,557 | 406.3 |
| Temperature (`temp`) | 7 | 175–1,557 | 406.3 |

Sampling density varies substantially. The deterministic analytics layer must therefore
resample or aggregate to fixed windows and reject under-covered windows rather than
assuming each calendar minute has a reading.

## Historical availability checkpoints

Read-only checkpoints at 30, 90, 180, and 365 days before the audit date each returned
HTTP 200 and all 17 metric categories. This establishes that data is available at least
one year back. It does not establish uninterrupted coverage: that will be measured only
after the calendar source identifies the period relevant to recurring meeting events.

## Confirmed limitations

- This is a seven-day availability check, not a historical-coverage audit.
- The actual timezone value was intentionally not copied into documentation; the
  canonical pipeline must read it locally and normalize timestamps consistently.
- No canonical event source has yet been connected, so event/health overlap is unknown.
- API field presence is not a clinical interpretation of any metric.
- The raw files are for local reference only and must not be uploaded before redaction
  and derived-record generation are implemented.

## Next Day 2 work

1. Determine historical Ultrahuman coverage and gaps without exporting raw data.
2. Locate and audit the canonical meeting/calendar source.
3. Normalize both sources to one local timeline and calculate overlap.
4. Define windowing, resampling, completeness, and exclusion rules.
