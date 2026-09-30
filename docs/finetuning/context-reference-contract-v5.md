# Private context-reference contract, v5

Status: complete  
Dataset location: `tooling/medgemma/outputs/finetuning/supervised-dataset-v5/` (ignored, owner-only local files)  
Dataset version: 5  
Evidence version in model messages: `synthetic-context-reference-v1`

## Decision

An explanation needs a durable pointer to the one recurring context it describes. For
example, a product may eventually need to show that a repeated music item or a repeated
contact pattern was the context compared with wearable windows. The language model must
not receive that song title, contact name, provider ID, or raw event history.

Version 5 therefore separates three things:

| Layer | Purpose | Leaves the private ingestion boundary? |
| --- | --- | --- |
| Event occurrence ID | Deduplicate one imported occurrence | No |
| Stable source key | Recognize repetitions of one private item or routine | No |
| `context_reference_id` | Opaque pointer used in evidence, model output, and local UI resolution | Yes, only under the experiment’s existing redacted-data controls |

The reference is pseudonymous, not anonymous. It is still user-linked data and must be
access-controlled, retained minimally, and deleted with the corresponding user data.

## Reference derivation and reuse

The local data layer computes an HMAC over the context family and a source-local stable
key with a per-user secret held in an OS-backed keystore or equivalent secret manager.
The result looks like `ctx_0316ad389488fc71`; it contains no title, number, account ID,
or event timestamp.

The helper is implemented in
[`context_references.py`](/Users/rakesh/Documents/repo/medgemma/tooling/medgemma/src/vueniverse_medgemma/context_references.py). It has three required properties:

- same family, same private key, and same local secret → same reference;
- a different key or secret → different reference; and
- the raw key cannot be recovered from the short reference.

Repeated occurrences never receive a new context reference. A newly imported Spotify
play of the same source-local track key, for instance, appends an occurrence to that
track’s existing private context series. A different track gets another reference. The
same rule applies to all canonical families:

| Family | Private stable source key used locally | Model-safe representation |
| --- | --- | --- |
| Recurring meeting | recurrence key or locally derived recurrence signature | opaque reference + work/personal and timing/duration bands |
| Discord/game | local session or game-routine signature | opaque reference + genre, group-size, and timing bands |
| Spotify | provider track/item key | opaque reference + playback and energy/mood bands |
| Phone call | local contact lookup key | opaque reference + user-approved relationship and duration/time bands |
| Screen time | local routine signature from broad app-category aggregates | opaque reference + aggregate category and duration/time bands |
| Manual journal | user-selected structured tag signature | opaque reference + structured tags only |
| Food/beverage | user-selected structured item/category key | opaque reference + category, timing, quantity, and caffeine/alcohol bands |

No raw source key, title, contact name, phone number, journal prose, app content,
timestamp, or source mapping appears in the model message, generated dataset, or cloud
training artifact.

## Analytics-to-model boundary

The deterministic analytics layer first groups repeated event occurrences by
`context_reference_id`, selects eligible wearable windows, builds matched comparison
windows, calculates its repeatability and data-quality metrics, and determines a finding
state. Only then does it create a bounded `ExplainerRequest`.

```text
private event occurrence → local stable key → context_reference_id
                                ↓
wearable + matched-control analytics → EvidenceBundle
                                ↓
MedGemma explanation + exact context_reference_id → local UI resolver
```

The model-facing EvidenceBundle contains a safe label, the opaque ID, already-computed
counts and metric differences, exclusions, unresolved context, and allowed next
observations. Its required JSON output must echo the one supplied
`context_reference_id`. The UI can resolve that returned ID locally to a user-approved
display label after output validation. MedGemma is never asked to discover the reference
or calculate the comparison.

For a result to be described as a repeated pattern rather than a coincidence, the
analytics layer must set eligibility rules, compare matched control windows, exclude
poor-quality data, inspect inconsistent windows, check the result in a future holdout,
and account for the number of contexts scanned. The explanation must still say that the
context *appeared alongside* a pattern, never that it caused a health change.

## Dataset composition and split integrity

The v5 corpus has six opaque context references for every finding-state and context-family
cell. One reference generates the six question-intent examples for the same supplied
evidence. Within each cell, references are stably ordered before any labels are rendered:
four go to train, one to validation, and one to test.

```text
5 finding states × 7 context families × 6 context references × 6 question intents
= 1,260 rows
```

| Split | Rows | Context references | Rows per family | Rows per finding state |
| --- | ---: | ---: | ---: | ---: |
| Train | 840 | 140 | 120 | 168 |
| Validation | 210 | 35 | 30 | 42 |
| Test | 210 | 35 | 30 | 42 |

The quality report verifies all of the following:

- 210 context references, each used in exactly six intent records;
- zero context-reference overlap across train, validation, and test;
- every assistant output returns exactly the same reference that its evidence supplied;
- zero duplicate prompts, zero duplicate assistant outputs, and zero group overlaps;
- zero raw wearable or canonical-event data; and
- zero model-facing `synthetic` markers. Experiment provenance remains in metadata.

## Reproducibility hashes

| File | SHA-256 |
| --- | --- |
| `train.jsonl` | `8a4e6780aa783ef77792c556b6e822621a51354c3412783e1bc95a414f621145` |
| `validation.jsonl` | `d61b0e5fb55d0e67088eb9968253d61f9924f7ab1d452ea5475dc5e780627e4b` |
| `test.jsonl` | `eb9480293d1c166d85fa15e5edfc1fb99f5232062fe4daa467cc31d89b742ad5` |
| `holdout-manifest.json` | `db4efb41669fb36153465397b300285fb39086e144a479012c38e9a00cfa7579` |
| `dataset-quality.json` | `5e87c8a74f80b207d31feb3c623579db432014aeadee28e869584ab34e7aa497` |

## Scope limit

Version 5 remains a synthetic, model-only learning asset. It validates the contract,
adapter training, output validation, and local reference-resolution design. It does not
connect Spotify, calls, Discord, journals, food logs, or live wearable timelines. Real
integrations require source-specific consent, minimum-scope collection, local redaction,
retention/deletion rules, and deterministic analytics validation before use.
