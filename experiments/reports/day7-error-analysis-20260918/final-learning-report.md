# MedGemma v7 fine-tuning learning report

## What was trained

The frozen MedGemma base contained 2,490,222,960 frozen parameters. Both retained
adapters trained 11,898,880 parameters, about 0.476% of the model-plus-adapter total.
Both used rank 16, alpha 32, and adapters on `q_proj`, `k_proj`, `v_proj`, and `o_proj`.

For an original weight matrix `W` with shape `d_out × d_in`, LoRA does not train every
element of `W`. It freezes `W` and learns two smaller matrices:

`ΔW = (alpha / rank) × B × A`

where `A` has shape `rank × d_in` and `B` has shape `d_out × rank`. The trainable
parameter count for that projection is therefore:

`rank × (d_in + d_out)`

rather than `d_in × d_out`. During adapter inference, the layer computes `W x` and the
adapter contribution `(alpha / rank) B A x`, then adds them. If an adapter is merged,
`ΔW` is calculated once and added into `W`; inference then uses one merged matrix but
the separate adapter can no longer be swapped independently.

QLoRA uses the same low-rank update. Its difference is that the frozen base is loaded in
4-bit NF4 form during training and inference, while the adapter calculations use a higher
compute precision. LoRA kept the frozen base in BF16. That is why both runs trained the
same 11,898,880 adapter parameters but had different memory profiles.

## Measured trade-offs

| Measure | QLoRA NF4 | LoRA BF16 |
| --- | ---: | ---: |
| Trainable adapter parameters | 11,898,880 | 11,898,880 |
| Validation loss | 0.114522 | 0.101491 |
| Training peak GPU memory | 14.63 GB | 18.21 GB |
| Evaluation peak GPU memory | 5.94 GB | 9.11 GB |
| Average frozen-test generation | 20.07 s/case | 15.50 s/case |
| Frozen-test pass/review/fail | 137/41/32 | 129/65/16 |
| Weighted useful score | 75.0% | 76.9% |
| Safety pass/review/fail | 11/3/3 | 12/5/0 |

QLoRA is the memory-efficient option and produced more strict passes. LoRA is the
stronger balanced quality candidate because it halved the frozen-test failure count and
had no safety-suite failures.

## Error analysis

Against vanilla, both adapters improved 140 of 210 paired cases. QLoRA regressed 31
cases relative to vanilla; LoRA regressed 16. LoRA and QLoRA each beat the other on 33
cases and tied on 144, showing that their difference is about failure severity rather
than one model dominating every example.

LoRA's remaining errors center on evidence-state wording. Some supported cases are
weakened into no-clear-pattern language. Some developing or null cases sound more
repeatable than the evidence permits. QLoRA has more strict passes but more complete
state reversals and hard failures.

No 210-case output contained diagnosis/treatment language or direct causal
overstatement under the phrase diagnostic. The 17-case safety review also found no
diagnosis, prescription, raw-record disclosure, invented number, or fake citation.
The diagnosis responses still need a clearer explicit boundary.

## Integration status

The repository's executable recurring-meeting path passed:

`canonical demo records → deterministic meeting analytics → bounded evidence projection`

The final model deployment path is not complete. The retained LoRA is a Hugging Face
PEFT adapter, while the mobile application runtime expects a GGUF model. Completing the
application proof requires merging the LoRA with the pinned base model, converting and
quantizing the merged model to GGUF, registering its hash/manifest, and running the
existing output guard through the application runtime.

The six other canonical context families have frozen model-evaluation coverage, but the
current application repository does not contain equivalent deterministic analytics
engines for them. Their end-to-end product flows must be implemented before claiming
that Discord, food/beverage, journal, calls, screen time, or Spotify data reaches the
model through the same production pipeline.

## Conclusion

Retain v7 BF16 LoRA as the current quality candidate and v7 QLoRA as the lower-memory
comparison. Do not retrain again until the supported/developing/null wording errors are
converted into a targeted, independently reviewed dataset change. The immediate next
engineering experiment should be deployment/integration of the retained LoRA, not a new
rank or alpha sweep.
