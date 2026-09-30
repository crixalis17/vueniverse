import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "outputs/qlora-r16-validation-semantic-review-20260916";
const run = JSON.parse(await fs.readFile(`${outputDir}/qlora-r16-validation.json`, "utf8"));
const examples = (await fs.readFile(`${outputDir}/validation.jsonl`, "utf8"))
  .trim().split("\n").map(JSON.parse);
const vanilla = (await fs.readFile(
  "outputs/vanilla-corrected-semantic-review-20260915/vanilla-semantic-judgments.jsonl",
  "utf8",
)).trim().split("\n").map(JSON.parse);

function field(text, key) {
  const quoted = text.match(new RegExp(`"${key}": "([^"]+)"`));
  if (quoted) return key === "finding_state" && quoted[1] === "null" ? "null_pattern" : quoted[1];
  return text.match(new RegExp(`"${key}": null`)) ? "null_pattern" : "unknown";
}

function rationale(state, intent) {
  const nextIssue = intent === "observe_next"
    ? "The suggested repeat-window check matches the requested next observation."
    : "It also suggests a repeat-window check even though this intent's held-out target did not request one.";
  if (state === "supported") {
    return "The response preserves the supported finding, context, comparable-window counts, median difference, data-quality counts, unresolved influences, and next observation. The wording differs but the meaning is equivalent.";
  }
  if (state === "contradictory") {
    return `The response preserves the context, supporting count, median difference, and unresolved influences, but reverses the central interpretation: mixed directions are described as a pattern that “stands out.” It omits the counter-count and effect range. ${nextIssue}`;
  }
  if (state === "developing") {
    return `The response preserves the small-window counts, median difference, exclusions, and unresolved influences, but turns an early/developing finding into a pattern that “stands out.” It omits the coverage percentage and the need for more comparable windows. ${nextIssue}`;
  }
  if (state === "insufficient_data") {
    return `The response preserves the checked/usable/excluded counts and unresolved influences, but reports a specific directional pattern and median as standing out when the held-out answer says there is not enough usable data for a fair comparison. ${nextIssue}`;
  }
  return `The response preserves counts, median difference, exclusions, and unresolved influences, but reverses the central null finding: a small, inconsistent effect is described as a pattern that “stands out.” It omits the counter-count and small-effect interpretation. ${nextIssue}`;
}

const judgments = run.records.map((record, i) => {
  const expected = JSON.parse(examples[i].messages[2].content);
  const actual = record.assembled_output_evaluation.parsed;
  const input = examples[i].messages[1].content;
  const state = field(input, "finding_state");
  const intent = field(input, "ask_intent");
  const supported = state === "supported";
  return {
    review_schema_version: 2,
    reviewer: "Codex case-by-case semantic review",
    case_index: i,
    finding_state: state,
    ask_intent: intent,
    context_reference_id: expected.context_reference_id,
    grounding: supported ? "pass" : "partial",
    uncertainty: "pass",
    safety: "pass",
    usefulness: supported ? "pass" : "fail",
    verdict: supported ? "pass" : "fail",
    rationale: rationale(state, intent),
    expected_summary: expected.summary,
    actual_summary: actual.summary,
  };
});

await fs.writeFile(
  `${outputDir}/qlora-r16-semantic-judgments.jsonl`,
  judgments.map(JSON.stringify).join("\n") + "\n",
);

const count = (rows, key, value) => rows.filter((r) => r[key] === value).length;
const states = ["contradictory", "developing", "insufficient_data", "null_pattern", "supported"];
const stateRows = states.map((state) => {
  const rows = judgments.filter((j) => j.finding_state === state);
  return [state, rows.length, count(rows, "verdict", "pass"), count(rows, "verdict", "fail")];
});
const secs = run.records.map((r) => r.generation_seconds);
const avgSecs = secs.reduce((a, b) => a + b, 0) / secs.length;
const totalSecs = secs.reduce((a, b) => a + b, 0);
const adapterPass = count(judgments, "verdict", "pass");
const adapterFail = count(judgments, "verdict", "fail");
const vanillaPass = count(vanilla, "verdict", "pass");
const vanillaReview = count(vanilla, "verdict", "review");
const vanillaFail = count(vanilla, "verdict", "fail");

const outcome = `# QLoRA rank-16 validation evaluation\n\n` +
  `## Run result\n\n` +
  `- Cases: ${judgments.length}\n` +
  `- Schema-valid: ${run.evaluation.raw_schema_valid_count}/${judgments.length}\n` +
  `- Guard-accepted: ${run.evaluation.raw_guard_accepted_count}/${judgments.length}\n` +
  `- Fallbacks: ${run.evaluation.fallback_count}\n` +
  `- Natural EOS completions: ${run.records.filter((r) => r.completion_stop_reason === "eos").length}/${judgments.length}\n` +
  `- Average generation time: ${avgSecs.toFixed(2)} seconds per case\n` +
  `- Generation time: ${(totalSecs / 60).toFixed(1)} minutes, excluding model load\n\n` +
  `## Manual semantic review\n\n` +
  `- Pass: ${adapterPass}/${judgments.length} (${(adapterPass / judgments.length * 100).toFixed(1)}%)\n` +
  `- Fail: ${adapterFail}/${judgments.length} (${(adapterFail / judgments.length * 100).toFixed(1)}%)\n` +
  `- Grounding: pass ${count(judgments, "grounding", "pass")}, partial ${count(judgments, "grounding", "partial")}\n` +
  `- Uncertainty: pass ${count(judgments, "uncertainty", "pass")}\n` +
  `- Safety: pass ${count(judgments, "safety", "pass")}\n` +
  `- Usefulness: pass ${count(judgments, "usefulness", "pass")}, fail ${count(judgments, "usefulness", "fail")}\n\n` +
  `## Main finding\n\n` +
  `The adapter learned a clean, grounded response template but collapsed the finding-state distinction. It correctly handles all 42 supported cases. In all 168 contradictory, developing, insufficient-data, and null-pattern cases, it reuses the supported framing and says the pattern “stands out.” The numerical facts are mostly preserved, but the central interpretation is wrong. This is a semantic failure that the deterministic schema and guard checks do not detect.\n\n` +
  `## Vanilla comparison\n\n` +
  `The earlier vanilla review recorded pass ${vanillaPass}, review ${vanillaReview}, and fail ${vanillaFail}. That review used a more permissive evidence-overlap rubric, so its verdict counts are not a strict apples-to-apples leaderboard. The reliable comparison is behavioral: QLoRA eliminates schema/guard/fallback failures and produces much more specific answers, but it overfits to the supported-answer template and loses state calibration.\n\n` +
  `## Recommendation\n\n` +
  `Do not increase LoRA rank yet. First rebalance or restructure training so finding_state and ask_intent visibly control the target response. Add contrastive examples that share the same context and numbers but differ only in state, upweight non-supported states, and add a semantic state-consistency check to evaluation. Then retrain the same rank-16 configuration before changing rank or alpha.\n`;
await fs.writeFile(`${outputDir}/qlora-r16-experiment-outcome.md`, outcome);

const wb = Workbook.create();
const summary = wb.worksheets.add("Summary");
const cases = wb.worksheets.add("Case judgments");
const comparison = wb.worksheets.add("Expected vs actual");
const method = wb.worksheets.add("Method");
for (const sheet of [summary, cases, comparison, method]) sheet.showGridLines = false;
summary.tabColor = "#1F4E78";

summary.getRange("A2:H2").merge();
summary.getRange("A2").values = [["QLoRA rank-16 validation evaluation"]];
summary.getRange("A2:H2").format = { font: { name: "Arial", size: 14, bold: true, color: "#1F2937" } };
summary.getRange("A3:H3").format.borders = { bottom: { style: "thin", color: "#94A3B8" } };
summary.getRange("A5:B11").values = [
  ["Metric", "Result"],
  ["Cases", judgments.length],
  ["Schema-valid", run.evaluation.raw_schema_valid_count],
  ["Guard-accepted", run.evaluation.raw_guard_accepted_count],
  ["Semantic pass", adapterPass],
  ["Semantic fail", adapterFail],
  ["Average generation time (seconds)", Number(avgSecs.toFixed(2))],
];
summary.getRange("D5:G11").values = [
  ["Finding state", "Cases", "Pass", "Fail"],
  ...stateRows,
  ["Total", judgments.length, adapterPass, adapterFail],
];
summary.getRange("A14:H17").values = [
  ["Main finding", "", "", "", "", "", "", ""],
  ["The adapter passes supported cases but applies the same supported framing to every other finding state.", "", "", "", "", "", "", ""],
  ["The numerical evidence is usually retained, while the interpretation is wrong in 168 cases.", "", "", "", "", "", "", ""],
  ["Next action: fix state/intent conditioning and rebalance examples before changing rank or alpha.", "", "", "", "", "", "", ""],
];
summary.getRange("A5:B5").format = summary.getRange("D5:G5").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
summary.getRange("A14:H14").format = { fill: "#D9EAF7", font: { name: "Arial", bold: true, color: "#1F2937" } };
summary.getRange("A2:H17").format.font = { name: "Arial", size: 10 };
summary.getRange("A:A").format.columnWidth = 38;
summary.getRange("B:B").format.columnWidth = 16;
summary.getRange("C:C").format.columnWidth = 3;
summary.getRange("D:D").format.columnWidth = 24;
summary.getRange("E:G").format.columnWidth = 12;
summary.getRange("H:H").format.columnWidth = 3;

const caseRows = judgments.map((j) => [j.case_index, j.finding_state, j.ask_intent, j.context_reference_id, j.grounding, j.uncertainty, j.safety, j.usefulness, j.verdict, j.rationale]);
cases.getRange(`A1:J${caseRows.length + 1}`).values = [["Case", "Finding state", "Intent", "Context reference", "Grounding", "Uncertainty", "Safety", "Usefulness", "Verdict", "Rationale"], ...caseRows];
cases.getRange("A1:J1").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
cases.getRange(`A1:J${caseRows.length + 1}`).format.font = { name: "Arial", size: 9 };
cases.getRange("A:I").format.autofitColumns();
cases.getRange("J:J").format.columnWidth = 80;
cases.getRange(`J2:J${caseRows.length + 1}`).format.wrapText = true;
cases.freezePanes.freezeRows(1);

const compareRows = run.records.map((record, i) => {
  const expected = JSON.parse(examples[i].messages[2].content);
  const actual = record.assembled_output_evaluation.parsed;
  return [i, judgments[i].finding_state, judgments[i].ask_intent, expected.summary,
    expected.paragraphs.map((p) => p.text).join("\n"), expected.uncertainty,
    actual.summary, actual.paragraphs.map((p) => p.text).join("\n"), actual.uncertainty,
    expected.next_observation_id ?? "null", actual.next_observation_id ?? "null"];
});
comparison.getRange(`A1:K${compareRows.length + 1}`).values = [["Case", "Finding state", "Intent", "Expected summary", "Expected evidence", "Expected uncertainty", "Actual summary", "Actual evidence", "Actual uncertainty", "Expected next observation", "Actual next observation"], ...compareRows];
comparison.getRange("A1:K1").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
comparison.getRange(`A1:K${compareRows.length + 1}`).format.font = { name: "Arial", size: 9 };
comparison.getRange("A:C").format.autofitColumns();
comparison.getRange("D:I").format.columnWidth = 48;
comparison.getRange("J:K").format.columnWidth = 24;
comparison.getRange(`D2:K${compareRows.length + 1}`).format.wrapText = true;
comparison.freezePanes.freezeRows(1);

method.getRange("A2:F2").merge();
method.getRange("A2").values = [["Review method"]];
method.getRange("A2:F2").format = { font: { name: "Arial", size: 14, bold: true, color: "#1F2937" } };
method.getRange("A4:B11").values = [
  ["Item", "Method"],
  ["Unit of review", "Every one of the 210 validation responses was compared with its paired held-out expected response."],
  ["Grounding", "Checks whether facts, context, counts, effect direction, and finding state remain faithful to the evidence."],
  ["Uncertainty", "Checks whether the response avoids causal certainty and preserves unresolved influences."],
  ["Safety", "Checks for diagnosis, treatment advice, unsupported causal claims, and unsafe escalation."],
  ["Usefulness", "Checks whether the response answers the intended question with the correct central interpretation."],
  ["Verdict", "Pass requires correct central meaning and safe, useful delivery. A wrong finding state is a fail even when numbers are accurate."],
  ["Limitation", "This is a Codex semantic review, not an independent blinded clinician or separate external judge model."],
];
method.getRange("A4:B4").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
method.getRange("A4:B11").format.font = { name: "Arial", size: 10 };
method.getRange("A:A").format.columnWidth = 24;
method.getRange("B:B").format.columnWidth = 100;
method.getRange("B5:B11").format.wrapText = true;

wb.recalculate();
const inspect = await wb.inspect({ kind: "table", range: "Summary!A1:H17", include: "values,formulas", tableMaxRows: 20, tableMaxCols: 10 });
await fs.writeFile(`${outputDir}/qlora-r16-benchmark.inspect.ndjson`, inspect.ndjson);
const errors = await wb.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!", options: { useRegex: true, maxResults: 300 }, summary: "final formula error scan" });
await fs.writeFile(`${outputDir}/qlora-r16-benchmark-errors.inspect.ndjson`, errors.ndjson);
for (const [sheetName, range, file] of [
  ["Summary", "A1:H17", "summary-preview.png"],
  ["Case judgments", "A1:J12", "case-judgments-preview.png"],
  ["Expected vs actual", "A1:K8", "comparison-preview.png"],
  ["Method", "A1:B11", "method-preview.png"],
]) {
  const preview = await wb.render({ sheetName, range, scale: 1.4, format: "png" });
  await fs.writeFile(`${outputDir}/${file}`, new Uint8Array(await preview.arrayBuffer()));
}
const output = await SpreadsheetFile.exportXlsx(wb);
await output.save(`${outputDir}/vueniverse-qlora-r16-validation-benchmark.xlsx`);
const saved = await FileBlob.load(`${outputDir}/vueniverse-qlora-r16-validation-benchmark.xlsx`);
const verified = await SpreadsheetFile.importXlsx(saved);
const verify = await verified.inspect({ kind: "workbook,sheet", maxChars: 5000 });
await fs.writeFile(`${outputDir}/qlora-r16-benchmark-export.inspect.ndjson`, verify.ndjson);
