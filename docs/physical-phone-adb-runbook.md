# Install and test Vueniverse on a physical Android phone

This runbook installs a debug build and the pinned MedGemma GGUF on a USB-connected
physical Android phone. Run every command from the Vueniverse repository root. Do
not omit `-s "$PHONE_SERIAL"`; it prevents ADB from selecting an emulator or a
different attached device.

## 1. Connect and select the phone

Enable **Developer options → USB debugging** on the phone, connect it by USB,
unlock it, and approve the computer's debugging key.

```sh
adb devices -l
```

Choose the authorized entry whose state is `device` and whose serial does not
start with `emulator-`. Set that exact serial for the remaining commands:

```sh
PHONE_SERIAL=dbcf617b
PACKAGE_ID=com.vueniverse.vueniverse
MODEL_FILE=models/medgemma-1.5-4b-it-Q4_K_M.gguf
```

Confirm this is an ARM64 physical phone and check its Android version:

```sh
adb -s "$PHONE_SERIAL" shell getprop ro.product.model
adb -s "$PHONE_SERIAL" shell getprop ro.product.cpu.abi
adb -s "$PHONE_SERIAL" shell getprop ro.build.version.release
adb -s "$PHONE_SERIAL" shell getprop ro.build.version.sdk
```

The ABI must be `arm64-v8a`. Stop if the selected serial starts with
`emulator-`, the state is `unauthorized`, or more than one serial was copied.

## 2. Verify the local model before copying

```sh
ls -lh "$MODEL_FILE"
wc -c "$MODEL_FILE"
shasum -a 256 "$MODEL_FILE"
```

The required identity is:

- Size: `2,489,894,976` bytes
- SHA-256: `b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd`
- Artifact revision: `1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30`

Do not continue with a different size or hash.

## 3. Run the focused pre-install checks

```sh
flutter test test/widget_test.dart

JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  android/gradlew -p android :app:testDebugUnitTest \
  --tests com.vueniverse.vueniverse.modeldownload.ModelDownloadProtocolTest \
  --no-daemon
```

Both commands must pass before installing a new build.

## 4. Build and install a clean ARM64 APK

Build the standalone APK immediately before installation. This avoids installing
an APK that an integration-test run may have overwritten with a test harness.

```sh
flutter build apk --debug --target-platform android-arm64
adb -s "$PHONE_SERIAL" install -r build/app/outputs/flutter-apk/app-debug.apk
```

`-r` updates the app while retaining its existing app-private files. Confirm the
package and debug-only `run-as` access:

```sh
adb -s "$PHONE_SERIAL" shell pm path "$PACKAGE_ID"
adb -s "$PHONE_SERIAL" shell run-as "$PACKAGE_ID" pwd
```

The first command must print a `base.apk` path. The second must print the
Vueniverse data directory. If `run-as` reports `unknown package`, the installation
did not survive or another test uninstalled it.

## 5. Check phone storage

The temporary and final GGUF copies coexist during installation, so keep at
least 5–6 GB free:

```sh
adb -s "$PHONE_SERIAL" shell df -h /data
```

## 6. Copy the model into Vueniverse private storage

Stop Vueniverse while replacing the file, create its private model directory,
stage the GGUF, and copy it under the app UID:

```sh
adb -s "$PHONE_SERIAL" shell am force-stop "$PACKAGE_ID"
adb -s "$PHONE_SERIAL" shell run-as "$PACKAGE_ID" mkdir -p files/medgemma-models
adb -s "$PHONE_SERIAL" push "$MODEL_FILE" /data/local/tmp/medgemma-Q4_K_M.gguf
adb -s "$PHONE_SERIAL" shell run-as "$PACKAGE_ID" cp \
  /data/local/tmp/medgemma-Q4_K_M.gguf \
  files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf
```

The final absolute destination is:

```text
/data/user/0/com.vueniverse.vueniverse/files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf
```

## 7. Verify the private copy

Check the private file's byte count and hash before deleting the temporary copy:

```sh
adb -s "$PHONE_SERIAL" shell run-as "$PACKAGE_ID" ls -l \
  files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf

adb -s "$PHONE_SERIAL" shell run-as "$PACKAGE_ID" sha256sum \
  files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf
```

The output must again show `2489894976` bytes and the expected SHA-256. Only
after both match, delete the exact temporary file:

```sh
adb -s "$PHONE_SERIAL" shell rm /data/local/tmp/medgemma-Q4_K_M.gguf
```

## 8. Restart Vueniverse and let the app validate it

```sh
adb -s "$PHONE_SERIAL" shell am force-stop "$PACKAGE_ID"
adb -s "$PHONE_SERIAL" shell am start -n "$PACKAGE_ID"/.MainActivity
```

In Vueniverse, choose **See how it works → Use my own data**. Entering the Live
setup path makes the app stream and validate the model hash. The model screen
should say **Your on-device model is ready.**

Confirm the native validation marker:

```sh
adb -s "$PHONE_SERIAL" shell run-as "$PACKAGE_ID" cat \
  shared_prefs/medgemma_model_download.xml
```

The marker must contain:

```text
verified_length = 2489894976
verified_revision = 1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30
integrity_failures = 0
```

## 9. Test Live behavior

Complete Live onboarding, prepare a supported finding, and open its
**Explain this pattern** or **Ask Vueniverse** action. Pass the quick check only
when the app remains responsive, uses the on-device model, and keeps its bounded
fallback behavior when a model response is rejected.

For the full physical-device runtime and performance gate, run:

```sh
tooling/medgemma/scripts/run_physical_benchmark.sh "$MODEL_FILE"
```

That is the MG-12 acceptance run, not a substitute for the quick installation
check above. Record its report separately.

## Important cleanup warning

Flutter physical-device integration commands can reinstall and later uninstall
the application as part of test cleanup. An uninstall deletes all app-private
data, including the 2.49 GB model. Do not run a separate `flutter test
integration_test/... -d "$PHONE_SERIAL"` or similar device test while performing
this procedure. If another test uninstalls Vueniverse, wait for it to finish, then
repeat the APK installation and private-copy steps.

Do not fix `INSTALL_FAILED_UPDATE_INCOMPATIBLE` by immediately uninstalling the
app: uninstalling also deletes the private model. Resolve the signing mismatch
first, or expect to repeat the model copy afterward.
