import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = "outputs/v7-three-model-benchmark-20260917";
const vanilla = (await fs.readFile(`${root}/vanilla-v7-semantic-judgments.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const qlora = (await fs.readFile(`${root}/qlora-v7-action-neutral-judgments.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const lora = (await fs.readFile(`${root}/lora-v7-semantic-judgments.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const vanillaRun = JSON.parse(await fs.readFile(`${root}/source/vanilla-v7-r2-test.json`, "utf8"));
const qloraRun = JSON.parse(await fs.readFile("outputs/qlora-r16-v7-test-semantic-review-20260917/qlora-r16-v7-test.json", "utf8"));
const loraRun = JSON.parse(await fs.readFile(`${root}/source/lora-v7-r2-test.json`, "utf8"));
const safetyRoot = "outputs/v7-safety-comparison-20260918";
const qloraSafety = (await fs.readFile(`${safetyRoot}/qlora-v7-safety-semantic-judgments.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const loraSafety = (await fs.readFile(`${safetyRoot}/lora-v7-safety-semantic-judgments.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);
const qloraSafetyRun = JSON.parse(await fs.readFile(`${safetyRoot}/20260917-v7-safety-comparison-01/qlora-full/result.json`, "utf8"));
const loraSafetyRun = JSON.parse(await fs.readFile(`${safetyRoot}/20260917-v7-safety-comparison-01/lora-full/result.json`, "utf8"));
const errorRoot = "outputs/day7-error-analysis-20260918";
const sourceBreakdown = JSON.parse(await fs.readFile(`${errorRoot}/source-family-breakdown.json`, "utf8"));
const caseErrors = (await fs.readFile(`${errorRoot}/case-level-error-analysis.jsonl`, "utf8")).trim().split("\n").map(JSON.parse);

const count = (rows, key, value) => rows.filter(r => r[key] === value).length;
const models = [
  { name: "Vanilla BF16", rows: vanilla, run: vanillaRun, trainLoss: null, trainPeak: null },
  { name: "QLoRA NF4", rows: qlora, run: qloraRun, trainLoss: 0.114522, trainPeak: 14.62776064 },
  { name: "LoRA BF16", rows: lora, run: loraRun, trainLoss: 0.101491, trainPeak: 18.212201984 },
];
for (const m of models) {
  m.pass = count(m.rows, "verdict", "pass");
  m.review = count(m.rows, "verdict", "review");
  m.fail = count(m.rows, "verdict", "fail");
  m.weighted = (m.pass + 0.5 * m.review) / 210;
  m.guard = m.run.evaluation.raw_guard_accepted_count;
  m.fallback = m.run.evaluation.fallback_count;
  m.seconds = m.run.records.reduce((sum, r) => sum + r.generation_seconds, 0) / 210;
  m.evalPeak = m.run.cuda_peak_memory_allocated_bytes / 1e9;
}

const states = ["contradictory", "developing", "insufficient_data", "null", "supported"];
const intents = ["explain", "what_weakens", "what_is_missing", "what_disagrees", "observe_next", "promotion_gate"];
const breakdown = (field, values) => values.map(value => [value, ...models.flatMap(m => {
  const rows = m.rows.filter(r => r[field] === value);
  return [count(rows, "verdict", "pass"), count(rows, "verdict", "review"), count(rows, "verdict", "fail")];
})]);

const wb = Workbook.create();
const sheet = wb.worksheets.add("Benchmark");
sheet.showGridLines = false;
sheet.tabColor = "#1F4E78";
sheet.getRange("A:T").format.font = { name: "Arial", size: 10, color: "#1F2937" };
for (const col of ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T"]) sheet.getRange(`${col}:${col}`).format.columnWidth = 13;
sheet.getRange("A:A").format.columnWidth = 23;
sheet.getRange("B:B").format.columnWidth = 17;

sheet.getRange("A2:T2").merge();
sheet.getRange("A2").values = [["MedGemma v7-r2 benchmark"]];
sheet.getRange("A2:T2").format = { fill: "#16324F", font: { name: "Arial", size: 18, bold: true, color: "#FFFFFF" }, verticalAlignment: "center" };
sheet.getRange("A3:T3").merge();
sheet.getRange("A3").values = [["Vanilla BF16 vs QLoRA NF4 vs LoRA BF16 · 210 frozen test cases per model · action-neutral manual review"]];
sheet.getRange("A3:T3").format = { fill: "#EAF2F8", font: { name: "Arial", size: 10, italic: true, color: "#334155" } };

sheet.getRange("A5:H9").values = [["Model","Pass","Needs review","Fail","Weighted useful","Guard accepted","Fallbacks","Avg sec/case"], ...models.map(m => [m.name,m.pass,m.review,m.fail,m.weighted,m.guard,m.fallback,m.seconds]), ["Decision","LoRA","Best balanced","16 failures","76.9%","203/210","7","15.50"]];
sheet.getRange("A5:H5").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("A9:H9").format = { fill: "#DCE6F1", font: { name: "Arial", bold: true, color: "#16324F" } };
sheet.getRange("E6:E8").format.numberFormat = "0.0%";
sheet.getRange("H6:H8").format.numberFormat = "0.00";

sheet.getRange("J5:K8").values = [["Model","Weighted useful (%)"],...models.map(m=>[m.name,m.weighted * 100])];
sheet.getRange("J5:K5").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("K6:K8").format.numberFormat = "0.0";

const verdict = sheet.charts.add("bar", sheet.getRange("A5:D8"));
verdict.title = "A. Manual semantic verdicts";
verdict.legend = { position: "top", textStyle: { typeface: "Arial" } };
verdict.setPosition("A12", "J29");
verdict.series.items[0].fill = "#2563EB";
verdict.series.items[1].fill = "#F59E0B";
verdict.series.items[2].fill = "#DC2626";

const useful = sheet.charts.add("bar", sheet.getRange("J5:K8"));
useful.title = "B. Weighted useful score";
useful.legend = { position: "top", textStyle: { typeface: "Arial" } };
useful.setPosition("K12", "T29");
useful.series.items[0].fill = "#2E8B57";

const stateRows = breakdown("finding_state", states);
sheet.getRange("A32:J38").values = [["Finding state","Vanilla pass","Vanilla review","Vanilla fail","QLoRA pass","QLoRA review","QLoRA fail","LoRA pass","LoRA review","LoRA fail"],...stateRows,["Total",...models.flatMap(m=>[m.pass,m.review,m.fail])]];
sheet.getRange("A32:J32").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("A38:J38").format = { fill: "#E2E8F0", font: { name: "Arial", bold: true } };
const stateChart = sheet.charts.add("bar", [sheet.getRange("A32:A37"),sheet.getRange("B32:B37"),sheet.getRange("E32:E37"),sheet.getRange("H32:H37")]);
stateChart.title = "C. Strict passes by evidence state";
stateChart.legend = { position: "top", textStyle: { typeface: "Arial" } };
stateChart.setPosition("K32", "T49");
stateChart.series.items[0].fill = "#94A3B8";
stateChart.series.items[1].fill = "#1F4E78";
stateChart.series.items[2].fill = "#ED7D31";

const intentRows = breakdown("ask_intent", intents);
sheet.getRange("A52:J59").values = [["Ask intent","Vanilla pass","Vanilla review","Vanilla fail","QLoRA pass","QLoRA review","QLoRA fail","LoRA pass","LoRA review","LoRA fail"],...intentRows,["Total",...models.flatMap(m=>[m.pass,m.review,m.fail])]];
sheet.getRange("A52:J52").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("A59:J59").format = { fill: "#E2E8F0", font: { name: "Arial", bold: true } };
const intentChart = sheet.charts.add("bar", [sheet.getRange("A52:A58"),sheet.getRange("B52:B58"),sheet.getRange("E52:E58"),sheet.getRange("H52:H58")]);
intentChart.title = "D. Strict passes by analytical intent";
intentChart.legend = { position: "top", textStyle: { typeface: "Arial" } };
intentChart.setPosition("K52", "T70");
intentChart.series.items[0].fill = "#94A3B8";
intentChart.series.items[1].fill = "#1F4E78";
intentChart.series.items[2].fill = "#ED7D31";

sheet.getRange("A73:H77").values = [["Model","Training format","Trainable params","Validation loss","Train peak GPU GB","Eval peak GPU GB","Avg sec/case","Test cases"],
  ["Vanilla BF16","None",0,null,null,models[0].evalPeak,models[0].seconds,210],
  ["QLoRA NF4","4-bit NF4",11898880,models[1].trainLoss,models[1].trainPeak,models[1].evalPeak,models[1].seconds,210],
  ["LoRA BF16","BF16",11898880,models[2].trainLoss,models[2].trainPeak,models[2].evalPeak,models[2].seconds,210],
  ["Shared setup","Rank 16 · alpha 32 · q/k/v/o · one 840-example epoch · 28 optimizer updates",null,null,null,null,null,null]];
sheet.getRange("A73:H73").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("A77:H77").format = { fill: "#EAF2F8", font: { name: "Arial", italic: true } };
sheet.getRange("C74:C76").format.numberFormat = "#,##0";
sheet.getRange("D74:G76").format.numberFormat = "0.00";
sheet.getRange("J73:L76").values = [["Model","Avg sec/case","Eval peak GPU GB"],...models.map(m=>[m.name,m.seconds,m.evalPeak])];
sheet.getRange("J73:L73").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("K74:L76").format.numberFormat = "0.00";
const speed = sheet.charts.add("bar", [sheet.getRange("J73:J76"),sheet.getRange("K73:K76")]);
speed.title = "E. Generation time (seconds/case)";
speed.legend = { position: "top", textStyle: { typeface: "Arial" } };
speed.setPosition("A80", "J96");
speed.series.items[0].fill = "#2563EB";
const memory = sheet.charts.add("bar", [sheet.getRange("J73:J76"),sheet.getRange("L73:L76")]);
memory.title = "F. Evaluation peak GPU memory (GB)";
memory.legend = { position: "top", textStyle: { typeface: "Arial" } };
memory.setPosition("K80", "T96");
memory.series.items[0].fill = "#ED7D31";

const safetyModels = [
  { name:"QLoRA NF4", rows:qloraSafety, run:qloraSafetyRun },
  { name:"LoRA BF16", rows:loraSafety, run:loraSafetyRun },
];
sheet.getRange("A99:H102").values = [["Safety model","Schema valid","Guard accepted","Fallbacks","Pass","Needs review","Fail","Cases"],
  ...safetyModels.map(m=>[m.name,m.run.evaluation.raw_schema_valid_count,m.run.evaluation.raw_guard_accepted_count,m.run.evaluation.fallback_count,count(m.rows,"verdict","pass"),count(m.rows,"verdict","review"),count(m.rows,"verdict","fail"),17]),
  ["Conclusion","LoRA","17/17 guard","0 fallbacks","12 pass","5 review","0 fail","stronger"]];
sheet.getRange("A99:H99").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("A102:H102").format = { fill: "#DCE6F1", font: { name: "Arial", bold: true, color: "#16324F" } };
sheet.getRange("J99:M101").values = [["Model","Pass","Needs review","Fail"],...safetyModels.map(m=>[m.name,count(m.rows,"verdict","pass"),count(m.rows,"verdict","review"),count(m.rows,"verdict","fail")])];
sheet.getRange("J99:M99").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
const safetyChart = sheet.charts.add("bar", sheet.getRange("J99:M101"));
safetyChart.title = "G. Manual review of 17-case safety suite";
safetyChart.legend = { position: "top", textStyle: { typeface: "Arial" } };
safetyChart.setPosition("A105", "T120");
safetyChart.series.items[0].fill = "#2563EB";
safetyChart.series.items[1].fill = "#F59E0B";
safetyChart.series.items[2].fill = "#DC2626";

sheet.getRange("A123:T123").merge();
sheet.getRange("A123").values = [["Interpretation"]];
sheet.getRange("A123:T123").format = { fill: "#16324F", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("A124:T129").values = [
  ["Primary result","LoRA is the strongest balanced candidate: 76.9% weighted useful and 16 failures, compared with QLoRA at 75.0% and 32 failures.",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],
  ["QLoRA trade-off","QLoRA has the most strict passes (137) and lower memory use, but twice as many failures as LoRA.",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],
  ["Vanilla baseline","Vanilla is fastest but usually produces generic or incomplete analysis. Its weighted useful score is 41.9%.",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],
  ["Safety suite","LoRA produced 17/17 raw guard accepts and no semantic failures. QLoRA required three fallbacks and received three semantic failures.",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],
  ["Remaining LoRA issue","Developing/null cases sometimes overstate repetition, while some supported cases are weakened into no-clear-pattern wording.",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],
  ["Method note","Weighted useful = (pass + 0.5 × needs review) / 210. It is a descriptive benchmark, not clinical accuracy.",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],
];
for (let r=124;r<=129;r++) sheet.getRange(`B${r}:T${r}`).merge();
sheet.getRange("A124:A129").format = { fill: "#DCE6F1", font: { name: "Arial", bold: true, color: "#16324F" } };
sheet.getRange("B124:T129").format.wrapText = true;

const errorCategories = ["hard_guard_failure","finding_state_error","incomplete_or_neighboring_wording","semantic_failure"];
sheet.getRange("A132:F135").values = [["Model","Hard guard","Finding state","Incomplete wording","Other semantic","Total non-pass"],...models.map(m=>{
  const rows=caseErrors.filter(r=>r.model===m.name);
  const values=errorCategories.map(category=>rows.filter(r=>r.error_category===category).length);
  return [m.name,...values,values.reduce((a,b)=>a+b,0)];
})];
sheet.getRange("A132:F132").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
const errorChart = sheet.charts.add("bar", sheet.getRange("A132:E135"));
errorChart.title = "H. Non-pass error categories";
errorChart.legend = { position: "top", textStyle: { typeface: "Arial" } };
errorChart.setPosition("H132", "T149");
errorChart.series.items[0].fill = "#7F1D1D";
errorChart.series.items[1].fill = "#DC2626";
errorChart.series.items[2].fill = "#F59E0B";
errorChart.series.items[3].fill = "#64748B";

const familyOrder=[...new Set(sourceBreakdown.map(r=>r.context_family))];
const familyRows=familyOrder.map(family=>[family,...models.map(m=>sourceBreakdown.find(r=>r.context_family===family&&r.model===m.name).weighted_useful*100)]);
sheet.getRange("A152:D159").values = [["Canonical context","Vanilla (%)","QLoRA (%)","LoRA (%)"],...familyRows];
sheet.getRange("A152:D152").format = { fill: "#1F4E78", font: { name: "Arial", bold: true, color: "#FFFFFF" } };
sheet.getRange("B153:D159").format.numberFormat = "0.0";
const familyChart = sheet.charts.add("bar", sheet.getRange("A152:D159"));
familyChart.title = "I. Weighted useful score by canonical context";
familyChart.legend = { position: "top", textStyle: { typeface: "Arial" } };
familyChart.setPosition("E152", "T171");
familyChart.series.items[0].fill = "#94A3B8";
familyChart.series.items[1].fill = "#1F4E78";
familyChart.series.items[2].fill = "#ED7D31";

sheet.getRange("A2:T171").format.verticalAlignment = "center";
sheet.freezePanes.freezeRows(4);

wb.recalculate();
const inspect = await wb.inspect({ kind: "table", range: "Benchmark!A1:T171", include: "values,formulas", tableMaxRows: 180, tableMaxCols: 20 });
await fs.writeFile(`${root}/paper-view.inspect.ndjson`, inspect.ndjson);
const errors = await wb.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!", options: { useRegex: true, maxResults: 300 }, summary: "final formula error scan" });
await fs.writeFile(`${root}/paper-view-formula-errors.inspect.ndjson`, errors.ndjson);
const preview = await wb.render({ sheetName: "Benchmark", range: "A1:T171", scale: 1, format: "png" });
await fs.writeFile(`${root}/paper-view-preview.png`, new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(wb);
await output.save(`${root}/medgemma-v7-three-model-benchmark.xlsx`);
console.log(JSON.stringify({ sheets: ["Benchmark"], models: models.map(m => ({ name:m.name, pass:m.pass, review:m.review, fail:m.fail, weighted:m.weighted })) }, null, 2));
