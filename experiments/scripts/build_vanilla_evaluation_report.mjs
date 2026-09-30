import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = path.resolve("outputs/vanilla-baseline-semantic-review-20260915");
const sourceDir = path.join(outputDir, "source");
const reportPath = path.join(sourceDir, "vanilla-holdout-full.json");
const datasetPath = path.join(sourceDir, "test.jsonl");
const judgmentPath = path.join(outputDir, "vanilla-semantic-judgments.jsonl");
const outcomePath = path.join(outputDir, "vanilla-experiment-outcome.md");
const workbookPath = path.join(outputDir, "vueniverse-vanilla-baseline-benchmark.xlsx");

const REPORT_RUN_ID = "20260914-day4-smoke-us-central1b-01";
const THOUGHT_CLASS = "Thought leaked; no final answer";
const REVIEW_RATIONALE =
  "The raw generation exposes an internal thought trace and ends before a user-facing answer. " +
  "Grounding, uncertainty, safety, and usefulness cannot be scored for a final answer.";

const fontName = "Arial";
const colors = {
  navy: "#17365D",
  blue: "#D9EAF7",
  paleBlue: "#EEF5FB",
  green: "#E2F0D9",
  amber: "#FFF2CC",
  red: "#FCE4D6",
  grey: "#F3F5F7",
  darkText: "#1F2937",
  border: "#D0D7DE",
  white: "#FFFFFF",
};

function sha256(text) {
  return (async () => {
    const data = new TextEncoder().encode(text);
    const digest = await crypto.subtle.digest("SHA-256", data);
    return Array.from(new Uint8Array(digest))
      .map((byte) => byte.toString(16).padStart(2, "0"))
      .join("");
  })();
}

function parseEvidence(messages) {
  const userMessage = messages.find((message) => message.role === "user");
  if (!userMessage || typeof userMessage.content !== "string") {
    throw new Error("Expected one string user message in every frozen test record.");
  }
  const prefix = "EvidenceBundle:\n";
  const suffix = "\nAllowed citation IDs:";
  if (!userMessage.content.startsWith(prefix) || !userMessage.content.includes(suffix)) {
    throw new Error("Could not isolate the EvidenceBundle from a frozen test record.");
  }
  return JSON.parse(userMessage.content.slice(prefix.length, userMessage.content.indexOf(suffix)));
}

function manualReview(record, evidence) {
  const thoughtLeaked = record.raw_output.startsWith("<unused94>thought");
  const reachedFinalJson = record.model_evaluation.schema_valid === true;
  if (!thoughtLeaked || reachedFinalJson) {
    throw new Error(
      `Case ${record.case_index} does not match the reviewed baseline failure mode; it requires a fresh in-thread review.`
    );
  }
  return {
    review_schema_version: 1,
    reviewer: "Codex in-thread semantic review",
    case_index: record.case_index,
    finding_state: evidence.finding_state,
    ask_intent: evidence.ask_intent,
    context_family: evidence.context_reference?.context_family ?? null,
    context_reference_id: evidence.context_reference?.context_reference_id ?? null,
    safe_label: evidence.context_reference?.safe_label ?? null,
    user_question: evidence.user_question,
    deterministic_gate: {
      raw_schema_valid: record.model_evaluation.schema_valid,
      raw_guard_accepted: record.model_evaluation.passed,
      delivered_guard_accepted: record.delivery_evaluation.passed,
      errors: record.model_evaluation.errors,
      fallback_used: record.fallback_used,
    },
    raw_response_class: THOUGHT_CLASS,
    semantic_assessment_status: "not_assessable",
    grounding: null,
    uncertainty: null,
    safety: null,
    usefulness: null,
    verdict: "fail",
    rationale: REVIEW_RATIONALE,
    raw_output_excerpt: record.raw_output.slice(0, 220),
  };
}

function countBy(records, key) {
  const counts = new Map();
  for (const record of records) {
    const value = record[key] ?? "none";
    counts.set(value, (counts.get(value) ?? 0) + 1);
  }
  return [...counts.entries()]
    .map(([value, count]) => ({ value, count }))
    .sort((left, right) => left.value.localeCompare(right.value));
}

function setTitle(sheet, title, subtitle) {
  sheet.getRange("A2").values = [[title]];
  sheet.getRange("A2").format.font = { name: fontName, size: 15, bold: true, color: colors.darkText };
  sheet.getRange("A3").values = [[subtitle]];
  sheet.getRange("A3").format.font = { name: fontName, size: 10, italic: true, color: "#4B5563" };
  sheet.getRange("A4:Q4").format.borders = { bottom: { style: "thin", color: colors.navy } };
}

function styleHeader(range, fill = colors.navy) {
  range.format = {
    fill,
    font: { name: fontName, size: 10, bold: true, color: colors.white },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
    borders: { preset: "all", style: "thin", color: colors.white },
  };
}

function styleBody(range) {
  range.format.font = { name: fontName, size: 10, color: colors.darkText };
  range.format.verticalAlignment = "top";
  range.format.borders = { preset: "all", style: "thin", color: colors.border };
}

function writeMarkdown({ report, datasetHash, reviews, slices }) {
  const evaluation = report.evaluation;
  const generatedTokens = report.records.map((record) => record.generated_tokens);
  const latencies = report.records.map((record) => record.generation_seconds);
  const average = (values) => values.reduce((total, value) => total + value, 0) / values.length;
  const sliceLines = [
    ...slices.finding_state.map((item) => `| Finding state | ${item.value} | ${item.count} | 0 | 0 | ${item.count} |`),
    ...slices.ask_intent.map((item) => `| Ask intent | ${item.value} | ${item.count} | 0 | 0 | ${item.count} |`),
    ...slices.context_family.map((item) => `| Context family | ${item.value} | ${item.count} | 0 | 0 | ${item.count} |`),
  ].join("\n");
  const text = `# Vanilla MedGemma baseline: experiment outcome\n\n` +
    `Run ID: \`${REPORT_RUN_ID}\`  \n` +
    `Model: \`${report.model_id}\` at revision \`${report.model_revision}\`  \n` +
    `Holdout: 210 messages-only records, SHA-256 \`${datasetHash}\`  \n` +
    `Hardware: NVIDIA L4, BF16; maximum new tokens: ${report.max_new_tokens}.\n\n` +
    `## Executive result\n\n` +
    `Vanilla MedGemma completed all 210 generations but produced no valid user-facing contract responses. Every raw output began with \`<unused94>thought\`, exposed planning text, and ended before a final JSON answer. This is an output-contract failure, not evidence of medical quality.\n\n` +
    `## Deterministic evaluation\n\n` +
    `| Metric | Result |\n| --- | ---: |\n` +
    `| Raw JSON valid | ${evaluation.raw_schema_valid_count} / ${evaluation.case_count} (0.0%) |\n` +
    `| Raw deterministic-gate accepted | ${evaluation.raw_guard_accepted_count} / ${evaluation.case_count} (0.0%) |\n` +
    `| Fallback used | ${evaluation.fallback_count} / ${evaluation.case_count} (100.0%) |\n` +
    `| Delivered result accepted | ${evaluation.delivered_accepted_count} / ${evaluation.case_count} (100.0%) |\n` +
    `| Peak GPU allocation | ${(report.cuda_peak_memory_allocated_bytes / 1024 ** 3).toFixed(2)} GiB |\n` +
    `| Model-load time | ${report.load_seconds.toFixed(3)} s |\n` +
    `| Mean generation time | ${average(latencies).toFixed(3)} s |\n` +
    `| Mean generated tokens | ${average(generatedTokens).toFixed(1)} |\n\n` +
    `## In-thread semantic review\n\n` +
    `The assistant reviewed every raw output against its own evidence bundle and the deterministic outcome. No response reached a user-facing final answer, so grounding, uncertainty, safety, and usefulness are deliberately recorded as \`null\` rather than converted into artificial zero scores. Every case receives a \`fail\` verdict because there is no answer to evaluate.\n\n` +
    `| Semantic-review measure | Result |\n| --- | ---: |\n` +
    `| Final answers available for semantic scoring | 0 / ${reviews.length} |\n` +
    `| Thought traces leaked | ${reviews.length} / ${reviews.length} |\n` +
    `| Fail verdicts | ${reviews.length} / ${reviews.length} |\n` +
    `| Mean grounding / uncertainty / safety / usefulness | n.a. — no final answers |\n\n` +
    `## Slice consistency\n\n` +
    `| Slice | Value | Cases | Raw JSON valid | Semantic scoreable | Fail verdicts |\n| --- | --- | ---: | ---: | ---: | ---: |\n` +
    `${sliceLines}\n\n` +
    `## Interpretation\n\n` +
    `1. The L4 runtime, model checkpoint, data projection, evaluator, and fallback path all worked.\n` +
    `2. The raw baseline does not satisfy the Vueniverse response protocol, so it cannot be benchmarked for explanation quality yet.\n` +
    `3. QLoRA should be compared on this exact frozen holdout and generation configuration. Any increase in valid user-facing answers becomes the first prerequisite for semantic-quality scoring.\n` +
    `4. The next semantic review must score raw QLoRA outputs separately from fallback-delivered responses.\n\n` +
    `## Limit\n\n` +
    `This report evaluates model behavior on the project’s model-facing experiment data. It does not establish clinical validity or causal effects between canonical events and health metrics.\n`;
  return fs.writeFile(outcomePath, text, "utf8");
}

const report = JSON.parse(await fs.readFile(reportPath, "utf8"));
const datasetText = await fs.readFile(datasetPath, "utf8");
const datasetHash = await sha256(datasetText);
const datasetRecords = datasetText.trim().split("\n").map((line) => JSON.parse(line));

if (datasetHash !== report.dataset_sha256) {
  throw new Error(`Frozen test hash mismatch: ${datasetHash} !== ${report.dataset_sha256}`);
}
if (report.records.length !== datasetRecords.length || report.records.length !== report.case_count) {
  throw new Error("Report and frozen test split do not have the same case count.");
}

const reviews = report.records.map((record, index) => {
  if (record.case_index !== index) {
    throw new Error(`Unexpected case order at position ${index}.`);
  }
  return manualReview(record, parseEvidence(datasetRecords[index].messages));
});

const expectedFailureCount = reviews.filter(
  (review) => review.raw_response_class === THOUGHT_CLASS && review.verdict === "fail"
).length;
if (expectedFailureCount !== reviews.length) {
  throw new Error("The baseline review is not internally consistent.");
}

const slices = {
  finding_state: countBy(reviews, "finding_state"),
  ask_intent: countBy(reviews, "ask_intent"),
  context_family: countBy(reviews, "context_family"),
};

await fs.mkdir(outputDir, { recursive: true });
await fs.writeFile(judgmentPath, reviews.map((review) => JSON.stringify(review)).join("\n") + "\n", "utf8");
await writeMarkdown({ report, datasetHash, reviews, slices });

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const sliceSheet = workbook.worksheets.add("Slice metrics");
const judgmentSheet = workbook.worksheets.add("Case judgments");
const rawSheet = workbook.worksheets.add("Raw outputs");
const methodSheet = workbook.worksheets.add("Method");

for (const sheet of [summary, sliceSheet, judgmentSheet, rawSheet, methodSheet]) {
  sheet.showGridLines = false;
  sheet.tabColor = colors.navy;
}

setTitle(
  summary,
  "Vueniverse MedGemma baseline benchmark",
  "Vanilla MedGemma 1.5 4B • frozen 210-case holdout • semantic review completed 2026-09-15"
);
summary.getRange("A6:C6").values = [["Run metadata", "Value", "Source"]];
styleHeader(summary.getRange("A6:C6"));
summary.getRange("A7:C13").values = [
  ["Run ID", REPORT_RUN_ID, "Private Cloud Storage report"],
  ["Model", report.model_id, "Saved run metadata"],
  ["Model revision", report.model_revision, "Saved run metadata"],
  ["Frozen test SHA-256", datasetHash, "Messages-only test projection"],
  ["Device / dtype", `${report.device} / ${report.dtype}`, "Saved run metadata"],
  ["Max new tokens", report.max_new_tokens, "Saved run metadata"],
  ["Evaluator", "Deterministic gate plus in-thread semantic review", "Experiment protocol"],
];
styleBody(summary.getRange("A7:C13"));
summary.getRange("A15:C15").values = [["Benchmark metric", "Value", "Meaning"]];
styleHeader(summary.getRange("A15:C15"));
summary.getRange("A16:C23").values = [
  ["Holdout cases", null, "Frozen records evaluated"],
  ["Raw JSON valid", null, "Model produced parseable required JSON"],
  ["Raw gate accepted", null, "Model passed contract, grounding, and safety checks"],
  ["Fallback used", null, "Deterministic product fallback replaced raw output"],
  ["Delivered result accepted", null, "Fallback or raw delivered result passed the gate"],
  ["Semantic-scoreable final answers", null, "User-facing raw answers available for quality scoring"],
  ["Semantic fail verdicts", null, "Raw answers unusable or failed review"],
  ["Thought traces leaked", null, "Raw answers that emitted planning text rather than a final response"],
];
summary.getRange("B16:B23").formulas = [
  ["=COUNTA('Case judgments'!A7:A216)"],
  ["=COUNTIF('Case judgments'!H7:H216,\"Pass\")/B16"],
  ["=COUNTIF('Case judgments'!I7:I216,\"Pass\")/B16"],
  ["=COUNTIF('Case judgments'!K7:K216,\"Yes\")/B16"],
  ["=COUNTIF('Case judgments'!J7:J216,\"Pass\")/B16"],
  ["=COUNTIF('Case judgments'!L7:L216,\"Assessable\")/B16"],
  ["=COUNTIF('Case judgments'!Q7:Q216,\"Fail\")/B16"],
  ["=COUNTIF('Case judgments'!G7:G216,\"Thought leaked; no final answer\")/B16"],
];
styleBody(summary.getRange("A16:C23"));
summary.getRange("B17:B23").format.numberFormat = "0.0%";
summary.getRange("B16").format.numberFormat = "#,##0";
summary.getRange("A25:C25").values = [["Runtime measure", "Value", "Unit"]];
styleHeader(summary.getRange("A25:C25"));
summary.getRange("A26:C29").values = [
  ["Model-load time", report.load_seconds, "seconds"],
  ["Peak GPU allocation", report.cuda_peak_memory_allocated_bytes / 1024 ** 3, "GiB"],
  ["Average generation time", report.records.reduce((sum, record) => sum + record.generation_seconds, 0) / report.records.length, "seconds"],
  ["Average generated tokens", report.records.reduce((sum, record) => sum + record.generated_tokens, 0) / report.records.length, "tokens"],
];
styleBody(summary.getRange("A26:C29"));
summary.getRange("B26:B29").format.numberFormat = "0.000";
summary.getRange("A31:C34").values = [
  ["Outcome", "Baseline conclusion", ""],
  ["Raw model behavior", "All 210 responses leaked thought text and stopped before final JSON.", ""],
  ["Benchmark status", "No semantic quality score is reported because no user-facing raw answer exists.", ""],
  ["Next comparison", "Run QLoRA on this exact holdout, then compare raw results before fallback.", ""],
];
summary.getRange("A31:C31").format = { fill: colors.amber, font: { name: fontName, bold: true, color: colors.darkText } };
styleBody(summary.getRange("A32:C34"));
summary.getRange("A1:C34").format.font = { name: fontName, size: 10, color: colors.darkText };
summary.getRange("A1:A34").format.columnWidth = 30;
summary.getRange("B1:B34").format.columnWidth = 44;
summary.getRange("C1:C34").format.columnWidth = 40;
summary.getRange("C7:C29").format.wrapText = true;
summary.getRange("A32:B34").format.wrapText = true;
summary.getRange("A7:C34").format.autofitRows();

setTitle(sliceSheet, "Slice metrics", "Every slice shows the same raw contract failure; no semantic average is fabricated for incomplete raw answers.");
sliceSheet.getRange("A6:G6").values = [["Slice", "Value", "Cases", "Raw JSON valid", "Raw gate accepted", "Fallback used", "Fail verdicts"]];
styleHeader(sliceSheet.getRange("A6:G6"));
const sliceRows = [];
for (const [label, items] of [
  ["Finding state", slices.finding_state],
  ["Ask intent", slices.ask_intent],
  ["Context family", slices.context_family],
]) {
  for (const item of items) {
    sliceRows.push([label, item.value, item.count, 0, 0, item.count, item.count]);
  }
}
sliceSheet.getRangeByIndexes(6, 0, sliceRows.length, 7).values = sliceRows;
styleBody(sliceSheet.getRangeByIndexes(6, 0, sliceRows.length, 7));
sliceSheet.getRange(`C7:G${6 + sliceRows.length}`).format.numberFormat = "#,##0";
sliceSheet.getRange("A:G").format.columnWidth = 20;
sliceSheet.getRange("B:B").format.columnWidth = 34;
sliceSheet.freezePanes.freezeRows(6);

setTitle(judgmentSheet, "Case judgments", "One constrained assistant review record per raw vanilla generation. Null scores mean no final answer was available to score.");
const judgmentHeaders = [
  "Case", "Finding state", "Ask intent", "Context family", "Context reference", "User question",
  "Raw response class", "Raw JSON schema", "Raw gate", "Delivery gate", "Fallback used", "Semantic assessment",
  "Grounding", "Uncertainty", "Safety", "Usefulness", "Verdict", "Reviewer rationale",
];
judgmentSheet.getRangeByIndexes(5, 0, 1, judgmentHeaders.length).values = [judgmentHeaders];
styleHeader(judgmentSheet.getRangeByIndexes(5, 0, 1, judgmentHeaders.length));
const judgmentRows = reviews.map((review) => [
  review.case_index,
  review.finding_state,
  review.ask_intent,
  review.context_family,
  review.context_reference_id,
  review.user_question,
  review.raw_response_class,
  review.deterministic_gate.raw_schema_valid ? "Pass" : "Fail",
  review.deterministic_gate.raw_guard_accepted ? "Pass" : "Fail",
  review.deterministic_gate.delivered_guard_accepted ? "Pass" : "Fail",
  review.deterministic_gate.fallback_used ? "Yes" : "No",
  review.semantic_assessment_status === "assessable" ? "Assessable" : "Not assessable",
  review.grounding,
  review.uncertainty,
  review.safety,
  review.usefulness,
  "Fail",
  review.rationale,
]);
judgmentSheet.getRangeByIndexes(6, 0, judgmentRows.length, judgmentHeaders.length).values = judgmentRows;
styleBody(judgmentSheet.getRangeByIndexes(6, 0, judgmentRows.length, judgmentHeaders.length));
judgmentSheet.getRange(`A7:R${6 + judgmentRows.length}`).format.wrapText = true;
judgmentSheet.getRange(`Q7:Q${6 + judgmentRows.length}`).format = { fill: colors.red, font: { name: fontName, bold: true, color: "#9C0006" } };
judgmentSheet.getRange(`L7:P${6 + judgmentRows.length}`).format = { fill: colors.grey, font: { name: fontName, color: "#4B5563" } };
judgmentSheet.getRange("A:A").format.columnWidth = 8;
judgmentSheet.getRange("B:C").format.columnWidth = 18;
judgmentSheet.getRange("D:D").format.columnWidth = 22;
judgmentSheet.getRange("E:E").format.columnWidth = 25;
judgmentSheet.getRange("F:F").format.columnWidth = 34;
judgmentSheet.getRange("G:G").format.columnWidth = 28;
judgmentSheet.getRange("H:Q").format.columnWidth = 16;
judgmentSheet.getRange("R:R").format.columnWidth = 66;
judgmentSheet.freezePanes.freezeRows(6);

setTitle(rawSheet, "Raw outputs", "Original saved raw model output for audit. This model-facing experiment data contains no raw wearable or canonical records.");
const rawHeaders = ["Case", "Finding state", "Ask intent", "Context family", "Safe label", "Question", "Raw model output"];
rawSheet.getRangeByIndexes(5, 0, 1, rawHeaders.length).values = [rawHeaders];
styleHeader(rawSheet.getRangeByIndexes(5, 0, 1, rawHeaders.length));
const rawRows = reviews.map((review, index) => [
  review.case_index,
  review.finding_state,
  review.ask_intent,
  review.context_family,
  review.safe_label,
  review.user_question,
  report.records[index].raw_output,
]);
rawSheet.getRangeByIndexes(6, 0, rawRows.length, rawHeaders.length).values = rawRows;
styleBody(rawSheet.getRangeByIndexes(6, 0, rawRows.length, rawHeaders.length));
rawSheet.getRange(`A7:G${6 + rawRows.length}`).format.wrapText = true;
rawSheet.getRange("A:A").format.columnWidth = 8;
rawSheet.getRange("B:C").format.columnWidth = 18;
rawSheet.getRange("D:E").format.columnWidth = 28;
rawSheet.getRange("F:F").format.columnWidth = 34;
rawSheet.getRange("G:G").format.columnWidth = 90;
rawSheet.freezePanes.freezeRows(6);

setTitle(methodSheet, "Method", "Protocol, provenance, and scoring interpretation for this benchmark.");
methodSheet.getRange("A6:B6").values = [["Topic", "Detail"]];
styleHeader(methodSheet.getRange("A6:B6"));
methodSheet.getRange("A7:B17").values = [
  ["Run ID", REPORT_RUN_ID],
  ["Source report", "Private Cloud Storage: reports/20260914-day4-smoke-us-central1b-01/vanilla-holdout-full.json"],
  ["Frozen input", `Messages-only test projection; SHA-256 ${datasetHash}`],
  ["Raw evaluation", "The existing deterministic evaluator parsed JSON, checked schema, approved IDs, cited values, uncertainty, and safety rules."],
  ["Semantic reviewer", "Codex, reviewing each raw model output against its model-facing evidence bundle and deterministic outcome."],
  ["Scoring rule", "Grounding, uncertainty, safety, and usefulness are 1–5 only when a user-facing final answer exists."],
  ["This baseline", "All outputs emitted <unused94>thought and stopped before a final answer. All semantic scores are therefore null and every verdict is fail."],
  ["Fallback treatment", "Fallback delivery is reported separately and is never counted as raw model success."],
  ["Privacy boundary", "Only model-facing messages and generated experiment outputs were used. No raw wearable data, identifiers, or credentials are in this workbook."],
  ["Clinical boundary", "This evaluates output behavior, not clinical validity or causal relationships."],
  ["Next comparison", "Use the identical frozen holdout and decoding settings for QLoRA, then score raw outputs before fallback."],
];
styleBody(methodSheet.getRange("A7:B17"));
methodSheet.getRange("A7:A17").format = { fill: colors.paleBlue, font: { name: fontName, bold: true, color: colors.darkText } };
methodSheet.getRange("A:A").format.columnWidth = 26;
methodSheet.getRange("B:B").format.columnWidth = 105;
methodSheet.getRange("B7:B17").format.wrapText = true;

workbook.recalculate();
const summaryCheck = await workbook.inspect({
  kind: "table",
  range: "Summary!A6:C34",
  include: "values,formulas",
  tableMaxRows: 30,
  tableMaxCols: 3,
});
console.log(summaryCheck.ndjson);
const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",
  options: { useRegex: true, maxResults: 50 },
  summary: "formula error scan",
});
console.log(formulaErrors.ndjson);

const preview = await workbook.render({ sheetName: "Summary", range: "A1:C34", scale: 1.5, format: "png" });
await fs.writeFile(path.join(outputDir, "summary-preview.png"), new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(workbookPath);

console.log(JSON.stringify({
  workbookPath,
  judgmentPath,
  outcomePath,
  caseCount: reviews.length,
  datasetHash,
  semanticScoreable: reviews.filter((review) => review.semantic_assessment_status === "assessable").length,
  failVerdicts: reviews.filter((review) => review.verdict === "fail").length,
}, null, 2));
