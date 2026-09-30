import fs from "node:fs/promises";

const root = "outputs/v7-three-model-benchmark-20260917/source";
const vanilla = JSON.parse(await fs.readFile(`${root}/vanilla-v7-r2-test.json`, "utf8"));
const lora = JSON.parse(await fs.readFile(`${root}/lora-v7-r2-test.json`, "utf8"));
const examples = (await fs.readFile(`${root}/test.jsonl`, "utf8"))
  .trim().split("\n").map(JSON.parse);

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

const clean = value => String(value ?? "").replaceAll("\t", " ").replaceAll("\n", " ");
const header = ["model","case","state","intent","guard","fallback","errors","expected_summary","expected_answer","actual_summary","actual_answer","uncertainty","raw_output"];
const rows = [header.join("\t")];
for (const [modelName, run] of [["vanilla", vanilla], ["lora", lora]]) {
  for (let i = 0; i < 210; i++) {
    const evidence = evidenceBundle(examples[i]);
    const expected = JSON.parse(examples[i].messages[2].content);
    const record = run.records[i];
    const actual = record.model_evaluation.parsed;
    rows.push([
      modelName, i, evidence.finding_state, evidence.ask_intent,
      record.model_evaluation.passed, record.fallback_used,
      record.model_evaluation.errors.join("; "), expected.summary,
      expected.paragraphs.map(p => p.text).join(" "), actual?.summary ?? "[unparseable]",
      actual?.paragraphs.map(p => p.text).join(" ") ?? "[unparseable]",
      actual?.uncertainty ?? "[unparseable]", record.raw_output,
    ].map(clean).join("\t"));
  }
}
await fs.writeFile("outputs/v7-three-model-benchmark-20260917/manual-review-input.tsv", rows.join("\n") + "\n");
console.log(JSON.stringify({vanilla: vanilla.evaluation, lora: lora.evaluation, rows: rows.length - 1}, null, 2));
