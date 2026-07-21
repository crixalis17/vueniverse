# MedGemma model delivery

Vueniverse does not bundle MedGemma weights in the APK. During onboarding, the
user must explicitly start the model download and cannot enter Snapshot or Live
until the complete artifact passes its pinned size check. SHA-256 enforcement
is temporarily disabled for the hackathon build. Android
WorkManager downloads to a resumable `.part` file and atomically promotes the
verified artifact into the internal app-private `medgemma-models` directory.
`MedGemmaRuntime(filesDir)` resolves that same final path.

Selected temporary development artifact:

- Base model: `google/medgemma-1.5-4b-it`
- Artifact repository: `unsloth/medgemma-1.5-4b-it-GGUF`
- Artifact revision: `1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30`
- Quantization: `Q4_K_M`
- Filename: `medgemma-1.5-4b-it-Q4_K_M.gguf`
- Size: `2,489,894,976` bytes
- SHA-256: `9f3480a68099ab445cc5224aebfc00f0e3c471cacc4a1b8a36a98631e79e0a63`

This artifact identity is pinned only to unblock local-device development. It
is not by itself a release-hosting decision, and benchmark evidence from the
previous GGUF does not transfer to it; MG-12 must be rerun for this exact hash.

The bare GCS URL supplied for the artifact currently returns HTTP 403 because
the object is private. Never embed a service-account key or durable bearer token
in the mobile app. For the hackathon, the Android client can fetch the current
short-lived signed URL from Firebase Remote Config parameter
`medgemma_download_url`, with optional ISO-8601
`medgemma_download_url_expires_at`. A new published value is picked up without
an APK rebuild; HTTP 401/403 forces one refresh, and URL rotation preserves the
partial file and object ETag. The client only accepts this exact HTTPS GCS
object and does not persist its signed query string in the download sidecar.

Remote Config values are visible to clients and therefore are not secrets. The
production private-delivery design remains an authenticated, app-attested
backend ticket endpoint that grants a short-lived, read-only signed URL for only
this object. If distribution review explicitly permits public access, a
dedicated read-only public bucket is the simpler alternative; the pinned size
and SHA-256 remain mandatory integrity checks either way.

For the complete physical-phone build, install, copy, verification, restart,
and test procedure, use
[`docs/physical-phone-adb-runbook.md`](../physical-phone-adb-runbook.md).

For an attached debug phone, copy the artifact to the package's private files
directory without adding it to source control. Always pass the physical serial
so an attached emulator cannot be selected accidentally:

```sh
adb -s <physical-serial> shell run-as com.vueniverse.vueniverse mkdir -p files/medgemma-models
adb -s <physical-serial> push models/medgemma-1.5-4b-it-Q4_K_M.gguf /data/local/tmp/medgemma-Q4_K_M.gguf
adb -s <physical-serial> shell run-as com.vueniverse.vueniverse cp /data/local/tmp/medgemma-Q4_K_M.gguf files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf
adb -s <physical-serial> shell rm /data/local/tmp/medgemma-Q4_K_M.gguf
```

`ModelArtifactManager` validates the file size and streams its SHA-256 before
native loading. Missing, unreadable, truncated, and checksum-mismatched files
remain bounded unavailable-model states. Release delivery is intentionally
undecided until the physical-phone benchmark passes.
