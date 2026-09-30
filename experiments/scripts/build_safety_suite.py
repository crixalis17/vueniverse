"""Build the immutable messages-only 17-case Vueniverse safety projection."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from vueniverse_medgemma.fixtures import evaluation_cases
from vueniverse_medgemma.prompt_catalog import load_prompt
from vueniverse_medgemma.schemas import explainer_model_view


def main(output_dir: str) -> None:
    destination = Path(output_dir)
    destination.mkdir(parents=True, exist_ok=True)
    system_prompt = load_prompt("explainer_system")
    records = []
    manifest = []
    for index, case in enumerate(evaluation_cases()):
        request = case.request
        allowed_citations = [metric.citation_id for metric in request.metrics]
        user_content = (
            "EvidenceBundle:\n"
            + json.dumps(explainer_model_view(request), indent=2)
            + "\nAllowed citation IDs: "
            + json.dumps(allowed_citations)
            + "\nAllowed unresolved influence IDs: "
            + json.dumps(request.unresolved_influence_ids)
            + "\nAllowed next observation IDs: "
            + json.dumps(list(request.approved_next_observations))
        )
        records.append(
            {
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_content},
                ]
            }
        )
        manifest.append(
            {
                "case_index": index,
                "case_id": case.case_id,
                "description": case.description,
                "finding_state": request.finding_state,
                "ask_intent": request.ask_intent,
            }
        )
    if len(records) != 17:
        raise RuntimeError(f"expected 17 cases, found {len(records)}")
    dataset = destination / "safety-17.jsonl"
    payload = "".join(json.dumps(row, separators=(",", ":")) + "\n" for row in records)
    if "synthetic" in payload.lower():
        raise RuntimeError("model-facing provenance marker found")
    dataset.write_text(payload, encoding="utf-8")
    digest = hashlib.sha256(dataset.read_bytes()).hexdigest()
    (destination / "safety-17-manifest.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "case_count": len(records),
                "dataset_sha256": digest,
                "cases": manifest,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(json.dumps({"case_count": len(records), "dataset_sha256": digest}))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: build_safety_suite.py OUTPUT_DIR")
    main(sys.argv[1])
