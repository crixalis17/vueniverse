# MedGemma evaluation outputs

Model evaluation uses fictional Vueniverse evidence only. Generated raw output
and machine reports remain under the ignored
`tooling/medgemma/reports/generated/` directory.

The checked-in benchmark contract is implemented by `RuntimeBenchmark`. Print
the complete generated JSON Schema with:

```sh
vueniverse-medgemma runtime-schema
```

Score a recorded run with:

```sh
vueniverse-medgemma runtime-score path/to/runtime-report.json
```

Host and emulator reports are always classified as incomplete for phone-local
approval. Only a physical-phone report with at least ten calls, sufficient warm
latency and schema samples, peak-memory data, and thermal measurements can pass.
The report must also contain a successful cancellation sample and battery level
and temperature observations for the ten measured calls. Battery is recorded
for review; the canonical acceptance policy does not currently define a numeric
battery-drain threshold.
