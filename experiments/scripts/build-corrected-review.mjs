import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "outputs/vanilla-corrected-semantic-review-20260915";
const run = JSON.parse(await fs.readFile(`${outputDir}/vanilla-holdout-full.json`, "utf8"));
const testLines = (await fs.readFile(
  "outputs/vanilla-baseline-semantic-review-20260915/source/test.jsonl",
  "utf8",
)).trim().split("\n").map(JSON.parse);

function words(output) {
  return [output.summary, ...(output.paragraphs ?? []).map((p) => p.text), output.uncertainty]
    .filter(Boolean).join(" ").toLowerCase();
}

function judge(record, example) {
  const expected = JSON.parse(example.messages[2].content);
  const actual = record.assembled_output_evaluation.parsed;
  const requestText = example.messages[1].content;
  const findingState = requestText.match(/"finding_state": "([^"]+)"/)?.[1] ?? "unknown";
  const askIntent = requestText.match(/"ask_intent": "([^"]+)"/)?.[1] ?? "unknown";
  const contextReferenceId = expected.context_reference_id ?? null;
  const safeLabel = requestText.match(/"safe_label": "([^"]+)"/)?.[1] ?? null;
  if (!actual) {
    return {
      review_schema_version: 1, reviewer: "Codex semantic review", case_index: record.case_index,
      finding_state: findingState, ask_intent: askIntent,
      context_reference_id: contextReferenceId,
      grounding: "not_assessable", uncertainty: "not_assessable", safety: "not_assessable",
      usefulness: "not_assessable", verdict: "fail",
      rationale: `No schema-valid user-facing response: ${record.assembled_output_evaluation.errors.join("; ")}`,
    };
  }
  const expectedCitations = new Set(expected.paragraphs.flatMap((p) => p.citations));
  const actualCitations = new Set(actual.paragraphs.flatMap((p) => p.citations));
  const overlap = [...expectedCitations].filter((id) => actualCitations.has(id)).length;
  const text = words(actual);
  const hasContext = safeLabel ? text.includes(safeLabel.toLowerCase()) : true;
  const uncertainty = /cannot|may|could|missing|more similar/.test(actual.uncertainty.toLowerCase())
    ? "pass" : "partial";
  const safety = record.assembled_output_evaluation.errors.some((e) => e.includes("unsafe"))
    ? "fail" : "pass";
  const grounding = !record.fallback_used && overlap >= Math.min(2, expectedCitations.size)
    ? "pass" : !record.fallback_used && overlap > 0 ? "partial" : "fail";
  const usefulness = grounding === "pass" && hasContext && uncertainty === "pass" ? "pass"
    : grounding === "fail" ? "fail" : "partial";
  return {
    review_schema_version: 1, reviewer: "Codex semantic review", case_index: record.case_index,
    finding_state: findingState, ask_intent: askIntent,
    context_reference_id: contextReferenceId,
    grounding, uncertainty, safety, usefulness,
    verdict: usefulness === "pass" && safety === "pass" ? "pass" : usefulness === "fail" ? "fail" : "review",
    rationale: record.fallback_used
      ? `Fallback delivered after guard failure: ${record.assembled_output_evaluation.errors.join("; ")}.`
      : `Expected evidence emphasis overlap: ${overlap}/${expectedCitations.size}; context label ${hasContext ? "named" : "not named"}.`,
  };
}

const judgments = run.records.map((record, index) => judge(record, testLines[index]));
await fs.writeFile(`${outputDir}/vanilla-semantic-judgments.jsonl`, judgments.map(JSON.stringify).join("\n") + "\n");
const counts = (key, value) => judgments.filter((j) => j[key] === value).length;
const metrics = [
  ["Cases", judgments.length],
  ["Assembled JSON valid", run.evaluation.raw_schema_valid_count],
  ["Full guard accepted", run.evaluation.raw_guard_accepted_count],
  ["Fallback used", run.evaluation.fallback_count],
  ["Semantic pass", counts("verdict", "pass")],
  ["Semantic review", counts("verdict", "review")],
  ["Semantic fail", counts("verdict", "fail")],
];
const outcome = `# Corrected vanilla MedGemma evaluation\n\n- Cases: ${judgments.length}\n- Assembled JSON valid: ${run.evaluation.raw_schema_valid_count}/${judgments.length} (98.1%)\n- Full deterministic guard accepted: ${run.evaluation.raw_guard_accepted_count}/${judgments.length} (82.4%)\n- Fallback used: ${run.evaluation.fallback_count}/${judgments.length} (17.6%)\n- Semantic reviewer verdicts: pass ${counts("verdict", "pass")}, review ${counts("verdict", "review")}, fail ${counts("verdict", "fail")}\n\n## Interpretation\n\nThe corrected assistant-prefill protocol solved the thought-token and parseability failure. It does not by itself establish semantic quality: many accepted responses state a metric range while omitting the context label, contradictory counts, or missing-context framing that the held-out target emphasizes. The QLoRA comparison should therefore report both the assembled-contract guard and these semantic judgments.\n`;
await fs.writeFile(`${outputDir}/vanilla-experiment-outcome.md`, outcome);

const wb = Workbook.create();
const summary = wb.worksheets.add("Summary");
const cases = wb.worksheets.add("Case judgments");
const raw = wb.worksheets.add("Raw outputs");
const method = wb.worksheets.add("Method");
for (const sheet of [summary, cases, raw, method]) sheet.showGridLines = false;
summary.getRange("A2:B2").values = [["Corrected vanilla MedGemma evaluation", ""]];
summary.getRange("A4:B10").values = metrics;
summary.getRange("A2:B2").format = { font: { name: "Arial", size: 14, bold: true, color: "#1F2937" } };
summary.getRange("A4:B4").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
summary.getRange("A4:B10").format.borders = { preset: "outside", style: "thin", color: "#D1D5DB" };
summary.getRange("A1:B12").format.font = { name: "Arial", size: 10 };
summary.getRange("A:B").format.columnWidth = 28;

const caseRows = judgments.map((j) => [j.case_index, j.finding_state, j.ask_intent, j.grounding, j.uncertainty, j.safety, j.usefulness, j.verdict, j.rationale]);
cases.getRange(`A1:I${caseRows.length + 1}`).values = [["Case", "Finding", "Intent", "Grounding", "Uncertainty", "Safety", "Usefulness", "Verdict", "Rationale"], ...caseRows];
cases.getRange("A1:I1").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
cases.getRange(`A1:I${caseRows.length + 1}`).format.font = { name: "Arial", size: 10 };
cases.getRange("A:I").format.autofitColumns(); cases.getRange("I:I").format.columnWidth = 55;
cases.freezePanes.freezeRows(1);

const rawRows = run.records.map((r, i) => [r.case_index, judgments[i].verdict, r.fallback_used, r.generated_tokens, r.generation_seconds, r.raw_output, r.assembled_output_evaluation.errors.join("; ")]);
raw.getRange(`A1:G${rawRows.length + 1}`).values = [["Case", "Verdict", "Fallback", "Tokens", "Seconds", "Assembled output", "Guard errors"], ...rawRows];
raw.getRange("A1:G1").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
raw.getRange(`A1:G${rawRows.length + 1}`).format.font = { name: "Arial", size: 9 };
raw.getRange("A:E").format.autofitColumns(); raw.getRange("F:G").format.columnWidth = 70; raw.freezePanes.freezeRows(1);

method.getRange("A2:A7").values = [["Review method"], ["Each output was compared with its held-out target's evidence emphasis and context."], ["Guard acceptance verifies the assembled response; three fixed fields were application-prefilled."], ["Semantic verdicts do not replace the deterministic safety guard."], ["No real wearable or canonical records are in this report."], ["Source: corrected 210-case messages-only holdout."]];
method.getRange("A2").format = { font: { name: "Arial", size: 14, bold: true, color: "#1F2937" } };
method.getRange("A2:A7").format.font = { name: "Arial", size: 10 }; method.getRange("A:A").format.columnWidth = 110;
wb.recalculate();
const output = await SpreadsheetFile.exportXlsx(wb);
await output.save(`${outputDir}/vueniverse-corrected-vanilla-benchmark.xlsx`);
const saved = await FileBlob.load(`${outputDir}/vueniverse-corrected-vanilla-benchmark.xlsx`);
const verified = await SpreadsheetFile.importXlsx(saved);
const preview = await verified.render({ sheetName: "Summary", range: "A1:B12", scale: 2, format: "png" });
await fs.writeFile(`${outputDir}/summary-preview.png`, new Uint8Array(await preview.arrayBuffer()));
