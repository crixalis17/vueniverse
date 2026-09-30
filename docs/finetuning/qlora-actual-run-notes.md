# QLoRA actual-run learning notes

## What is being trained

The v6 run measured 2,502,121,840 parameters in the combined model view:

- frozen parameters: 2,490,222,960;
- trainable LoRA parameters: 11,898,880;
- trainable share: approximately 0.476%.

The frozen MedGemma weights are still used in every forward pass. They are not updated
and therefore do not need optimizer states or weight gradients. The new low-rank A and B
matrices are attached to `q_proj`, `k_proj`, `v_proj`, and `o_proj`; only those matrices
receive optimizer updates.

For one original projection weight `W` with input width `d_in` and output width `d_out`,
full tuning would train `d_in × d_out` values. LoRA instead trains:

```text
A: rank × d_in
B: d_out × rank
trainable values: rank × (d_in + d_out)
effective projection: W(x) + (alpha / rank) B(A(x))
```

With rank 16 and alpha 32, the adapter contribution is scaled by 2. The multiplication
through frozen `W` still costs inference compute; the saving comes mainly from training
far fewer gradients and optimizer states. QLoRA additionally stores the frozen base in
4-bit NF4 with double quantization while computing adapter operations in BF16.

## Measured mechanics

- smoke losses: `0.934454`, `0.864130`, `0.755785`;
- one-example smoke validation loss: `0.452570`;
- smoke peak CUDA allocation: 14,385,336,320 bytes;
- full-run startup/training allocation observed through `nvidia-smi`: about 17.7 GB;
- adapter target modules: `q_proj`, `k_proj`, `v_proj`, `o_proj`;
- dropout: 0.05;
- training rows/steps: 1,512 / 1,512, one epoch;
- checkpoint interval: 100 steps.

These values establish that optimization and reloading work. They do not establish model
quality. Quality is determined only by frozen validation/test behavior, deterministic
contract checks, case-by-case semantic review, safety regression, and comparison with
the vanilla and v5 runs.

