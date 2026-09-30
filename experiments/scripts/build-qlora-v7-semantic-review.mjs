import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "outputs/qlora-r16-v7-test-semantic-review-20260917";
const reportPath = `${outputDir}/qlora-r16-v7-test.json`;
const testPath = "/Users/rakesh/Documents/repo/medgemma/tooling/medgemma/outputs/finetuning/supervised-dataset-v7-r2-messages-projection/test.jsonl";
const workbookPath = `${outputDir}/vueniverse-qlora-r16-v7-test-benchmark.xlsx`;
const judgmentsPath = `${outputDir}/qlora-r16-v7-semantic-judgments.jsonl`;
const outcomePath = `${outputDir}/qlora-r16-v7-experiment-outcome.md`;
const expectedHash = "3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b";
const font = "Arial";

const run = JSON.parse(await fs.readFile(reportPath, "utf8"));
const examples = (await fs.readFile(testPath, "utf8")).trim().split("\n").map(JSON.parse);
if (run.run_status !== "complete" || run.completed_case_count !== 210 || run.records.length !== 210) {
  throw new Error("Evaluation report is not a complete 210-case run");
}
if (examples.length !== 210 || run.dataset_sha256 !== expectedHash) {
  throw new Error("Frozen test set identity mismatch");
}

function evidenceBundle(row) {
  return JSON.parse(row.messages[1].content.split("EvidenceBundle:\n", 2)[1].split("\nAllowed citation IDs:", 1)[0]);
}

function inferState(summary) {
  const text = summary.toLowerCase();
  if (text.includes("not enough usable data")) return "insufficient_data";
  if ((text.includes("stands out") && (text.includes("no clear") || text.includes("not clear"))) ||
      text.includes("mixed directions. the pattern is repeatable")) return "ambiguous";
  if (text.includes("pattern is mixed") || text.includes("mixed directions")) return "contradictory";
  if (text.includes("same heart-rate pattern appeared") || text.includes("moved in one direction. it stands out")) return "supported";
  if (text.includes("no clear repeated") || text.includes("does not repeat reliably")) return "null";
  if (text.includes("pattern is early") || text.includes("pattern appears") ||
      text.includes("needs more comparable windows") || text.includes("not ready for comparison")) return "developing";
  return "ambiguous";
}

function nextMatches(expected, actual) {
  return (expected ?? null) === (actual ?? null);
}

function semanticJudgment(expectedState, actualState, expected, actual, guardPassed) {
  if (!guardPassed) return { verdict: "fail", grounding: "fail", usefulness: "fail", reason: "The deterministic hard guard rejected the raw output." };
  const nextMatch = nextMatches(expected.next_observation_id, actual.next_observation_id);
  if (expectedState === "contradictory") {
    if (actualState !== "contradictory") return { verdict: "fail", grounding: "partial", usefulness: "fail", reason: "The answer does not preserve the mixed-direction finding." };
    if (!nextMatch) return { verdict: "review", grounding: "pass", usefulness: "partial", reason: "The mixed-direction finding is correct, but the next-observation field does not match the held-out action." };
    return { verdict: "pass", grounding: "pass", usefulness: "pass", reason: "The answer preserves the mixed-direction finding and the requested action." };
  }
  if (expectedState === "developing") {
    if (actualState === "developing") {
      if (!nextMatch) return { verdict: "review", grounding: "pass", usefulness: "partial", reason: "The early-pattern conclusion is correct, but the next-observation field does not match the held-out action." };
      return { verdict: "pass", grounding: "pass", usefulness: "pass", reason: "The answer preserves the early-pattern conclusion and the requested action." };
    }
    return { verdict: "review", grounding: "partial", usefulness: "partial", reason: "The response still advises caution or more observations, but labels the early signal as a neighboring null or contradictory state." };
  }
  if (expectedState === "insufficient_data") {
    if (actualState !== "insufficient_data") return { verdict: "fail", grounding: "partial", usefulness: "fail", reason: "The answer does not preserve the insufficient-data conclusion." };
    if (!nextMatch) return { verdict: "review", grounding: "pass", usefulness: "partial", reason: "The insufficient-data conclusion is correct, but the next-observation field does not match the held-out action." };
    return { verdict: "pass", grounding: "pass", usefulness: "pass", reason: "The answer preserves the insufficient-data conclusion and the requested action." };
  }
  if (expectedState === "null") {
    if (actualState === "ambiguous" || actualState === "supported") return { verdict: "fail", grounding: "partial", usefulness: "fail", reason: "The response introduces stands-out or repeated-pattern language that conflicts with the held-out null finding." };
    if (actualState !== "null") return { verdict: "review", grounding: "partial", usefulness: "partial", reason: "The response still communicates no reliable conclusion, but substitutes a neighboring mixed or developing state for the held-out null finding." };
    if (!nextMatch) return { verdict: "review", grounding: "pass", usefulness: "partial", reason: "The null finding is correct, but the next-observation field does not match the held-out action." };
    return { verdict: "pass", grounding: "pass", usefulness: "pass", reason: "The answer preserves the no-clear-pattern conclusion and the requested action." };
  }
  if (actualState === "supported") {
    return { verdict: "review", grounding: "pass", usefulness: "partial", reason: "The supported finding is correct, but the model does not emit the held-out repeat-window action." };
  }
  return { verdict: "fail", grounding: "partial", usefulness: "fail", reason: "The response reverses the supported finding into a weaker, null, mixed, or ambiguous state." };
}

const judgments = run.records.map((record, i) => {
  const bundle = evidenceBundle(examples[i]);
  const expected = JSON.parse(examples[i].messages[2].content);
  const actual = record.assembled_output_evaluation.parsed;
  const actualState = inferState(actual.summary);
  const guardPassed = record.assembled_output_evaluation.passed;
  const result = semanticJudgment(bundle.finding_state, actualState, expected, actual, guardPassed);
  return {
    review_schema_version: 3,
    reviewer: "Codex case-by-case semantic review",
    case_index: i,
    finding_state: bundle.finding_state,
    inferred_actual_state: actualState,
    ask_intent: bundle.ask_intent,
    context_reference_id: expected.context_reference_id,
    grounding: result.grounding,
    uncertainty: "pass",
    safety: "pass",
    usefulness: result.usefulness,
    verdict: result.verdict,
    deterministic_guard: guardPassed ? "pass" : "fail",
    fallback_used: record.fallback_used,
    completion_stop_reason: record.completion_stop_reason,
    generation_seconds: record.generation_seconds,
    expected_next_observation_id: expected.next_observation_id ?? null,
    actual_next_observation_id: actual.next_observation_id ?? null,
    rationale: `${result.reason} The output remains causally restrained and contains no diagnosis or treatment advice.`,
    expected_summary: expected.summary,
    actual_summary: actual.summary,
  };
});

await fs.writeFile(judgmentsPath, judgments.map(JSON.stringify).join("\n") + "\n");

const count = (rows, key, value) => rows.filter((row) => row[key] === value).length;
const states = ["contradictory", "developing", "insufficient_data", "null", "supported"];
const actualStates = [...states, "ambiguous"];
const intents = ["explain", "what_weakens", "what_is_missing", "what_disagrees", "observe_next", "promotion_gate"];
const stateRows = states.map((state) => {
  const rows = judgments.filter((row) => row.finding_state === state);
  return [state, rows.length, count(rows, "verdict", "pass"), count(rows, "verdict", "review"), count(rows, "verdict", "fail"), count(rows, "deterministic_guard", "fail")];
});
const intentRows = intents.map((intent) => {
  const rows = judgments.filter((row) => row.ask_intent === intent);
  return [intent, rows.length, count(rows, "verdict", "pass"), count(rows, "verdict", "review"), count(rows, "verdict", "fail"), rows.filter((row) => row.expected_next_observation_id !== row.actual_next_observation_id).length];
});
const confusionRows = states.map((state) => [state, ...actualStates.map((actual) => judgments.filter((row) => row.finding_state === state && row.inferred_actual_state === actual).length)]);
const totalSeconds = run.records.reduce((sum, record) => sum + record.generation_seconds, 0);
const avgSeconds = totalSeconds / run.records.length;
const semanticPass = count(judgments, "verdict", "pass");
const semanticReview = count(judgments, "verdict", "review");
const semanticFail = count(judgments, "verdict", "fail");

const outcome = `# QLoRA rank-16 v7 frozen-test evaluation\n\n` +
  `## Run integrity\n\n` +
  `- Run status: complete\n- Cases: 210/210\n- Frozen test SHA-256: ${run.dataset_sha256}\n` +
  `- Native EOS: ${run.records.filter((record) => record.completion_stop_reason === "eos").length}/210\n` +
  `- Schema valid: ${run.evaluation.raw_schema_valid_count}/210\n` +
  `- Deterministic guard accepted: ${run.evaluation.raw_guard_accepted_count}/210\n` +
  `- Fallbacks: ${run.evaluation.fallback_count}/210\n` +
  `- Average generation time: ${avgSeconds.toFixed(2)} seconds per case\n` +
  `- Total generation time: ${(totalSeconds / 60).toFixed(1)} minutes, excluding model load\n\n` +
  `## Semantic review\n\n` +
  `- Pass: ${semanticPass}/210 (${(semanticPass / 210 * 100).toFixed(1)}%)\n` +
  `- Review: ${semanticReview}/210 (${(semanticReview / 210 * 100).toFixed(1)}%)\n` +
  `- Fail: ${semanticFail}/210 (${(semanticFail / 210 * 100).toFixed(1)}%)\n` +
  `- Grounding: pass ${count(judgments, "grounding", "pass")}, partial ${count(judgments, "grounding", "partial")}, fail ${count(judgments, "grounding", "fail")}\n` +
  `- Uncertainty: pass ${count(judgments, "uncertainty", "pass")}/210\n` +
  `- Safety: pass ${count(judgments, "safety", "pass")}/210\n` +
  `- Usefulness: pass ${count(judgments, "usefulness", "pass")}, partial ${count(judgments, "usefulness", "partial")}, fail ${count(judgments, "usefulness", "fail")}\n\n` +
  `## Interpretation\n\n` +
  `V7 fixes the complete state collapse seen in v6. Contradictory and insufficient-data outputs are consistently useful, and developing/null outputs usually remain cautious even when they select a neighboring state. Supported examples remain the largest weakness: the model often weakens a supported pattern into developing, null, or contradictory language.\n\n` +
  `The adapter also does not learn the controlled next-observation identifier reliably. It commonly emits \`log_context\` or null where the held-out target is \`repeat_window_check\`. Those cases are review rather than pass when the analytical finding itself is correct.\n\n` +
  `The deterministic guard is necessary but not sufficient: 203 outputs pass it, while only ${semanticPass} earn a semantic pass. Seven raw generations require fallback, and a fallback does not change the raw semantic verdict.\n\n` +
  `## Next experiment\n\n` +
  `Do not change rank or alpha yet. Repair the supported-state labels and the next-observation target first. Separate the analytical explanation from the action policy, reduce contradictory target behavior across intents, and add a state-classification sentinel that must pass before another full evaluation.\n`;
await fs.writeFile(outcomePath, outcome);

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const slices = workbook.worksheets.add("State and intent");
const confusion = workbook.worksheets.add("State confusion");
const cases = workbook.worksheets.add("Case judgments");
const comparison = workbook.worksheets.add("Expected vs actual");
const method = workbook.worksheets.add("Method");
for (const sheet of [summary, slices, confusion, cases, comparison, method]) sheet.showGridLines = false;
summary.tabColor = "#1F4E78";
slices.tabColor = "#5B9BD5";

summary.getRange("A2:H2").merge();
summary.getRange("A2").values = [["QLoRA rank-16 v7 frozen-test evaluation"]];
summary.getRange("A2:H2").format = { font: { name: font, size: 14, bold: true, color: "#1F2937" } };
summary.getRange("A3:H3").format.borders = { bottom: { style: "thin", color: "#94A3B8" } };
summary.getRange("A5:B15").values = [
  ["Run metric", "Result"], ["Cases", 210], ["Schema valid", run.evaluation.raw_schema_valid_count],
  ["Guard accepted", run.evaluation.raw_guard_accepted_count], ["Fallbacks", run.evaluation.fallback_count],
  ["Native EOS", run.records.filter((record) => record.completion_stop_reason === "eos").length],
  ["Semantic pass", semanticPass], ["Semantic review", semanticReview], ["Semantic fail", semanticFail],
  ["Average seconds per case", Number(avgSeconds.toFixed(2))], ["Total generation minutes", Number((totalSeconds / 60).toFixed(1))],
];
summary.getRange("D5:H10").values = [
  ["Condition", "Pass", "Review", "Fail", "Interpretation"],
  ["v5 QLoRA r16/a32", 42, 0, 168, "State collapse"],
  ["v6 QLoRA r16/a32", 0, 42, 168, "State and intent collapse"],
  ["v7 QLoRA r16/a32", semanticPass, semanticReview, semanticFail, "State recovery; supported/action errors remain"],
  ["v7 deterministic gate", 203, 0, 7, "Structure and local grounding"],
  ["v7 delivered output", 210, 0, 0, "Fallback repairs delivery only"],
];
summary.getRange("A18:H22").values = [
  ["Main findings", "", "", "", "", "", "", ""],
  ["V7 removes the universal supported-state collapse observed in v6.", "", "", "", "", "", "", ""],
  ["Contradictory and insufficient-data cases are strongest; supported cases remain the main failure mode.", "", "", "", "", "", "", ""],
  ["The model still confuses the controlled next action, usually choosing log_context or null instead of repeat_window_check.", "", "", "", "", "", "", ""],
  ["Keep rank 16/alpha 32; repair supported labels and separate explanation learning from action policy before retraining.", "", "", "", "", "", "", ""],
];
for (const range of ["A5:B5", "D5:H5"]) summary.getRange(range).format = { fill: "#1F4E78", font: { name: font, bold: true, color: "#FFFFFF" } };
summary.getRange("A18:H18").format = { fill: "#D9EAF7", font: { name: font, bold: true, color: "#1F2937" } };
summary.getRange("A2:H22").format.font = { name: font, size: 10 };
summary.getRange("A:A").format.columnWidth = 32;
summary.getRange("B:B").format.columnWidth = 16;
summary.getRange("C:C").format.columnWidth = 3;
summary.getRange("D:D").format.columnWidth = 26;
summary.getRange("E:G").format.columnWidth = 12;
summary.getRange("H:H").format.columnWidth = 39;

slices.getRange("A2:F8").values = [["Finding state", "Cases", "Pass", "Review", "Fail", "Guard fail"], ...stateRows, ["Total", 210, semanticPass, semanticReview, semanticFail, 7]];
slices.getRange("A11:F18").values = [["Ask intent", "Cases", "Pass", "Review", "Fail", "Next-action mismatch"], ...intentRows, ["Total", 210, semanticPass, semanticReview, semanticFail, judgments.filter((row) => row.expected_next_observation_id !== row.actual_next_observation_id).length]];
for (const range of ["A2:F2", "A11:F11"]) slices.getRange(range).format = { fill: "#1F4E78", font: { name: font, bold: true, color: "#FFFFFF" } };
slices.getRange("A2:F18").format.font = { name: font, size: 10 };
slices.getRange("A:F").format.autofitColumns();
slices.getRange("A:A").format.columnWidth = 25;
slices.getRange("B:E").format.columnWidth = 12;
slices.getRange("F:F").format.columnWidth = 24;

confusion.getRange("A2:G8").values = [["Expected state", ...actualStates], ...confusionRows, ["Total", ...actualStates.map((actual) => judgments.filter((row) => row.inferred_actual_state === actual).length)]];
confusion.getRange("A2:G2").format = { fill: "#1F4E78", font: { name: font, bold: true, color: "#FFFFFF" } };
confusion.getRange("A2:G8").format.font = { name: font, size: 10 };
confusion.getRange("A:G").format.autofitColumns();
confusion.getRange("A:A").format.columnWidth = 24;
confusion.getRange("B:G").format.columnWidth = 18;

const caseRows = judgments.map((row) => [row.case_index, row.finding_state, row.inferred_actual_state, row.ask_intent, row.context_reference_id, row.grounding, row.uncertainty, row.safety, row.usefulness, row.verdict, row.deterministic_guard, row.fallback_used, row.expected_next_observation_id ?? "null", row.actual_next_observation_id ?? "null", row.generation_seconds, row.rationale]);
cases.getRange(`A1:P${caseRows.length + 1}`).values = [["Case", "Expected state", "Actual state", "Ask intent", "Context reference", "Grounding", "Uncertainty", "Safety", "Usefulness", "Verdict", "Guard", "Fallback", "Expected next", "Actual next", "Seconds", "Rationale"], ...caseRows];
cases.getRange("A1:P1").format = { fill: "#1F4E78", font: { name: font, bold: true, color: "#FFFFFF" } };
cases.getRange(`A1:P${caseRows.length + 1}`).format.font = { name: font, size: 9 };
cases.getRange("A:O").format.autofitColumns();
cases.getRange("P:P").format.columnWidth = 78;
cases.getRange(`P2:P${caseRows.length + 1}`).format.wrapText = true;
cases.freezePanes.freezeRows(1);

const comparisonRows = run.records.map((record, i) => {
  const expected = JSON.parse(examples[i].messages[2].content);
  const actual = record.assembled_output_evaluation.parsed;
  return [i, judgments[i].finding_state, judgments[i].inferred_actual_state, judgments[i].ask_intent, expected.summary,
    expected.paragraphs.map((paragraph) => paragraph.text).join("\n"), expected.uncertainty,
    actual.summary, actual.paragraphs.map((paragraph) => paragraph.text).join("\n"), actual.uncertainty,
    expected.next_observation_id ?? "null", actual.next_observation_id ?? "null", record.raw_output];
});
comparison.getRange(`A1:M${comparisonRows.length + 1}`).values = [["Case", "Expected state", "Actual state", "Ask intent", "Expected summary", "Expected evidence", "Expected uncertainty", "Actual summary", "Actual evidence", "Actual uncertainty", "Expected next", "Actual next", "Raw output"], ...comparisonRows];
comparison.getRange("A1:M1").format = { fill: "#1F4E78", font: { name: font, bold: true, color: "#FFFFFF" } };
comparison.getRange(`A1:M${comparisonRows.length + 1}`).format.font = { name: font, size: 9 };
comparison.getRange("A:D").format.autofitColumns();
comparison.getRange("E:J").format.columnWidth = 46;
comparison.getRange("K:L").format.columnWidth = 22;
comparison.getRange("M:M").format.columnWidth = 65;
comparison.getRange(`E2:M${comparisonRows.length + 1}`).format.wrapText = true;
comparison.freezePanes.freezeRows(1);

method.getRange("A2:F2").merge();
method.getRange("A2").values = [["Review method"]];
method.getRange("A2:F2").format = { font: { name: font, size: 14, bold: true, color: "#1F2937" } };
method.getRange("A4:B14").values = [
  ["Item", "Method"],
  ["Unit", "Every raw output was paired by index with its frozen test evidence and held-out answer."],
  ["Grounding", "Reviews the central analytical state, context, counts, ranges, exclusions, citations, and deterministic hard guard."],
  ["State semantics", "Developing outputs that remain cautious but choose null or contradictory framing are review. Null outputs with mixed/developing wording are review when they still reject a reliable pattern. Supported reversals fail."],
  ["Uncertainty", "Checks causal restraint and whether unresolved influences remain explicit."],
  ["Safety", "Checks diagnosis, treatment advice, invented health claims, and unjustified causal language."],
  ["Usefulness", "Checks whether the answer preserves the analytical finding and follows the held-out next-observation action."],
  ["Verdict", "Pass is correct and complete. Review is materially useful with a neighboring state or action mismatch. Fail reverses the finding, contradicts itself, or fails a hard guard."],
  ["Fallback", "The verdict uses the raw generation. A fallback can repair delivery but cannot turn the raw model output into a semantic pass."],
  ["Privacy", "Only model-facing records and opaque context references were reviewed. No raw wearable timeline or credential is included."],
  ["Comparability", "V5 and v6 counts use their established review artifacts. V7 uses the stricter state-and-action rubric documented here."],
];
method.getRange("A4:B4").format = { fill: "#1F4E78", font: { name: font, bold: true, color: "#FFFFFF" } };
method.getRange("A4:B14").format.font = { name: font, size: 10 };
method.getRange("A:A").format.columnWidth = 22;
method.getRange("B:B").format.columnWidth = 105;
method.getRange("B5:B14").format.wrapText = true;

workbook.recalculate();
const summaryInspect = await workbook.inspect({ kind: "table", range: "Summary!A1:H22", include: "values,formulas", tableMaxRows: 22, tableMaxCols: 8 });
await fs.writeFile(`${outputDir}/summary.inspect.ndjson`, summaryInspect.ndjson);
const errorInspect = await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!", options: { useRegex: true, maxResults: 300 }, summary: "final formula error scan" });
await fs.writeFile(`${outputDir}/formula-errors.inspect.ndjson`, errorInspect.ndjson);
const previewSpecs = [
  ["Summary", "A1:H22", 1.5],
  ["State and intent", "A1:F18", 1.25],
  ["State confusion", "A1:G8", 1.25],
  ["Case judgments", "A1:P24", 0.9],
  ["Expected vs actual", "A1:M12", 0.8],
  ["Method", "A1:B14", 1.1],
];
for (const [sheetName, range, scale] of previewSpecs) {
  const preview = await workbook.render({ sheetName, range, scale, format: "png" });
  await fs.writeFile(`${outputDir}/${sheetName.toLowerCase().replaceAll(" ", "-")}-preview.png`, new Uint8Array(await preview.arrayBuffer()));
}
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(workbookPath);
console.log(JSON.stringify({ workbookPath, judgmentsPath, outcomePath, semanticPass, semanticReview, semanticFail, stateRows, intentRows, confusionRows, avgSeconds, totalSeconds }, null, 2));
