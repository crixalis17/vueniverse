# MedGemma model delivery

WhyPulse does not bundle MedGemma weights in the APK. The selected artifact is
installed into the internal app-private `medgemma-models` directory by a local
developer workflow before phone-runtime testing. The staging workflow needs
enough temporary free space for both the source and private copy; delete the
temporary source immediately after the private copy is validated.

Selected artifact:

- Model: `google/medgemma-1.5-4b-it`
- Revision: `91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b`
- Quantization: `Q4_K_M`
- Filename: `medgemma-1.5-4b-it-Q4_K_M.gguf`
- Size: `2,489,894,144` bytes
- SHA-256: `4828aa086174fa34e570a6f289e9d17385542c21cdbbc7f0071d6d72d5c2774f`

For a debug emulator or attached test phone, discover the package's private
files directory and copy the artifact without adding it to source control:

```sh
adb shell run-as com.whypulse.why_pulse mkdir -p files/medgemma-models
adb push models/medgemma-1.5-4b-it-Q4_K_M.gguf /data/local/tmp/medgemma-Q4_K_M.gguf
adb shell run-as com.whypulse.why_pulse cp /data/local/tmp/medgemma-Q4_K_M.gguf files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf
adb shell rm /data/local/tmp/medgemma-Q4_K_M.gguf
```

`ModelArtifactManager` validates the file size and streams its SHA-256 before
native loading. Missing, unreadable, truncated, and checksum-mismatched files
remain bounded unavailable-model states. Release delivery is intentionally
undecided until the physical-phone benchmark passes.
