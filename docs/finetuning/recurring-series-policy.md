# Recurring-series selection — analysis version 5

The analytics unit is one provider-recognized recurring series, not all calendar
events marked one-to-one. Native Calendar uses ORIGINAL_ID for exceptions and
EVENT_ID for the recurring master. Source synchronization passes this series ID
as recurrence_id; normalization HMACs it using the local identity key. Individual
occurrences retain separate canonical IDs. Titles and attendee names do not
determine the group and are not needed by the model.

The current application has one active meeting finding. Among eligible occurrences
in the 30-day window, default selection uses the largest identified cohort, then
the most recent occurrence, then lexical hashed key as a deterministic tie-breaker.
This is a product selection heuristic and does not rank by heart-rate effect or
confidence. It does not evaluate every cohort or establish statistical significance.

The engine and repository evaluate method accept recurrenceKeyHmac to select a
specific cohort. eventIds first limits eligible targets; requests spanning several
identified series must also specify a key or raise ArgumentError. An absent
requested key returns insufficient data. All calendar events still screen candidate
controls, whether or not their series is selected.

Missing/blank keys never join a known series. If no identified group exists,
occurrences receive missing_recurrence_identity exclusions and cannot produce a
repeated finding. Legacy identified Demo records keep their existing groups.
Evidence payloads retain the selected private key so different cohorts have distinct
evidence hashes; no raw source identity is added to the model projection.

## Boundaries

- A series identifies a calendar routine, not a verified person. Different series
  involving the same person remain separate; provider changes can create a new group.
- Stable identity is local to the retained identity key and provider IDs. Recreated
  events or reset keys can break continuity. Future provider namespaces and ID reuse
  require explicit migration policies before new calendar connectors are added.
- Missing identities require source repair, not inferred names or category pooling.
- User-facing multi-series discovery/selection is not implemented by this change.
- Default cohort selection and greedy control allocation can change as records are
  added. Full dependency invalidation remains P1.4; fixed-offset/DST handling remains
  P1.3. Promotion gates are still conservative engineering heuristics.

Regression tests cover separated cohorts, missing identity, explicit mixed selection,
deterministic ranking, other-series control contamination and normalizer stability.
Historical training datasets and benchmark results are unchanged.
