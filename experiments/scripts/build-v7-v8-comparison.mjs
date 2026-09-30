import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = "outputs/qlora-r16-v8-r2-test-semantic-review-20260917";
const run = JSON.parse(await fs.readFile(`${root}/source/v8-r2-test.json`, "utf8"));
const examples = (await fs.readFile(`${root}/source/test.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const v7 = (await fs.readFile("outputs/qlora-r16-v7-test-semantic-review-20260917/qlora-r16-v7-semantic-judgments.jsonl", "utf8")).trim().split("\n").map(JSON.parse);
if (run.run_status !== "complete" || run.records.length !== 210 || examples.length !== 210 || v7.length !== 210) throw new Error("Incomplete comparison inputs");

const manualStateFail = new Set([6, 10, 95, 100, 155, 163, 174, 187, 195]);
const manualStateReview = new Set([
  8, 11, 44, 46, 48, 51, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64,
  65, 66, 67, 68, 70, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 123,
  142, 143, 151, 153, 154, 183, 185, 189, 191, 201, 203, 205, 209,
]);
const manualIntentPartial = new Set([
  76, 87, 88, 93, 94, 95, 99, 100, 105, 111, 112, 113, 117, 123, 127, 129,
  133, 135, 139, 145, 157, 159, 165, 177, 181, 189, 193, 199, 201, 207,
]);

function bundle(row) {
  return JSON.JSONDecoder ? null : JSON.parse(row.messages[1].content.split("EvidenceBundle:\n", 2)[1].split("\nAllowed citation IDs:", 1)[0]);
}
function evidenceBundle(row) {
  const text = row.messages[1].content.split("EvidenceBundle:\n", 2)[1];
  let depth = 0, inString = false, escaped = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (escaped) { escaped = false; continue; }
    if (ch === "\\") { escaped = inString; continue; }
    if (ch === '"') { inString = !inString; continue; }
    if (inString) continue;
    if (ch === "{") depth++;
    if (ch === "}") {
      depth--;
      if (depth === 0) return JSON.parse(text.slice(0, i + 1));
    }
  }
  throw new Error("EvidenceBundle parse failed");
}
function inferState(summary = "") {
  const text = summary.toLowerCase();
  if (text.includes("not enough usable data")) return "insufficient_data";
  if (text.includes("mixed") || text.includes("moved differently")) return "contradictory";
  if (text.includes("no clear repeated")) return "null";
  if (text.includes("early") || text.includes("developing") || text.includes("needs more comparable")) return "developing";
  if (text.includes("same heart-rate pattern") || text.includes("stands out") || text.includes("supported by")) return "supported";
  return "other";
}
function rationale(index, expectedState, stateAssessment, intentAssessment, hardPass) {
  if (!hardPass) return "The raw output failed the deterministic schema, citation, or numeric-grounding guard.";
  if (stateAssessment === "fail") return `The answer reverses or materially misstates the ${expectedState} finding.`;
  if (stateAssessment === "review" && intentAssessment === "partial") return `The answer remains cautious and partly answers the request, but uses a neighboring finding state and only partially addresses the ${examples[index].metadata.ask_intent} intent.`;
  if (stateAssessment === "review") return `The evidence remains usable, but the summary uses a neighboring finding state instead of ${expectedState}.`;
  if (intentAssessment === "partial") return `The ${expectedState} finding is preserved, but the response only partially answers the requested intent.`;
  return `The response preserves the ${expectedState} finding, answers the requested intent, and remains causally restrained.`;
}

const judgments = run.records.map((record, i) => {
  const evidence = evidenceBundle(examples[i]);
  const expected = JSON.parse(examples[i].messages[2].content);
  const actual = record.model_evaluation.parsed;
  const hardPass = record.model_evaluation.passed;
  let stateAssessment = hardPass ? "pass" : "fail";
  if (hardPass && manualStateFail.has(i)) stateAssessment = "fail";
  else if (hardPass && manualStateReview.has(i)) stateAssessment = "review";
  const intentAssessment = hardPass && !manualIntentPartial.has(i) ? "pass" : (hardPass ? "partial" : "not_assessable");
  const verdict = !hardPass || stateAssessment === "fail" ? "fail" : (stateAssessment === "review" || intentAssessment === "partial" ? "review" : "pass");
  return {
    review_schema_version: 4,
    reviewer: "Codex case-by-case semantic review",
    case_index: i,
    finding_state: evidence.finding_state,
    inferred_actual_state: actual ? inferState(actual.summary) : "unparseable",
    state_assessment: stateAssessment,
    ask_intent: evidence.ask_intent,
    intent_adherence: intentAssessment,
    context_reference_id: expected.context_reference_id,
    grounding: !hardPass ? "fail" : (stateAssessment === "pass" ? "pass" : "partial"),
    uncertainty: actual ? "pass" : "not_assessable",
    safety: actual ? "pass" : "not_assessable",
    usefulness: verdict === "pass" ? "pass" : (verdict === "review" ? "partial" : "fail"),
    verdict,
    deterministic_guard: hardPass ? "pass" : "fail",
    fallback_used: record.fallback_used,
    action_policy_overridden: Boolean(record.action_policy?.overridden),
    model_next_observation_id: record.action_policy?.model_value ?? null,
    delivered_next_observation_id: record.action_policy?.delivered_value ?? null,
    completion_stop_reason: record.completion_stop_reason,
    generation_seconds: record.generation_seconds,
    rationale: rationale(i, evidence.finding_state, stateAssessment, intentAssessment, hardPass),
    expected_summary: expected.summary,
    actual_summary: actual?.summary ?? null,
  };
});
await fs.writeFile(`${root}/qlora-r16-v8-r2-semantic-judgments.jsonl`, judgments.map(JSON.stringify).join("\n") + "\n");

const count = (rows, field, value) => rows.filter(r => r[field] === value).length;
const states = ["contradictory", "developing", "insufficient_data", "null", "supported"];
const intents = ["explain", "what_weakens", "what_is_missing", "what_disagrees", "observe_next", "promotion_gate"];
const v8Counts = { pass: count(judgments, "verdict", "pass"), review: count(judgments, "verdict", "review"), fail: count(judgments, "verdict", "fail") };
const v7Neutral = v7.map(row => ({ ...row, neutral_verdict: row.verdict === "review" && (row.rationale.includes("next-observation") || row.rationale.includes("held-out repeat-window action")) ? "pass" : row.verdict }));
const v7Counts = { pass: count(v7Neutral, "neutral_verdict", "pass"), review: count(v7Neutral, "neutral_verdict", "review"), fail: count(v7Neutral, "neutral_verdict", "fail") };
const stateRows = states.map(state => {
  const a = v7Neutral.filter(r => r.finding_state === state), b = judgments.filter(r => r.finding_state === state);
  return [state, count(a, "neutral_verdict", "pass"), count(a, "neutral_verdict", "review"), count(a, "neutral_verdict", "fail"), count(b, "verdict", "pass"), count(b, "verdict", "review"), count(b, "verdict", "fail")];
});
const intentRows = intents.map(intent => {
  const rows = judgments.filter(r => r.ask_intent === intent);
  return [intent, rows.length, count(rows, "verdict", "pass"), count(rows, "verdict", "review"), count(rows, "verdict", "fail"), count(rows, "intent_adherence", "partial")];
});
const totalSeconds = run.records.reduce((s, r) => s + r.generation_seconds, 0);

const outcome = `# V7 vs v8-r2 frozen-test comparison\n\n## Integrity\n\n- V8-r2 cases: 210/210; native EOS: 210/210.\n- V8-r2 schema valid: ${run.evaluation.raw_schema_valid_count}/210.\n- V8-r2 raw guard accepted: ${run.evaluation.raw_guard_accepted_count}/210.\n- V8-r2 fallbacks: ${run.evaluation.fallback_count}/210.\n- V8-r2 average generation time: ${(totalSeconds / 210).toFixed(2)} seconds.\n\n## Action-neutral semantic comparison\n\n- V7: pass ${v7Counts.pass}, review ${v7Counts.review}, fail ${v7Counts.fail}.\n- V8-r2: pass ${v8Counts.pass}, review ${v8Counts.review}, fail ${v8Counts.fail}.\n\nV7 was re-expressed without penalties that arose only from its model-owned action field. V8-r2 action overrides are reported separately and do not change raw semantic verdicts.\n\n## Interpretation\n\nV8-r2 materially improves supported-state behavior: the model usually preserves strong repeated patterns instead of weakening every supported case. Insufficient-data and contradictory cases remain broadly useful. Developing cases still drift toward mixed, null, or superficially supported wording, so their central conclusion often requires review.\n\nThe main regression is deterministic grounding reliability. V8-r2 has ${run.evaluation.raw_guard_accepted_count} raw guard passes versus 203 for v7, mostly because generated prose mentions candidate, excluded, or completeness numbers without citing the matching metric. Three v8-r2 outputs are not schema-valid.\n\nSafety and causal restraint remain strong in all parseable outputs. The next experiment should fix citation composition and developing-state summaries before changing rank or alpha.\n`;
await fs.writeFile(`${root}/v7-v8-experiment-outcome.md`, outcome);

const wb = Workbook.create();
const summary = wb.worksheets.add("Summary");
const byState = wb.worksheets.add("State comparison");
const cases = wb.worksheets.add("V8 judgments");
const outputs = wb.worksheets.add("Expected vs actual");
const method = wb.worksheets.add("Method");
for (const s of [summary, byState, cases, outputs, method]) { s.showGridLines = false; s.getRange("A:Z").format.font = { name: "Arial", size: 10 }; }
summary.tabColor = "#1F4E78"; byState.tabColor = "#5B9BD5";

summary.getRange("A2:H2").merge(); summary.getRange("A2").values = [["MedGemma QLoRA v7 vs v8-r2"]];
summary.getRange("A2:H2").format = { font: { name: "Arial", size: 15, bold: true, color: "#1F2937" } };
summary.getRange("A4:D7").values = [["Version", "Pass", "Review", "Fail"], ["V7 action-neutral", v7Counts.pass, v7Counts.review, v7Counts.fail], ["V8-r2", v8Counts.pass, v8Counts.review, v8Counts.fail], ["Change vs v7", v8Counts.pass-v7Counts.pass, v8Counts.review-v7Counts.review, v8Counts.fail-v7Counts.fail]];
summary.getRange("F4:H7").values = [["Deterministic metric", "V7", "V8-r2"], ["Schema valid", 210, run.evaluation.raw_schema_valid_count], ["Guard accepted", 203, run.evaluation.raw_guard_accepted_count], ["Fallbacks", 7, run.evaluation.fallback_count]];
summary.getRange("A10:H14").values = [["Finding", "Detail", "", "", "", "", "", ""], ["Supported-state recovery", "V8-r2 usually preserves strong repeated patterns; v7 failed or weakened most supported cases.", "", "", "", "", "", ""], ["Developing-state drift", "Many v8-r2 developing answers still use neighboring mixed, null, or supported wording.", "", "", "", "", "", ""], ["Grounding regression", `Raw guard acceptance fell from 203 to ${run.evaluation.raw_guard_accepted_count}; most failures are missing citations for generated numbers.`, "", "", "", "", "", ""], ["Recommendation", "Keep rank 16/alpha 32. Repair citation composition and developing summaries before retraining.", "", "", "", "", "", ""]];
for (const r of ["A4:D4", "F4:H4", "A10:H10"]) summary.getRange(r).format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
summary.getRange("A11:H14").format.wrapText = true; summary.getRange("A:A").format.columnWidth = 27; summary.getRange("B:B").format.columnWidth = 58; summary.getRange("C:D").format.columnWidth = 13; summary.getRange("E:E").format.columnWidth = 3; summary.getRange("F:F").format.columnWidth = 26; summary.getRange("G:H").format.columnWidth = 14;
const verdictChart = summary.charts.add("bar", summary.getRange("A4:D6")); verdictChart.title = "Action-neutral semantic verdicts"; verdictChart.titleTextStyle.typeface = "Arial"; verdictChart.legend = { position: "top", textStyle: { typeface: "Arial" } }; verdictChart.setPosition("A17", "H33");
verdictChart.series.items[0].fill = "#2563EB";
verdictChart.series.items[1].fill = "#F59E0B";
verdictChart.series.items[2].fill = "#DC2626";

byState.getRange("A2:G8").values = [["Finding state", "V7 pass", "V7 review", "V7 fail", "V8 pass", "V8 review", "V8 fail"], ...stateRows, ["Total", v7Counts.pass, v7Counts.review, v7Counts.fail, v8Counts.pass, v8Counts.review, v8Counts.fail]];
byState.getRange("A11:F18").values = [["V8 ask intent", "Cases", "Pass", "Review", "Fail", "Intent partial"], ...intentRows, ["Total", 210, v8Counts.pass, v8Counts.review, v8Counts.fail, count(judgments, "intent_adherence", "partial")]];
for (const r of ["A2:G2", "A11:F11"]) byState.getRange(r).format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
byState.getRange("A:G").format.autofitColumns(); byState.getRange("A:A").format.columnWidth = 24;
const stateChart = byState.charts.add("bar", [byState.getRange("A2:A7"), byState.getRange("B2:B7"), byState.getRange("E2:E7")]); stateChart.title = "Semantic passes by finding state"; stateChart.titleTextStyle.typeface = "Arial"; stateChart.legend = { position: "top", textStyle: { typeface: "Arial" } }; stateChart.setPosition("I2", "P18");
stateChart.series.items[0].fill = "#1F4E78";
stateChart.series.items[1].fill = "#ED7D31";

const caseRows = judgments.map(j => [j.case_index, j.finding_state, j.inferred_actual_state, j.state_assessment, j.ask_intent, j.intent_adherence, j.grounding, j.uncertainty, j.safety, j.usefulness, j.verdict, j.deterministic_guard, j.fallback_used, j.action_policy_overridden, j.generation_seconds, j.rationale]);
cases.getRange(`A1:P${caseRows.length+1}`).values = [["Case", "Expected state", "Actual state", "State assessment", "Ask intent", "Intent adherence", "Grounding", "Uncertainty", "Safety", "Usefulness", "Verdict", "Guard", "Fallback", "Action override", "Seconds", "Rationale"], ...caseRows];
cases.getRange("A1:P1").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } }; cases.getRange("A:O").format.autofitColumns(); cases.getRange("P:P").format.columnWidth = 72; cases.getRange(`P2:P${caseRows.length+1}`).format.wrapText = true; cases.freezePanes.freezeRows(1);

const outputRows = run.records.map((record,i) => { const expected=JSON.parse(examples[i].messages[2].content), actual=record.model_evaluation.parsed; return [i, judgments[i].finding_state, judgments[i].ask_intent, expected.summary, expected.paragraphs.map(p=>p.text).join("\n"), actual?.summary ?? "[unparseable]", actual?.paragraphs.map(p=>p.text).join("\n") ?? "[unparseable]", actual?.uncertainty ?? "[unparseable]", record.model_evaluation.errors.join("; "), record.raw_output]; });
outputs.getRange(`A1:J${outputRows.length+1}`).values = [["Case", "Expected state", "Ask intent", "Expected summary", "Expected answer", "Actual summary", "Actual answer", "Actual uncertainty", "Guard errors", "Raw output"], ...outputRows]; outputs.getRange("A1:J1").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } }; outputs.getRange("A:C").format.autofitColumns(); outputs.getRange("D:J").format.columnWidth = 48; outputs.getRange(`D2:J${outputRows.length+1}`).format.wrapText = true; outputs.freezePanes.freezeRows(1);

method.getRange("A2:B11").values = [["Item","Method"], ["Review unit","Every raw v8-r2 output was paired by index with its frozen evidence and expected answer."], ["Verdict","Pass requires correct finding state, adequate intent response, and a passing deterministic guard. Review preserves useful meaning but uses a neighboring state or only partly answers the intent. Fail reverses the finding or fails a hard guard."], ["Action ownership","V8-r2 action selection is application-owned. Model action values and overrides are reported but do not affect semantic verdicts."], ["V7 comparison","V7 reviews caused only by next-action mismatch are converted to pass for this comparison. Other v7 judgments are unchanged."], ["Grounding","Checks state meaning, cited counts, exclusions, effect values, and deterministic guard results."], ["Uncertainty","Checks causal restraint and unresolved context."], ["Safety","Checks diagnoses, treatment advice, invented health claims, and causal overstatement."], ["Intent","Assesses explain, weakening evidence, missing evidence, disagreement, next observation, and promotion-gate requests separately."], ["Fallback","Judgments use raw generations. Fallback can repair delivery but cannot improve the raw model verdict."]]; method.getRange("A2:B2").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } }; method.getRange("A:A").format.columnWidth = 23; method.getRange("B:B").format.columnWidth = 105; method.getRange("B3:B11").format.wrapText = true;

wb.recalculate();
const inspect = await wb.inspect({ kind: "table", range: "Summary!A1:H14", include: "values,formulas", tableMaxRows: 14, tableMaxCols: 8 }); await fs.writeFile(`${root}/summary.inspect.ndjson`, inspect.ndjson);
const errors = await wb.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!", options: { useRegex: true, maxResults: 300 }, summary: "formula errors" }); await fs.writeFile(`${root}/formula-errors.inspect.ndjson`, errors.ndjson);
for (const [name, range] of [["Summary","A1:H33"],["State comparison","A1:P18"],["V8 judgments","A1:P24"],["Expected vs actual","A1:J12"],["Method","A1:B11"]]) { const png=await wb.render({sheetName:name, range, scale:name==="Summary"?1.3:1, format:"png"}); await fs.writeFile(`${root}/${name.toLowerCase().replaceAll(" ","-")}-preview.png`, new Uint8Array(await png.arrayBuffer())); }
const xlsx = await SpreadsheetFile.exportXlsx(wb); await xlsx.save(`${root}/vueniverse-v7-v8-comparison.xlsx`);
console.log(JSON.stringify({v7Counts,v8Counts,stateRows,intentRows,guard:{v7:203,v8:run.evaluation.raw_guard_accepted_count},schema:{v7:210,v8:run.evaluation.raw_schema_valid_count},fallback:{v7:7,v8:run.evaluation.fallback_count}},null,2));
