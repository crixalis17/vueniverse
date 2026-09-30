# Recorded context screening — analysis version 4

Meeting and candidate control windows use the same exclusion helper. Meeting
windows span 15 minutes before through 60 minutes after the meeting; controls
span their 15-minute measurement interval. The windows differ in duration, not
in the policy used to screen them.

- Recorded workouts exclude overlapping windows and windows starting up to and
  including 30 minutes after workout end. At 31 minutes they no longer exclude.
- Illness, travel and manual exercise check-ins exclude windows intersecting
  that recorded local calendar day. Manual exercise has no reliable duration,
  so this deliberately conservative heuristic does not infer one from prose.
- Local days use the meeting's recorded UTC offset on both sides. Check-ins
  timestamped after the analysis cutoff are ignored. Cross-midnight windows
  are compared against the whole local-day interval, not just their start date.
- Calendar overlap/recovery buffers, coverage checks and the separate caffeine
  policy remain in force. A passed screen means no disqualifying *recorded*
  context was found, not that all confounders are absent.

These are engineering heuristics, not clinically validated physiological recovery
thresholds. Fixed offsets do not provide historical IANA timezone/DST resolution.
Missing illness/travel/exercise logs remain an evidence limitation. Recurring
identity grouping and comprehensive dependency invalidation remain roadmap work.

## Demo regression

Raw fixture records are unchanged. Screening changes control allocation:
the July 9 meeting now uses July 12 (difference +18 bpm); July 15 has no remaining
eligible control. The main case has 7 usable meetings, 11 matched controls,
6 positive differences, 1 counterexample and 5 exclusions. Median remains +11
bpm; positive range is +8–18 bpm and median recovery is 39 minutes. State remains
developing. Subset scenarios calculate their own control allocations; they need
not have the same pairing as the full cohort. Greedy control allocation and
its order sensitivity are not resolved by this change.

No training datasets, model checkpoints or historical experiment benchmarks were
modified. Updated fixture expectations describe the live analytical policy only.
