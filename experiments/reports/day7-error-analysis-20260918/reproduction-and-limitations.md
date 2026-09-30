# Reproduction and limitations

## Frozen identifiers

- Project: `vueniverse-508413`
- VM: `medgemma-qlora-l4-03`
- Zone: `us-east1-b`
- Frozen v7 test SHA-256: `3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b`
- Safety dataset SHA-256: `00657782195bd2dbc897a820a081d30de11fda851ce10852c974540e35a4a869`
- QLoRA adapter SHA-256: `3962a62a6fbaf26c222dd8af658d23aab82e87f2014c5367a77d73d4744e4cc1`
- LoRA adapter SHA-256: `3a6a8cf132f02f11d9207cd0916b626a3e66af1e1b2376915eb1d02aa4a973f9`

## Connect to the retained VM

```sh
gcloud compute ssh medgemma-qlora-l4-03 \
  --project=vueniverse-508413 \
  --zone=us-east1-b \
  --tunnel-through-iap
```

## Inspect retained adapter artifacts

```sh
cd /home/e_rakesh176_gmail_com/medgemma-work
sha256sum \
  reports/20260917-qlora-r16-v7-full-02/adapter/adapter_model.safetensors \
  reports/20260917-lora-r16-v7-r2-full-01/adapter/adapter_model.safetensors
```

## Re-run the 17-case adapter safety comparison

```sh
cd /home/e_rakesh176_gmail_com/medgemma-work
tmux new-session -s medgemma-v7-safety-rerun './run-v7-safety-comparison.sh'
```

This command incurs GPU cost while the VM is running. Use a new report directory before
repeating it so that the retained result is not overwritten.

## Re-run the product integration projection test

From the application repository:

```sh
flutter test test/data/demo_longitudinal_inference_test.dart
```

## Material limitations

- The dataset is a controlled simulation calibrated from one user's wearable ranges. It
  is not clinical training data and is not representative of a patient population.
- The 210-case test set measures adherence to the designed evidence states and intents;
  it does not establish medical accuracy or health benefit.
- The weighted useful score is descriptive and depends on the chosen pass/review/fail
  rubric.
- Semantic judgments were performed by one evaluator and were not independently
  adjudicated.
- The style diagnostic detects repetition but does not prove absence of memorization.
- Only recurring meetings currently have an executable application analytics path.
- The retained PEFT adapters have not been merged, converted to GGUF, or tested inside
  the mobile model runtime.
- Cloud cost reconciliation remains pending, and the VM remains billable until it is
  explicitly stopped.
