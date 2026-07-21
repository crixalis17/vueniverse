# Vueniverse full manual integration runbook

This runbook tests the Android product as one connected user journey. Record a
pass only when the expected result is visible in the installed app. Record a
failure when a device, permission, model, or UI state prevents the step; never
convert a skipped step into a pass.

## 1. Test setup

1. Use an Android API 34 ARM64 emulator for the compatibility run.
2. Keep a physical ARM64 phone available for the separate MG-12 run.
3. Configure a stable direct HTTPS URL for the exact Q4 model. Do not commit
   the URL or token. Its required identity is:
   - Artifact: `unsloth/medgemma-1.5-4b-it-GGUF`
   - Revision: `1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30`
   - File: `medgemma-1.5-4b-it-Q4_K_M.gguf`
   - Bytes: `2489894976`
   - SHA-256: `b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd`
   - Before provisioning, record approval that the app's downstream agreement,
     HAI-DEF agreement copy, modified-file notice, required `Notice` text, use
     restrictions, and any regulatory obligations satisfy the current Google
     HAI-DEF distribution terms. A URL without this approval is a blocked test,
     not an acceptance pass.
4. From the repository root, run:

   ```sh
   flutter pub get
   flutter analyze
   flutter test
   flutter build apk --debug
   ```

   For the Live model journey, inject the URL when building or running:

   ```sh
   ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_DOWNLOAD_URL='https://your-host.example/medgemma-1.5-4b-it-Q4_K_M.gguf' \
     flutter run -d emulator-5554
   ```

5. Start the app with `flutter run -d <api-34-emulator-id>`.
6. If an older Demo store is already present, open **Settings → Demo Data →
   Reset deterministic demo**. This imports the current lifecycle fixtures.
7. Create a results sheet with columns: test ID, device, mode, result, evidence,
   failure text, and follow-up owner.

## 2. Journey A — onboarding and store separation

### A1. Demo onboarding

1. Launch from a fresh app state.
2. Tap **See how it works**.
3. Read the product boundary: personal evidence, not diagnosis or treatment.
4. Tap **Explore Demo Data**.
5. Confirm the bottom navigation contains **Today**, **History**,
   **Experiments**, and **Settings**.
6. Confirm the page is labelled **DEMO** and says the snapshot is fictional.
7. Pass only if no Health Connect or Calendar permission prompt appears in Demo.

### A2. Live onboarding

1. Clear the app test state or reinstall the debug build.
2. Tap **See how it works → Continue to Sources**.
3. Confirm the source-preparation page lists **Health Connect**, **Android
   Calendar**, **Manual check-ins**, and **Demo Data**.
4. Confirm Calendar disclosure says titles are used only during review and are
   not stored.
5. Tap **Continue with selected sources**.
6. Confirm the final disclosure says approximately **2.49 GB**, unmetered
   Wi-Fi, offline on-device AI, background transfer, and Android notification.
7. Confirm there is one forward action, **Download model**, with no **Later** or
   **Disable** action.
8. Tap **Download model**. Accept or deny notification permission for the
   current test case.
9. Confirm onboarding completes immediately, **LIVE** is visible, and no
   fictional Demo finding appears while the transfer is pending.
10. Pass only if Live and Demo have visibly different content and switching mode
   does not merge their check-ins, findings, experiments, history, or exports.

### A3. Background model lifecycle

1. Start the Live disclosure while the device is on a metered network. Confirm
   Settings → Data and privacy → **On-device AI model** says queued.
2. Restore unmetered Wi-Fi and confirm progress appears in Settings and the
   Android foreground notification without keeping Vueniverse open.
3. Tap **Cancel**. Confirm the state is Cancelled and the partial is retained.
4. Switch to Demo, then return to Live. Confirm the same mandatory boundary is
   respected and the accepted download resumes.
5. Force-stop Vueniverse during transfer, reopen it, and confirm persisted
   WorkManager progress resumes instead of starting a second unique job.
6. Reboot the emulator and repeat the progress check.
7. Deny notification permission. Confirm the app records the actual denial and
   the foreground work remains visible through Android's system task UI.
8. When the transfer reaches verifying, keep the app open and confirm Settings
   changes to Ready without restarting Vueniverse.
9. Turn off networking and request an explanation. Pass only if the verified
   phone runtime is preferred; before Ready, the deterministic fallback must
   remain available.
10. Repeat with insufficient storage and a corrupt same-length fixture. Confirm
    user-visible failure, one clean integrity retry, and manual **Retry** after
    the second integrity failure.

## 3. Journey B — observe source data

1. Return to Demo and open **Today → View source data**.
2. Confirm **Observe** shows the selected range, source record count, active
   days, and last local snapshot time.
3. For Demo fixture v4, verify **30/30 active days** and **2,990 records**:
   2,800 heart-rate samples, 30 HRV, 30 steps, 30 sleep sessions, 10 workouts,
   30 activity intervals, 30 privacy-safe Calendar events, and 30 manual
   check-ins. Every day must contribute ambient heart rate, HRV, steps, sleep,
   activity, one event, and one check-in.
4. Switch among **Heart rate**, **Sleep**, and **Steps**.
5. Switch between the available date ranges.
6. Confirm each chart changes its label and values without changing the finding.
7. Scroll to **Source mix** and verify health, calendar, and manual record
   contributions.
8. Scroll to **Recently observed** and verify timestamps and activity types.
9. Pull to refresh, then use the toolbar refresh action.
10. Pass if the page remains read-only and refresh never opens source controls.

## 4. Journey C — source controls and privacy

### C1. Demo source

1. Open **Today → Manage sources**.
2. Confirm **Demo Data** is loaded and Live integrations are labelled as
   available only in Live.
3. Open every source row and verify **Why it matters** and **What Vueniverse
   keeps**.
4. Reset Demo and confirm Live mode is unchanged.

### C2. Live Health Connect

1. Switch to Live in **Settings**.
2. Open **Sources → Health Connect → Connect Health Connect**.
3. Test full permission, partial permission, denial, and unavailable-provider
   states when the device supports them.
4. Refresh the source and verify stored record count and last sync.
5. Tap **Pause syncing**; confirm the state becomes Paused.
6. Tap **Resume and refresh**; confirm it returns to a connected state.
7. Test **Disconnect** and verify stored-data wording remains accurate.
8. Reconnect, then test **Delete stored source data**.
9. Confirm the warning says dependent evidence becomes stale and other sources
   remain unchanged.
10. Pass each state separately; a device that lacks Health Connect produces a
    recorded failure or not-applicable device result, not a feature pass.

### C3. Live Calendar

1. Open **Sources → Android Calendar → Review recurring series**.
2. Grant or deny permission and record the resulting UI state.
3. For an allowed run, classify at least one series as **Recurring 1:1**, one as
   **Team meeting**, and leave one excluded.
4. Save the review.
5. Reopen the source and confirm the app shows categories without retaining
   title, attendee, location, description, or organizer fields.
6. Exercise refresh, pause, resume, disconnect, and delete as in C2.

## 5. Journey D — manual context and direct influence correction

1. In Demo, open **Today → Add check-in**.
2. Add one entry for each category: Caffeine, Exercise, Illness, Mood, Travel,
   and Custom.
3. For Custom, try saving without a reviewed category name; confirm it is
   blocked.
4. Save a valid custom entry.
5. Open a recent check-in from Today, change its detail, and save.
6. Open the recurring finding, tap **Challenge the evidence → Review
   influences**.
7. Confirm the same persisted entries appear in the direct evidence editor.
8. Tap an influence, correct its category/detail, and save.
9. Delete a different influence and accept the warning.
10. Confirm each add, correction, and deletion says evidence will be recomputed.
11. Return to Evidence and History. Pass if the current evidence refreshes and a
    prior evidence version remains available when the evidence version changes.

## 6. Journey E — Moment Fingerprint and Replay

1. In Demo Today, tap the supported recurring 1:1 finding.
2. Confirm **Moment Fingerprint** shows difference, repeated count, and recovery.
3. Under **Repeated traces**, confirm multiple included meeting traces are
   overlaid.
4. Confirm the matched no-meeting baseline is visually distinct and the phases
   are **Before**, **During**, and **Recovery**.
5. Confirm the source label says the chart came from deterministic Demo or
   persisted event-window metrics.
6. Use TalkBack and confirm the chart announces the number of included meetings
   and the matched baseline.
7. In Live with no current evidence, confirm the app shows no fingerprint or
   sample trace. Pass only if Demo data is never substituted into Live.

## 7. Journey F — challenge, explain, and Ask Vueniverse

1. From Moment Fingerprint, tap **Challenge the evidence**.
2. Verify pre-event difference, repeatability, recovery, confidence/effect range,
   completeness, candidate count, included count, controls, exclusions, and
   counterevidence are visible.
3. Expand **How were windows compared?** and **What disagrees?**.
4. Verify unresolved or missing caffeine context remains visible.
5. Tap **Explain this evidence**.
6. Confirm every paragraph is bounded to the evidence bundle and citations use
   known evidence IDs.
7. Confirm uncertainty says association is not causation, diagnosis, or
   treatment.
8. Open **Ask about this evidence**.
9. Ask all supported intents: why shown, what is missing, what disagrees, and
   what to observe next.
10. Ask for a diagnosis or treatment. Confirm it is blocked without model prose.
11. Test cancel during generation, runtime unavailable, offline fallback, cached
    accepted output, evidence-version mismatch, and stale/invalidated evidence.
12. Pass only if rejected or stale model text is never displayed or cached as
    trusted evidence.

## 8. Journey G — History and lifecycle truth

1. Reset Demo so the current imported fixture metadata is present.
2. Open **History** in the installed app, not only a widget test.
3. Under **All**, verify rows for Supported, Strengthened, Inconclusive,
   Developing, Null finding, Weakened, and Expired/invalidated states.
4. Use filters for **Supported**, **Developing**, **Null finding**, **Weakened**,
   and **Expired**.
5. Open each row and verify title, status, current/not-current value, and why the
   state changed.
6. Open **Demo scenario library** and inspect the five calculated states:
   Supported, Null finding, Mixed, Developing, and Needs data.
7. Confirm Lifecycle and Demo Test receipts name their seeded source, and that
   every future detector says **ILLUSTRATIVE** and stays out of History.
8. Confirm mixed evidence says promotion stopped and missing data says
   the evidence gate was not reached.
9. Switch to Live. Confirm only real database finding versions appear and Demo
   lifecycle fixtures disappear.

## 9. Journey H — experiment lifecycle and restart recovery

Run the following paths separately. Use **Reset deterministic demo** between
paths when you need a fresh proposal.

### H1. Start, pause, and restore

1. Open **Experiments → Review proposed test**.
2. Verify change, stable factors, duration, primary measure, stop wording, and
   non-treatment consent.
3. Try to start without consent; confirm Start is disabled.
4. Accept consent and tap **Start 3-meeting experiment**.
5. Confirm **ACTIVE** and `0/3 eligible meetings`.
6. Tap **Pause experiment** and confirm **PAUSED**.
7. Force-stop the app and relaunch it.
8. Return to Experiments. Pass only if **PAUSED** and `0/3` are restored from
   the repository.
9. Tap **Resume experiment** and confirm **ACTIVE**.

### H2. Occurrence eligibility and completed receipts

1. Tap **Complete occurrence check-in** once and confirm `1/3`.
2. Tap it again without advancing to the next scheduled meeting. Confirm the
   count stays `1/3` and the app says only a due meeting can be checked in.
3. Force-stop and relaunch. Confirm `1/3` is restored.
4. Confirm a completed protocol does not show a result until a deterministic
   experiment result receipt has been calculated and persisted.
5. Open **Demo scenario library** and inspect the seeded Strengthened and
   Inconclusive receipts. Verify their source disclosure says they are seeded
   completed Demo experiments, not the active protocol's result.
6. Open the possible-outcomes gallery and inspect Strengthened, Weakened,
   Unchanged, and Inconclusive as labelled outcome examples.

### H3. Cancel

1. Start a fresh experiment.
2. Tap **Cancel**.
3. Verify the confirmation says reminders are cancelled while the protocol and
   completed check-ins stay preserved.
4. Confirm **CANCELLED**.
5. Relaunch and verify Cancelled is restored.

### H4. Stop early

1. Start a fresh experiment and record one occurrence.
2. Tap **Stop early**.
3. Verify the confirmation says no result will be forced.
4. Confirm **STOPPED** and `1/3` remain visible.
5. Relaunch and verify Stopped is restored.
6. Tap **Review a new test** and verify a new protocol can begin without deleting
   the stopped record.

## 10. Journey I — contextual previews

1. Open **History → Weekly Digest** and confirm it is marked **PREVIEW**.
2. Confirm there is no separate Preview Lab in Settings; previews belong to the
   user journey they extend.
3. Open **Weekly Digest** from History.
4. In Demo, verify **PREVIEW · SAMPLE DATA**, the current finding, source record
   count, active days, logged influences, and unresolved count.
5. In Live with no current finding, verify an honest empty state replaces sample
   findings.
6. Confirm no notification or automatic weekly delivery is enabled.
7. Open **Experiments → What-if Lab** and move the quiet-buffer slider through
   all positions.
8. Confirm illustrative recovery and difference change.
9. Return to Evidence and History. Pass only if the slider changed neither.
10. Open **Settings → Proof & exports → Reviewed Clinician Report** and confirm
    the sample-data badge, observed measure, repeat count, and limitation.

## 11. Journey J — proof, export, privacy, accessibility, and scope labels

1. Open **Settings → Proof & exports**.
2. Verify finding, difference, comparable count, analysis version, and integrity
   hash match the current evidence version.
3. Export PDF and canonical JSON.
4. Verify both files exist locally, contain the same evidence identity/hash, and
   contain no Demo/Live cross-store data.
5. In Live with no current evidence, confirm export is unavailable instead of
   exporting Demo evidence.
6. Open **Privacy** and verify encryption, local storage, Live/Demo separation,
   minimum calendar fields, and model boundary wording.
7. Enable **Reduced motion** and repeat navigation/state changes; confirm
   transitions become immediate without removing content.
8. In Settings, confirm **Expansion** is passive informational content, every
   future integration is marked **LATER**, and there is no Connect button or
   navigation affordance.
9. Confirm core features are not marked Preview or Later, and Preview features
   never claim to be production automations.

## 12. Journey K — MG-10 emulator checkpoint

1. Start exactly one API 34 ARM64 emulator.
2. Put `adb` on `PATH` and run:

   ```sh
   tooling/medgemma/scripts/run_emulator_checkpoint.sh \
     /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf
   ```

3. The script verifies API level, ABI, byte count, and SHA-256; builds and
   installs the debug APK; copies the model into the app-private directory; and
   runs the real-model JNI instrumentation test with `requireRealModel=true`.
4. Pass only when the real model loads and bounded generation completes without
   an assumption/skip. Missing and corrupt artifact tests must also pass.
5. Record the result as emulator compatibility evidence only, never as MG-12.

## 13. Journey L — MG-12 physical-phone acceptance

1. Connect exactly one authorized physical ARM64 Android phone.
2. Keep the phone unplugged only if your test policy requires battery-drain
   observation; otherwise record charging state alongside the report.
3. Let the phone reach a stable starting thermal state.
4. Run:

   ```sh
   tooling/medgemma/scripts/run_physical_benchmark.sh \
     /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf
   ```

5. The test records cold load, ten calls, warm p50/p95, sampled peak incremental
   RSS, raw schema validity, guard acceptance, cancellation, crash/OOM,
   per-call thermal state, battery level, and battery temperature.
6. Pass phone-local only if the scorer reports `pass`:
   - no crash or OOM;
   - warm p95 at most 8 seconds;
   - peak incremental RSS at most 3.5 GB;
   - raw schema validity at least 95%;
   - no serious or critical thermal state;
   - ten battery/temperature samples; and
   - a successful cancellation sample.
7. Review battery drop separately. The canonical policy currently records
   battery but does not define a numeric drain threshold, so do not invent one.
8. If any acceptance threshold fails, record phone-local as failed and retain
   the Demo-only development runtime. Emulator values cannot replace this run.

## 14. Final release decision

An all-features integration pass requires every applicable core journey above,
plus an unskipped MG-10 run. Phone-local MedGemma additionally requires MG-12.
If MG-12 is not run, report the app features separately as passed and the
phone-local runtime as **blocked/unverified**—never as an all-features pass.
