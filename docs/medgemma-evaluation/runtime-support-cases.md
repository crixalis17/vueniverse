# MedGemma runtime support cases

These versioned fictional fixtures let the application owner test fallback,
cache, export-metadata, and invalidation behavior without starting MedGemma.
They contain no app database content, account identifiers, raw events, or
personal health data.

Each JSON block is a standalone `vueniverse-runtime-support-v1` fixture.

## Unavailable phone model

Expected behavior: select the deterministic fallback. Do not relabel it as
phone-local inference.

```json
{
  "schemaVersion": "vueniverse-runtime-support-v1",
  "caseId": "phone_model_unavailable",
  "requestEvidenceVersion": "fictional-evidence-v1",
  "result": {
    "output": null,
    "metadata": {
      "runtime": "phoneMedGemma",
      "modelName": "google/medgemma-1.5-4b-it-Q4_K_M",
      "promptVersion": 2,
      "outputGuardVersion": 0,
      "latencyMillis": 0,
      "schemaValid": false
    },
    "safety": {
      "accepted": false,
      "failures": ["missing_model"]
    },
    "failure": "missing_model"
  },
  "expectedAction": "deterministic_fallback"
}
```

## Development backend disconnect

Expected behavior: surface a bounded retryable runtime failure and select the
deterministic fallback. Never send the request to a cloud endpoint.

```json
{
  "schemaVersion": "vueniverse-runtime-support-v1",
  "caseId": "development_backend_disconnect",
  "requestEvidenceVersion": "fictional-evidence-v1",
  "serviceError": {
    "schemaVersion": "vueniverse-model-service-error-v1",
    "error": {
      "code": "backend_disconnect",
      "message": "llama-server disconnected during inference",
      "retryable": true
    }
  },
  "expectedAction": "deterministic_fallback"
}
```

## Evidence-version mismatch

Expected behavior: discard the cached explanation before display. The cached
output must not be reused or exported as current evidence.

```json
{
  "schemaVersion": "vueniverse-runtime-support-v1",
  "caseId": "evidence_version_mismatch",
  "requestEvidenceVersion": "fictional-evidence-v2",
  "cachedEvidenceVersion": "fictional-evidence-v1",
  "expectedAction": "invalidate_cached_output"
}
```

## Accepted cached output

Expected behavior: when the evidence version is unchanged, an already accepted
explanation can reopen offline without loading the model. Preserve its original
runtime label and metadata; do not claim that a new inference occurred.

```json
{
  "schemaVersion": "vueniverse-runtime-support-v1",
  "caseId": "accepted_cached_output",
  "requestEvidenceVersion": "fictional-evidence-v1",
  "cachedEvidenceVersion": "fictional-evidence-v1",
  "result": {
    "output": {
      "summary": "The fictional comparison remained evidence bounded.",
      "citedParagraphsJson": "[{\"text\":\"Included observations supported the displayed association.\",\"citations\":[\"included_count\"]}]",
      "uncertainty": "An unresolved influence could change the interpretation.",
      "citedUnresolvedInfluences": ["caffeine_missing_two_days"],
      "approvedNextObservation": "Log caffeine before the next comparable meeting."
    },
    "metadata": {
      "runtime": "phoneMedGemma",
      "modelName": "google/medgemma-1.5-4b-it-Q4_K_M",
      "promptVersion": 2,
      "outputGuardVersion": 1,
      "latencyMillis": 4120,
      "schemaValid": true
    },
    "safety": {
      "accepted": true,
      "failures": []
    },
    "failure": null
  },
  "expectedAction": "reopen_cached_output_without_inference"
}
```

The accepted fixture intentionally records output guard version `1`, indicating
that Person 1's deterministic guard accepted it before caching. Raw MG-09
runtime results report guard version `0` until that application-owned step runs.
