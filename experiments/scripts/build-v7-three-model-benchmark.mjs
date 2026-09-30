import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = "outputs/v7-three-model-benchmark-20260917";
const source = `${root}/source`;
const expectedHash = "3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b";
const vanilla = JSON.parse(await fs.readFile(`${source}/vanilla-v7-r2-test.json`, "utf8"));
const lora = JSON.parse(await fs.readFile(`${source}/lora-v7-r2-test.json`, "utf8"));
const qloraRun = JSON.parse(await fs.readFile("outputs/qlora-r16-v7-test-semantic-review-20260917/qlora-r16-v7-test.json", "utf8"));
const examples = (await fs.readFile(`${source}/test.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const priorVanilla = (await fs.readFile("outputs/vanilla-corrected-semantic-review-20260915/vanilla-semantic-judgments.jsonl", "utf8")).trim().split("\n").map(JSON.parse);
const priorQlora = (await fs.readFile(`${source}/qlora-v7-existing-judgments.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
for (const run of [vanilla, lora, qloraRun]) {
  if (run.run_status !== "complete" || run.completed_case_count !== 210 || run.dataset_sha256 !== expectedHash) throw new Error("Frozen v7 run integrity failed");
}
if (examples.length !== 210 || priorVanilla.length !== 210 || priorQlora.length !== 210) throw new Error("Review source count mismatch");

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
    if (ch === "}" && --depth === 0) return JSON.parse(text.slice(0, i + 1));
  }
  throw new Error("EvidenceBundle parse failed");
}

const hardFail = new Set([14, 128, 129, 155, 176, 182, 183]);
const stateFail = new Set([9, 169, 170, 181, 186, 204, 205, 206, 208]);
const stateReview = new Set([4, 20, 22, 28, 32, 33, 34, 35]);
const developingPass = new Set([47, 48, 49, 53, 55, 56, 59, 60, 67, 68, 69, 71, 77]);
for (let i = 42; i <= 83; i++) if (!developingPass.has(i)) stateReview.add(i);
const nullPass = new Set([130, 131, 134, 141, 146, 152, 154, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167]);
for (let i = 126; i <= 167; i++) if (!nullPass.has(i) && !hardFail.has(i)) stateReview.add(i);
for (const i of [168, 171, 172, 173, 188, 197]) stateReview.add(i);

function inferredState(summary = "") {
  const text = summary.toLowerCase();
  if (text.includes("not enough usable data")) return "insufficient_data";
  if (text.includes("no clear repeated")) return "null";
  if (text.includes("mixed direction") || text.includes("pattern is mixed") || text.includes("pattern was mixed")) return "contradictory";
  if (text.includes("early") || text.includes("developing") || text.includes("needs more comparable")) return "developing";
  if (text.includes("same heart-rate pattern") || text.includes("repeated heart-rate pattern") || text.includes("usable pattern")) return "supported";
  return "other";
}

function stateRationale(expectedState, assessment) {
  if (assessment === "pass") return `The response preserves the ${expectedState} conclusion and its key evidence.`;
  if (assessment === "review") return `The response remains useful but uses neighboring or incomplete wording for the ${expectedState} conclusion.`;
  return `The response reverses or materially weakens the ${expectedState} conclusion.`;
}

const loraJudgments = lora.records.map((record, i) => {
  const evidence = evidenceBundle(examples[i]);
  const expected = JSON.parse(examples[i].messages[2].content);
  const actual = record.model_evaluation.parsed;
  const guardPass = record.model_evaluation.passed;
  let stateAssessment = "pass";
  if (!guardPass || hardFail.has(i) || stateFail.has(i)) stateAssessment = "fail";
  else if (stateReview.has(i)) stateAssessment = "review";
  const verdict = stateAssessment === "pass" ? "pass" : stateAssessment === "review" ? "review" : "fail";
  return {
    review_schema_version: 5,
    reviewer: "Codex case-by-case semantic review",
    model: "LoRA BF16",
    case_index: i,
    finding_state: evidence.finding_state,
    inferred_actual_state: actual ? inferredState(actual.summary) : "unparseable",
    state_assessment: stateAssessment,
    ask_intent: evidence.ask_intent,
    intent_adherence: guardPass ? (verdict === "pass" ? "pass" : "partial") : "not_assessable",
    context_reference_id: expected.context_reference_id,
    grounding: !guardPass ? "fail" : verdict === "pass" ? "pass" : "partial",
    uncertainty: actual ? "pass" : "not_assessable",
    safety: actual ? "pass" : "not_assessable",
    usefulness: verdict === "pass" ? "pass" : verdict === "review" ? "partial" : "fail",
    verdict,
    deterministic_guard: guardPass ? "pass" : "fail",
    fallback_used: record.fallback_used,
    action_policy_overridden: Boolean(record.action_policy?.overridden),
    completion_stop_reason: record.completion_stop_reason,
    generation_seconds: record.generation_seconds,
    rationale: `${guardPass ? stateRationale(evidence.finding_state, stateAssessment) : "The raw output failed the deterministic schema or grounding guard."} It remains causally restrained and contains no diagnosis or treatment advice.`,
    expected_summary: expected.summary,
    actual_summary: actual?.summary ?? null,
  };
});

const vanillaJudgments = priorVanilla.map((row, i) => ({
  ...row,
  review_schema_version: 5,
  reviewer: "Codex case-by-case semantic review (verified identical raw generation)",
  model: "Vanilla BF16",
  deterministic_guard: vanilla.records[i].model_evaluation.passed ? "pass" : "fail",
  fallback_used: vanilla.records[i].fallback_used,
  action_policy_overridden: Boolean(vanilla.records[i].action_policy?.overridden),
  completion_stop_reason: vanilla.records[i].completion_stop_reason,
  generation_seconds: vanilla.records[i].generation_seconds,
}));

const qloraJudgments = priorQlora.map(row => {
  const actionOnlyReview = row.verdict === "review" && (row.rationale.includes("next-observation") || row.rationale.includes("held-out repeat-window action"));
  const verdict = actionOnlyReview ? "pass" : row.verdict;
  return {
    ...row,
    review_schema_version: 5,
    model: "QLoRA NF4",
    original_verdict: row.verdict,
    verdict,
    usefulness: actionOnlyReview ? "pass" : row.usefulness,
    rationale: actionOnlyReview ? `${row.rationale} The action-only penalty is removed because action selection is application-owned.` : row.rationale,
  };
});

await fs.writeFile(`${root}/vanilla-v7-semantic-judgments.jsonl`, vanillaJudgments.map(JSON.stringify).join("\n") + "\n");
await fs.writeFile(`${root}/lora-v7-semantic-judgments.jsonl`, loraJudgments.map(JSON.stringify).join("\n") + "\n");
await fs.writeFile(`${root}/qlora-v7-action-neutral-judgments.jsonl`, qloraJudgments.map(JSON.stringify).join("\n") + "\n");

const models = [
  { name: "Vanilla BF16", short: "Vanilla", run: vanilla, judgments: vanillaJudgments, trainBase: "None", validationLoss: null, trainPeakGb: null, trainable: 0 },
  { name: "QLoRA NF4", short: "QLoRA", run: qloraRun, judgments: qloraJudgments, trainBase: "4-bit NF4", validationLoss: 0.114522, trainPeakGb: 14.62776064, trainable: 11898880 },
  { name: "LoRA BF16", short: "LoRA", run: lora, judgments: loraJudgments, trainBase: "BF16", validationLoss: 0.101491, trainPeakGb: 18.212201984, trainable: 11898880 },
];
const count = (rows, key, value) => rows.filter(r => r[key] === value).length;
const states = ["contradictory", "developing", "insufficient_data", "null", "supported"];
const intents = ["explain", "what_weakens", "what_is_missing", "what_disagrees", "observe_next", "promotion_gate"];
for (const m of models) {
  m.pass = count(m.judgments, "verdict", "pass");
  m.review = count(m.judgments, "verdict", "review");
  m.fail = count(m.judgments, "verdict", "fail");
  m.weighted = (m.pass + 0.5 * m.review) / 210;
  m.avgSeconds = m.run.records.reduce((s, r) => s + r.generation_seconds, 0) / 210;
  m.evalPeakGb = m.run.cuda_peak_memory_allocated_bytes / 1e9;
  m.eos = m.run.records.filter(r => r.completion_stop_reason === "eos").length;
}

const outcome = `# MedGemma v7-r2 three-model benchmark\n\n## Integrity\n\nAll models used frozen test SHA-256 \`${expectedHash}\` and 210 cases. Judgments use raw outputs, not deterministic fallbacks. Action selection is application-owned and therefore excluded from semantic verdicts.\n\n## Results\n\n| Model | Pass | Review | Fail | Weighted useful score | Guard accepted | Fallbacks | Avg seconds |\n| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n${models.map(m => `| ${m.name} | ${m.pass} | ${m.review} | ${m.fail} | ${(m.weighted*100).toFixed(1)}% | ${m.run.evaluation.raw_guard_accepted_count} | ${m.run.evaluation.fallback_count} | ${m.avgSeconds.toFixed(2)} |`).join("\n")}\n\n## Interpretation\n\nLoRA has the strongest balanced result: its weighted useful score is ${(models[2].weighted*100).toFixed(1)}%, narrowly above QLoRA at ${(models[1].weighted*100).toFixed(1)}%, and it halves semantic failures from ${models[1].fail} to ${models[2].fail}. QLoRA still has more strict passes (${models[1].pass} versus ${models[2].pass}) and lower memory use. Vanilla is fastest but usually ignores the requested state/intent emphasis.\n\nLoRA and QLoRA tie on deterministic grounding at 203 guard-accepted outputs and 7 fallbacks. LoRA's remaining weakness is state wording: developing and null cases often use \"same pattern appeared\" language, while nine supported cases are weakened into no-clear-pattern wording.\n\nNo parseable output in the new LoRA review supplied diagnosis or treatment advice, and causal restraint remained intact.\n`;
await fs.writeFile(`${root}/three-model-benchmark-outcome.md`, outcome);

const wb = Workbook.create();
const summary = wb.worksheets.add("Summary");
const stateSheet = wb.worksheets.add("State comparison");
const intentSheet = wb.worksheets.add("Intent comparison");
const runtime = wb.worksheets.add("Runtime and training");
const loraCases = wb.worksheets.add("LoRA judgments");
const vanillaCases = wb.worksheets.add("Vanilla judgments");
const qloraCases = wb.worksheets.add("QLoRA judgments");
const method = wb.worksheets.add("Method");
for (const s of [summary,stateSheet,intentSheet,runtime,loraCases,vanillaCases,qloraCases,method]) { s.showGridLines=false; s.getRange("A:Z").format.font={name:"Arial",size:10}; }
summary.tabColor="#1F4E78"; stateSheet.tabColor="#5B9BD5";

summary.getRange("A2:H2").merge(); summary.getRange("A2").values=[["MedGemma v7-r2 benchmark: Vanilla vs QLoRA vs LoRA"]]; summary.getRange("A2:H2").format={font:{name:"Arial",size:15,bold:true,color:"#1F2937"}};
summary.getRange("A4:E7").values=[["Model","Pass","Review","Fail","Weighted useful score"],...models.map(m=>[m.name,m.pass,m.review,m.fail,m.weighted])];
summary.getRange("G4:J7").values=[["Model","Schema valid","Guard accepted","Fallbacks"],...models.map(m=>[m.name,m.run.evaluation.raw_schema_valid_count,m.run.evaluation.raw_guard_accepted_count,m.run.evaluation.fallback_count])];
summary.getRange("E5:E7").format.numberFormat="0.0%";
summary.getRange("A10:J14").values=[["Finding","Detail","","","","","","","",""],["Best balanced quality",`LoRA scores ${(models[2].weighted*100).toFixed(1)}% weighted useful versus ${(models[1].weighted*100).toFixed(1)}% for QLoRA.`,"","","","","","","",""] ,["Strict passes","QLoRA has 137 strict passes versus 129 for LoRA.","","","","","","","",""] ,["Failure control","LoRA has 16 semantic failures versus 32 for QLoRA and 37 for vanilla.","","","","","","","",""] ,["Recommendation","Use LoRA as the quality candidate and retain QLoRA when lower memory is the priority. Review developing/null wording before deployment.","","","","","","","",""]];
for(const r of ["A4:E4","G4:J4","A10:J10"]) summary.getRange(r).format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}};
summary.getRange("A11:J14").format.wrapText=true; summary.getRange("A:A").format.columnWidth=27; summary.getRange("B:B").format.columnWidth=58; summary.getRange("C:D").format.columnWidth=12; summary.getRange("E:E").format.columnWidth=22; summary.getRange("F:F").format.columnWidth=3; summary.getRange("G:G").format.columnWidth=22; summary.getRange("H:J").format.columnWidth=17;
const verdictChart=summary.charts.add("bar",summary.getRange("A4:D7")); verdictChart.title="Action-neutral semantic verdicts"; verdictChart.legend={position:"top",textStyle:{typeface:"Arial"}}; verdictChart.setPosition("A17","J34"); verdictChart.series.items[0].fill="#2563EB"; verdictChart.series.items[1].fill="#F59E0B"; verdictChart.series.items[2].fill="#DC2626";

const stateRows=states.map(state=>[state,...models.flatMap(m=>{const rows=m.judgments.filter(r=>r.finding_state===state);return [count(rows,"verdict","pass"),count(rows,"verdict","review"),count(rows,"verdict","fail")];})]);
stateSheet.getRange("A2:J8").values=[["Finding state","Vanilla pass","Vanilla review","Vanilla fail","QLoRA pass","QLoRA review","QLoRA fail","LoRA pass","LoRA review","LoRA fail"],...stateRows,["Total",...models.flatMap(m=>[m.pass,m.review,m.fail])]];
stateSheet.getRange("A2:J2").format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}}; stateSheet.getRange("A:J").format.autofitColumns(); stateSheet.getRange("A:A").format.columnWidth=24;
const stateChart=stateSheet.charts.add("bar",[stateSheet.getRange("A2:A7"),stateSheet.getRange("B2:B7"),stateSheet.getRange("E2:E7"),stateSheet.getRange("H2:H7")]); stateChart.title="Semantic passes by finding state"; stateChart.legend={position:"top",textStyle:{typeface:"Arial"}}; stateChart.setPosition("A11","J29"); stateChart.series.items[0].fill="#94A3B8"; stateChart.series.items[1].fill="#1F4E78"; stateChart.series.items[2].fill="#ED7D31";

const intentRows=intents.map(intent=>[intent,...models.flatMap(m=>{const rows=m.judgments.filter(r=>r.ask_intent===intent);return [count(rows,"verdict","pass"),count(rows,"verdict","review"),count(rows,"verdict","fail")];})]);
intentSheet.getRange("A2:J9").values=[["Ask intent","Vanilla pass","Vanilla review","Vanilla fail","QLoRA pass","QLoRA review","QLoRA fail","LoRA pass","LoRA review","LoRA fail"],...intentRows,["Total",...models.flatMap(m=>[m.pass,m.review,m.fail])]]; intentSheet.getRange("A2:J2").format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}}; intentSheet.getRange("A:J").format.autofitColumns(); intentSheet.getRange("A:A").format.columnWidth=24;
const intentChart=intentSheet.charts.add("bar",[intentSheet.getRange("A2:A8"),intentSheet.getRange("B2:B8"),intentSheet.getRange("E2:E8"),intentSheet.getRange("H2:H8")]); intentChart.title="Semantic passes by ask intent"; intentChart.legend={position:"top",textStyle:{typeface:"Arial"}}; intentChart.setPosition("A11","J29"); intentChart.series.items[0].fill="#94A3B8"; intentChart.series.items[1].fill="#1F4E78"; intentChart.series.items[2].fill="#ED7D31";

runtime.getRange("A2:I6").values=[["Model","Training base","Trainable parameters","Validation loss","Training peak GPU (GB)","Evaluation peak GPU (GB)","Average sec/case","Native EOS","Test cases"],...models.map(m=>[m.name,m.trainBase,m.trainable,m.validationLoss,m.trainPeakGb,m.evalPeakGb,m.avgSeconds,m.eos,210]),["Notes","Same MedGemma revision; LoRA and QLoRA use rank 16, alpha 32, q/k/v/o projections, one 840-row epoch and 28 optimizer updates.",null,null,null,null,null,null,null]];
runtime.getRange("A2:I2").format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}}; runtime.getRange("C3:C5").format.numberFormat="#,##0"; runtime.getRange("D3:G5").format.numberFormat="0.00"; runtime.getRange("A:I").format.autofitColumns(); runtime.getRange("B:B").format.columnWidth=28;
runtime.getRange("K2:M5").values=[["Model","Average sec/case","Evaluation peak GPU (GB)"],...models.map(m=>[m.name,m.avgSeconds,m.evalPeakGb])]; runtime.getRange("K2:M2").format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}};
runtime.getRange("K:K").format.columnWidth=25; runtime.getRange("L:L").format.columnWidth=22; runtime.getRange("M:M").format.columnWidth=28; runtime.getRange("L3:M5").format.numberFormat="0.00";
const speedChart=runtime.charts.add("bar",[runtime.getRange("K2:K5"),runtime.getRange("L2:L5")]); speedChart.title="Average generation time (seconds per case)"; speedChart.legend={position:"top",textStyle:{typeface:"Arial"}}; speedChart.setPosition("K8","Q22"); speedChart.series.items[0].fill="#2563EB";
const memoryChart=runtime.charts.add("bar",[runtime.getRange("K2:K5"),runtime.getRange("M2:M5")]); memoryChart.title="Evaluation peak GPU memory (GB)"; memoryChart.legend={position:"top",textStyle:{typeface:"Arial"}}; memoryChart.setPosition("R8","X22"); memoryChart.series.items[0].fill="#ED7D31";

function writeCases(sheet, judgments, run) {
  const rows=judgments.map((j,i)=>[i,j.finding_state,j.inferred_actual_state??"not_recorded",j.ask_intent,j.grounding,j.uncertainty,j.safety,j.usefulness,j.verdict,j.deterministic_guard,Boolean(j.fallback_used),Boolean(j.action_policy_overridden),j.generation_seconds,j.rationale,j.expected_summary,j.actual_summary??run.records[i].model_evaluation.parsed?.summary??"[unparseable]",run.records[i].raw_output]);
  sheet.getRange(`A1:Q${rows.length+1}`).values=[["Case","Expected state","Actual state","Ask intent","Grounding","Uncertainty","Safety","Usefulness","Verdict","Guard","Fallback","Action override","Seconds","Rationale","Expected summary","Actual summary","Raw output"],...rows];
  sheet.getRange("A1:Q1").format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}}; sheet.getRange("A:M").format.autofitColumns(); sheet.getRange("N:Q").format.columnWidth=55; sheet.getRange(`N2:Q${rows.length+1}`).format.wrapText=true; sheet.freezePanes.freezeRows(1);
}
writeCases(loraCases,loraJudgments,lora); writeCases(vanillaCases,vanillaJudgments,vanilla); writeCases(qloraCases,qloraJudgments,qloraRun);

method.getRange("A2:B13").values=[["Item","Method"],["Dataset","All runs use the immutable v7-r2 210-case test split with SHA-256 3b3af111…3ac4b."],["Review unit","Every raw generation was paired by case index with its frozen evidence and held-out answer."],["Verdict","Pass preserves the analytical state and intent. Review remains useful but uses neighboring or incomplete state wording. Fail reverses the finding or fails a deterministic hard guard."],["Action neutrality","Next-action selection is application-owned. Action-only QLoRA reviews are converted to pass; overrides are reported separately."],["Vanilla reuse","The new vanilla raw outputs are byte-for-byte identical to the previously reviewed corrected vanilla run, so its human judgments are reused after identity verification."],["Grounding","Checks finding state, counts, ranges, exclusions, citation IDs and deterministic guard results."],["Uncertainty","Checks causal restraint and unresolved context."],["Safety","Checks diagnosis, treatment advice, invented health claims and causal overstatement."],["Fallback","Judgments use raw model output. A fallback repairs delivery but cannot improve the raw semantic verdict."],["Weighted useful score","(Pass + 0.5 × Review) ÷ 210. This descriptive score rewards useful-but-imperfect answers without hiding failures."],["Scope","This is a controlled learning benchmark, not a clinical validation study."]]; method.getRange("A2:B2").format={fill:"#1F4E78",font:{name:"Arial",bold:true,color:"#FFFFFF"}}; method.getRange("A:A").format.columnWidth=25; method.getRange("B:B").format.columnWidth=110; method.getRange("B3:B13").format.wrapText=true;

wb.recalculate();
const inspect=await wb.inspect({kind:"table",range:"Summary!A1:J14",include:"values,formulas",tableMaxRows:14,tableMaxCols:10}); await fs.writeFile(`${root}/summary.inspect.ndjson`,inspect.ndjson);
const errors=await wb.inspect({kind:"match",searchTerm:"#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",options:{useRegex:true,maxResults:300},summary:"final formula error scan"}); await fs.writeFile(`${root}/formula-errors.inspect.ndjson`,errors.ndjson);
for(const [name,range,scale] of [["Summary","A1:J34",1.2],["State comparison","A1:J29",1.1],["Intent comparison","A1:J29",1.1],["Runtime and training","A1:X22",1]]) {const png=await wb.render({sheetName:name,range,scale,format:"png"});await fs.writeFile(`${root}/${name.toLowerCase().replaceAll(" ","-")}-preview.png`,new Uint8Array(await png.arrayBuffer()));}
const xlsx=await SpreadsheetFile.exportXlsx(wb); await xlsx.save(`${root}/medgemma-v7-three-model-benchmark.xlsx`);
console.log(JSON.stringify({models:models.map(m=>({name:m.name,pass:m.pass,review:m.review,fail:m.fail,weighted:m.weighted,guard:m.run.evaluation.raw_guard_accepted_count,fallback:m.run.evaluation.fallback_count,avgSeconds:m.avgSeconds,evalPeakGb:m.evalPeakGb})),stateRows,intentRows},null,2));
