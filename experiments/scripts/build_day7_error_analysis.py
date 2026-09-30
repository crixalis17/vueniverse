"""Build the Day 7 case-paired error analysis for the frozen v7 benchmark."""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path("outputs/v7-three-model-benchmark-20260917")
OUT = Path("outputs/day7-error-analysis-20260918")
OUT.mkdir(parents=True, exist_ok=True)


def read_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def evidence(messages: list[dict]) -> dict:
    text = messages[1]["content"].split("EvidenceBundle:\n", 1)[1]
    return json.JSONDecoder().raw_decode(text)[0]


examples = read_jsonl(ROOT / "source/test.jsonl")
bundles = [evidence(row["messages"]) for row in examples]
judgments = {
    "Vanilla BF16": read_jsonl(ROOT / "vanilla-v7-semantic-judgments.jsonl"),
    "QLoRA NF4": read_jsonl(ROOT / "qlora-v7-action-neutral-judgments.jsonl"),
    "LoRA BF16": read_jsonl(ROOT / "lora-v7-semantic-judgments.jsonl"),
}
runs = {
    "Vanilla BF16": json.loads((ROOT / "source/vanilla-v7-r2-test.json").read_text()),
    "QLoRA NF4": json.loads(Path("outputs/qlora-r16-v7-test-semantic-review-20260917/qlora-r16-v7-test.json").read_text()),
    "LoRA BF16": json.loads((ROOT / "source/lora-v7-r2-test.json").read_text()),
}


def score(verdict: str) -> int:
    return {"fail": 0, "review": 1, "pass": 2}[verdict]


def raw_summary(record: dict) -> str:
    parsed = record["model_evaluation"].get("parsed")
    return parsed.get("summary", "") if isinstance(parsed, dict) else ""


def normalized_template(text: str) -> str:
    text = text.lower()
    text = re.sub(r"ctx_[a-f0-9]+", "<context>", text)
    text = re.sub(r"[+-]?\d+(?:\.\d+)?%?", "<n>", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def category(row: dict) -> str:
    if row["verdict"] == "pass":
        return "pass"
    if row.get("deterministic_guard") == "fail":
        return "hard_guard_failure"
    rationale = row.get("rationale", "").lower()
    if "reverses" in rationale or "materially weakens" in rationale:
        return "finding_state_error"
    if row["verdict"] == "review":
        return "incomplete_or_neighboring_wording"
    return "semantic_failure"


case_rows = []
for i, bundle in enumerate(bundles):
    base = {
        "case_index": i,
        "context_family": bundle["context_reference"]["context_family"],
        "context_reference_id": bundle["context_reference"]["context_reference_id"],
        "finding_state": bundle["finding_state"],
        "ask_intent": bundle["ask_intent"],
    }
    for model, rows in judgments.items():
        row = rows[i]
        case_rows.append(
            {
                **base,
                "model": model,
                "verdict": row["verdict"],
                "error_category": category(row),
                "deterministic_guard": row.get("deterministic_guard"),
                "fallback_used": bool(row.get("fallback_used")),
                "rationale": row.get("rationale", ""),
            }
        )

(OUT / "case-level-error-analysis.jsonl").write_text(
    "".join(json.dumps(row) + "\n" for row in case_rows), encoding="utf-8"
)

source_rows = []
families = sorted({bundle["context_reference"]["context_family"] for bundle in bundles})
for family in families:
    indexes = [i for i, bundle in enumerate(bundles) if bundle["context_reference"]["context_family"] == family]
    for model, rows in judgments.items():
        subset = [rows[i] for i in indexes]
        source_rows.append(
            {
                "context_family": family,
                "model": model,
                "cases": len(subset),
                "pass": sum(r["verdict"] == "pass" for r in subset),
                "review": sum(r["verdict"] == "review" for r in subset),
                "fail": sum(r["verdict"] == "fail" for r in subset),
                "weighted_useful": (sum(r["verdict"] == "pass" for r in subset) + 0.5 * sum(r["verdict"] == "review" for r in subset)) / len(subset),
            }
        )
(OUT / "source-family-breakdown.json").write_text(json.dumps(source_rows, indent=2) + "\n")

pairwise = []
for left, right in (("Vanilla BF16", "QLoRA NF4"), ("Vanilla BF16", "LoRA BF16"), ("QLoRA NF4", "LoRA BF16")):
    improved, regressed, tied = [], [], []
    for i in range(210):
        delta = score(judgments[right][i]["verdict"]) - score(judgments[left][i]["verdict"])
        target = improved if delta > 0 else regressed if delta < 0 else tied
        target.append(i)
    pairwise.append({"from": left, "to": right, "improved": improved, "regressed": regressed, "tied": tied})
(OUT / "pairwise-case-movements.json").write_text(json.dumps(pairwise, indent=2) + "\n")

style = []
for model, run in runs.items():
    summaries = [raw_summary(record) for record in run["records"] if raw_summary(record)]
    templates = Counter(normalized_template(summary) for summary in summaries)
    exact = Counter(summaries)
    all_text = "\n".join(record.get("raw_output", "") for record in run["records"]).lower()
    style.append(
        {
            "model": model,
            "parseable_summaries": len(summaries),
            "unique_exact_summaries": len(exact),
            "unique_normalized_templates": len(templates),
            "largest_template_count": templates.most_common(1)[0][1] if templates else 0,
            "largest_template_share": templates.most_common(1)[0][1] / len(summaries) if templates else 0,
            "diagnosis_or_treatment_mentions": len(re.findall(r"\b(?:diagnos\w*|treatment|medicine|medication)\b", all_text)),
            "causal_overstatement_mentions": len(re.findall(r"\b(?:caused|proves?|the reason)\b", all_text)),
        }
    )
(OUT / "style-and-safety-diagnostics.json").write_text(json.dumps(style, indent=2) + "\n")

category_counts = {
    model: dict(Counter(category(row) for row in rows)) for model, rows in judgments.items()
}
lines = [
    "# Day 7 v7 error analysis",
    "",
    "## Pairwise movement",
    "",
    "| Comparison | Improved | Regressed | Tied |",
    "| --- | ---: | ---: | ---: |",
]
for item in pairwise:
    lines.append(f"| {item['from']} → {item['to']} | {len(item['improved'])} | {len(item['regressed'])} | {len(item['tied'])} |")
lines += ["", "## Error categories", "", "| Model | Pass | Incomplete/neighboring | Finding-state error | Hard guard | Other semantic |", "| --- | ---: | ---: | ---: | ---: | ---: |"]
for model in judgments:
    counts = category_counts[model]
    lines.append(f"| {model} | {counts.get('pass',0)} | {counts.get('incomplete_or_neighboring_wording',0)} | {counts.get('finding_state_error',0)} | {counts.get('hard_guard_failure',0)} | {counts.get('semantic_failure',0)} |")
lines += ["", "## Canonical-source weighted useful score", "", "| Context family | Vanilla | QLoRA | LoRA |", "| --- | ---: | ---: | ---: |"]
by_family = defaultdict(dict)
for row in source_rows:
    by_family[row["context_family"]][row["model"]] = row["weighted_useful"]
for family in families:
    lines.append(f"| {family} | {by_family[family]['Vanilla BF16']:.1%} | {by_family[family]['QLoRA NF4']:.1%} | {by_family[family]['LoRA BF16']:.1%} |")
lines += [
    "",
    "## Findings",
    "",
    "- Both adapters improve substantially over vanilla across the paired frozen cases.",
    "- LoRA's advantage over QLoRA comes from fewer failures, not from more strict passes.",
    "- Remaining LoRA errors are concentrated in finding-state wording: supported cases can be weakened, while developing or null cases can sound too repeatable.",
    "- Deterministic fallbacks protect delivery but remain raw-model failures in this analysis.",
    "- Template diagnostics are descriptive checks for style collapse, not proof of memorization. A real memorization audit requires canary or nearest-neighbor testing against the training set.",
]
(OUT / "day7-error-analysis.md").write_text("\n".join(lines) + "\n")
print(json.dumps({"families": families, "pairwise": [{k: len(v) if isinstance(v, list) else v for k,v in x.items()} for x in pairwise], "categories": category_counts, "style": style}, indent=2))
