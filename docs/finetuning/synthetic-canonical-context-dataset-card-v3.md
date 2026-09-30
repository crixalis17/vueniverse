# Synthetic multi-context supervised dataset card, v3

Status: superseded for training by dataset version 4; retained as a provenance record  
Dataset location: `tooling/medgemma/outputs/finetuning/supervised-dataset-v3/` (ignored, owner-only local files)  
Dataset schema: `vueniverse-supervised-explainer-dataset-v1`  
Dataset version: 3

The current training candidate is version 4. It keeps the same synthetic provenance
outside the chat messages while removing every model-facing `synthetic` marker. See
`docs/finetuning/model-facing-provenance-separation-v4.md`.

## Purpose

This synthetic-only dataset broadens the Vueniverse fine-tuning experiment from recurring
meetings to seven privacy-safe canonical context families. MedGemma is trained only to
explain a pre-computed result: it does not calculate wearable statistics, link real
accounts, read raw journal text, or decide why a health metric changed.

## Canonical context taxonomy

| Context family | Synthetic, model-visible category fields | Excluded from the dataset |
| --- | --- | --- |
| Recurring meetings | work/personal category, cadence, duration band, time band | title, people, link, transcript |
| Discord game session | game genre, solo/small-group category, timing, duration band | handle, server, channel, chat, real session history |
| Spotify listening | energy/mood tag, listening context, timing band | track, artist, playlist, account, listening history |
| Phone call | relationship category, timing, duration band | contact name, number, recording, transcript, call identifier |
| Screen time | broad activity mix, timing, aggregate duration band | application content, notification, URL, typed text, device timeline |
| Manual journal | structured workload, stress, social, and restfulness tags | journal prose, name, location, medical free text |
| Food/beverage log | meal/beverage category, timing, caffeine/alcohol flag, portion band | brand, venue, receipt, free-text note, intake history |

Every canonical label begins with `Synthetic`. It is fictional context, not imported
account data or a claim about the owner.

## Narrative contract

The input includes a `canonical_context` metric alongside the already-computed evidence
metrics. An assistant answer can cite that metric.

- **Supported:** the synthetic context can be described as the repeated context that
  *stands out* across comparable windows.
- **Developing:** the pattern is early and needs more comparable windows.
- **Null:** no clear repeated pattern appeared for that context.
- **Contradictory:** comparable windows moved in mixed directions.
- **Insufficient data:** too little usable data exists for a fair comparison.

Even in a supported case, the answer says only that the context stands out in the supplied
comparisons. It does not call the context the reason for a health change. The uncertainty
field names possible unmeasured context and the existing output guard rejects causal,
diagnostic, treatment, and unsupported-number claims.

## Composition and split integrity

The dataset has 630 synthetic recurring-context groups:

```text
5 finding states × 7 context families × 6 question intents × 3 safe context variants
```

Within every finding-state and context-family cell, 18 groups are stable-SHA-256 ordered
before labels are rendered: 12 train, 3 validation, and 3 immutable test. This guarantees
every source family occurs in every split and prevents an event group from crossing
splits.

| Split | Records | Per finding state | Per context family |
| --- | ---: | ---: | ---: |
| Train | 420 | 84 | 60 |
| Validation | 105 | 21 | 15 |
| Test (immutable holdout) | 105 | 21 | 15 |

## Validation and review

All 630 records passed strict JSON-schema, citation, numerical-grounding, approved-ID,
privacy-marker, exact-duplicate, and group-leakage checks. The automated report found zero
duplicate prompts, zero duplicate assistant answers, and zero cross-split groups.

The initial review covered every context-family by finding-state narrative pattern and
representative question-intent variants. It verified the intended distinction between a
strong repeated context, a normal/no-pattern context, a mixed context, and a context with
too little data. Full guard validation still runs over every row.

## Reproducibility hashes

| File | SHA-256 |
| --- | --- |
| `train.jsonl` | `256df2b83f465939fb728b87ad113b2e4a332b969dcb04dfb1cc1d6c29ea5387` |
| `validation.jsonl` | `9a99204d7aa6d07009eada4746383d598c6baf74e21eb8f9c3875b00decea6f8` |
| `test.jsonl` | `871838e9e7a460a31f580498776df546b0668194d1eec0145a39f87ed07c6129` |
| `holdout-manifest.json` | `fe6286fb9bb51b0b9c8c1ca13cbe57f8363db83568c73e3f4d8c1f438068d66c` |
| `dataset-quality.json` | `647652d1b227e29630086474e788c9423cf33260f46ee57bc53a612ec70cc38d` |

## Limitations

- This is a controlled learning asset. It cannot establish real-world health behavior,
  individual effects, or clinical usefulness.
- The dataset is template-authored and relatively small. Fine-tuning may teach structured
  style more than broad reasoning; Day 7 must inspect for repetitive language and
  overconfidence.
- The seven context families are synthetic. Connecting a real provider requires a new
  consent, redaction, retention, and deterministic analytics design before any data use.
- An adapter never replaces the deterministic analytics layer or the existing output
  guard.
