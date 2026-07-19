# MedGemma model delivery

WhyPulse does not bundle MedGemma weights in the APK. The selected artifact is
installed into the internal app-private `medgemma-models` directory by a local
developer workflow before phone-runtime testing. The staging workflow needs
enough temporary free space for both the source and private copy; delete the
temporary source immediately after the private copy is validated.

Selected temporary development artifact:

- Base model: `google/medgemma-1.5-4b-it`
- Artifact repository: `unsloth/medgemma-1.5-4b-it-GGUF`
- Artifact revision: `1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30`
- Quantization: `Q4_K_M`
- Filename: `medgemma-1.5-4b-it-Q4_K_M.gguf`
- Size: `2,489,894,976` bytes
- SHA-256: `b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd`

This public artifact is pinned only to unblock local-device development. It is
not a release-hosting decision, and benchmark evidence from the previous GGUF
does not transfer to it; MG-12 must be rerun for this exact hash.

For the complete physical-phone build, install, copy, verification, restart,
and test procedure, use
[`docs/physical-phone-adb-runbook.md`](../physical-phone-adb-runbook.md).

For an attached debug phone, copy the artifact to the package's private files
directory without adding it to source control. Always pass the physical serial
so an attached emulator cannot be selected accidentally:

```sh
adb -s <physical-serial> shell run-as com.whypulse.why_pulse mkdir -p files/medgemma-models
adb -s <physical-serial> push models/medgemma-1.5-4b-it-Q4_K_M.gguf /data/local/tmp/medgemma-Q4_K_M.gguf
adb -s <physical-serial> shell run-as com.whypulse.why_pulse cp /data/local/tmp/medgemma-Q4_K_M.gguf files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf
adb -s <physical-serial> shell rm /data/local/tmp/medgemma-Q4_K_M.gguf
```

`ModelArtifactManager` validates the file size and streams its SHA-256 before
native loading. Missing, unreadable, truncated, and checksum-mismatched files
remain bounded unavailable-model states. Release delivery is intentionally
undecided until the physical-phone benchmark passes.
