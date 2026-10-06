"""Seal and verify inspected app requests; never load or judge a model."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

FAMILIES = (
    "supported_negative",
    "supported_positive",
    "scarce_complete",
    "context_blocked",
    "mixed_direction",
)
INTENTS = ("why_promoted", "disagreement", "observe_next")
CASES = tuple(f"{family}__{intent}" for family in FAMILIES for intent in INTENTS)
REQUEST_KEYS = {
    "schemaVersion",
    "evidenceVersion",
    "findingState",
    "metricsJson",
    "promotionGatesJson",
    "exclusionsJson",
    "counterevidenceJson",
    "unresolvedInfluencesJson",
    "approvedNextObservations",
    "askIntent",
}
SOURCE_FILES = (
    "tooling/medgemma/src/vueniverse_medgemma/emulator_semantic_package.py",
    "tooling/medgemma/tests/test_emulator_semantic_package.py",
    "test/support/emulator_semantic_fixture.dart",
    "test/tools/emulator_semantic_package_builder_test.dart",
    "android/app/src/test/kotlin/com/vueniverse/vueniverse/medgemma/EmulatorSemanticContractFreezeTest.kt",
    "lib/data/model_runtime/evidence_projection_repository.dart",
    "lib/data/analytics/meeting_analysis_repository.dart",
    "lib/data/normalization/record_normalizer.dart",
    "lib/data/repositories/canonical_record_repository.dart",
    "lib/data/database/vueniverse_database.dart",
    "lib/domain/analytics/meeting_analytics_engine.dart",
    "lib/data/database/schema_versions.dart",
    "lib/domain/model_runtime/output_guard.dart",
    "lib/domain/model_runtime/deterministic_explanation_runtime.dart",
    "lib/platform/generated/model_runtime_api.g.dart",
    "android/app/src/main/kotlin/com/vueniverse/vueniverse/modelruntime/ModelRuntimeApi.g.kt",
    "android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/ModelArtifactManager.kt",
    "android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/MedGemmaRuntimeResultMapper.kt",
    "android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/PhoneLoraExplainerContract.kt",
    "android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/MedGemmaRuntime.kt",
    "android/app/src/main/cpp/medgemma_jni.cpp",
    "docs/finetuning/emulator-semantic-cases-v1.md",
    "docs/finetuning/readiness-evaluation-contract-v1.md",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(data: bytes | str) -> str:
    return hashlib.sha256(data.encode("utf-8") if isinstance(data, str) else data).hexdigest()


def _object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def parse(text: str) -> object:
    return json.loads(
        text,
        object_pairs_hook=_object,
        parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)),
    )


def read_json(path: Path) -> dict:
    value = parse(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"Not a JSON object: {path.name}")
    return value


def rows(path: Path) -> list[dict]:
    return [parse(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def facts(family: str) -> dict:
    scarce, blocked, mixed = (
        family == name for name in ("scarce_complete", "context_blocked", "mixed_direction")
    )
    count = 2 if scarce else 4
    return {
        "state": "contradictory" if mixed else "developing" if scarce or blocked else "supported",
        "candidate_count": count,
        "included_count": count,
        "control_count": count,
        "positive_count": 2 if mixed else 0 if family == "supported_negative" else count,
        "counterevidence_count": 2 if mixed else 0,
        "consistency": 0.5 if mixed else 1,
        "completeness": 1,
        "median_difference_bpm": -10 if family == "supported_negative" else 7 if mixed else 10,
        "excluded_count": 0,
        "unresolved_influence_count": 4 if blocked else 0,
        "caffeine_unknown_pair_count": 4 if blocked else 0,
        "caffeine_exposure_pair_count": 0,
        "promotion_gates": {
            "four_usable_meetings": not scarce,
            "four_controls": not scarce,
            "completeness": True,
            "consistent_direction": not mixed,
            "material_difference": True,
            "complete_provenance": True,
            "caffeine_context_reported_zero": not blocked,
        },
    }


def inventory(root: Path) -> dict:
    require(root.is_dir() and not root.is_symlink(), "Package must be a real directory")
    result = {}
    for path in sorted(root.rglob("*")):
        require(not path.is_symlink(), "Symlinks are forbidden")
        if path.is_file():
            relative = path.relative_to(root).as_posix()
            if relative != "manifest.json":
                data = path.read_bytes()
                result[relative] = {"sha256": digest(data), "bytes": len(data)}
    return result


def validate_inputs(root: Path) -> None:
    expected_files = {
        "raw-timelines.jsonl",
        "app-projections.jsonl",
        "input-export-metadata.json",
        "rendered/rendered-contracts.jsonl",
        "rendered/host-export-metadata.json",
    }
    for case in CASES:
        expected_files.update(
            {
                f"rendered/{case}.lora_v7.prompt.txt",
                f"rendered/{case}.vanilla.prompt.txt",
                f"rendered/{case}.lora_v7.grammar.gbnf",
            }
        )
    actual_files = set(inventory(root))
    extras = {"README.md", "candidate-artifact-manifest.json", "pending-semantic-review.json"}
    require(
        expected_files <= actual_files <= expected_files | extras,
        "Unexpected or missing package file",
    )
    raw = rows(root / "raw-timelines.jsonl")
    projections = rows(root / "app-projections.jsonl")
    contracts = rows(root / "rendered/rendered-contracts.jsonl")
    require([r["family_id"] for r in raw] == list(FAMILIES), "Raw family matrix changed")
    require([r["case_id"] for r in projections] == list(CASES), "Request case matrix changed")
    require([r["case_id"] for r in contracts] == list(CASES), "Rendered case matrix changed")
    raw_by_family = {r["family_id"]: r for r in raw}
    for r in raw:
        require(
            r["split"] == "inspected_development" and r["cluster_id"] == r["family_id"],
            "Wrong raw split",
        )
        require(digest(r["raw_timeline_json"]) == r["raw_input_sha256"], "Raw bytes changed")
        require(parse(r["raw_timeline_json"]) == r["records"], "Raw duplicate content disagrees")
        require(
            {record["source"] for record in r["records"]}
            <= {"demoCalendar", "demoHealth", "demoManual"},
            "Non-demo input source",
        )
    for r, c in zip(projections, contracts, strict=True):
        family, intent = r["case_id"].split("__")
        require(
            r["family_id"] == c["family_id"] == r["cluster_id"] == family,
            "Family identity mismatch",
        )
        require(
            r["intent"] == c["intent"] == intent and r["split"] == "inspected_development",
            "Intent/split mismatch",
        )
        require(
            r["raw_input_sha256"] == raw_by_family[family]["raw_input_sha256"],
            "Raw linkage mismatch",
        )
        require(r["expected_analytics"] == facts(family), "Analytical facts changed")
        request = r["pigeon_request"]
        require(
            set(request) == REQUEST_KEYS and request["schemaVersion"] == "explainer-v8",
            "Pigeon contract changed",
        )
        require(
            request["askIntent"] == intent and request["findingState"] == facts(family)["state"],
            "Request meaning mismatch",
        )
        metrics = parse(request["metricsJson"])
        expected = facts(family)
        require(
            metrics == r["guard_context"]["primaryMetricValues"], "Guard metric values disagree"
        )
        for key, value in expected.items():
            if key not in ("state", "promotion_gates"):
                require(metrics[key] == value, f"Projected metric changed: {key}")
        for key, value in expected["promotion_gates"].items():
            require(metrics[f"gate_{key}"] == int(value), f"Projected gate changed: {key}")
        require(
            parse(request["promotionGatesJson"])
            == {"status": expected["state"], "policyVersion": 2},
            "Promotion policy mismatch",
        )
        require(
            parse(r["request_wire_json"]) == request
            and digest(r["request_wire_json"]) == r["request_wire_sha256"],
            "Request bytes changed",
        )
        require(
            r["projection_request_hash"] != r["request_wire_sha256"],
            "Cache identity mislabeled as wire hash",
        )
        require(
            digest(r["evidence_snapshot_json"]) == r["evidence_snapshot_sha256"],
            "Evidence snapshot changed",
        )
        evidence = parse(r["evidence_snapshot_json"])["evidence_bundle"]
        require(
            evidence["id"] == r["evidence_bundle_id"]
            and evidence["analysisRunId"] == r["analysis_run_id"],
            "Evidence/run identity mismatch",
        )
        require(evidence["evidenceHash"] == r["evidence_hash"], "Evidence content hash mismatch")
        require(
            evidence["status"] == expected["state"] and evidence["promotionPolicyVersion"] == 2,
            "Evidence policy mismatch",
        )
        require(
            request["evidenceVersion"]
            == r["evidence_bundle_id"]
            == r["guard_context"]["evidenceVersion"]
            == c["evidence_version"],
            "Evidence version mismatch",
        )
        baseline = r["deterministic_baseline"]
        require(
            baseline["delivery_mode"] == "deterministic"
            and baseline["is_expected_llm_target"] is False,
            "Fallback mislabeled",
        )
        require(baseline["raw_dto"]["safety"]["accepted"] is True, "Fallback not accepted")
        dto = baseline["raw_dto"]
        require(
            dto["evidenceVersion"] == request["evidenceVersion"]
            and dto["metadata"]["runtime"] == "deterministic"
            and dto["metadata"]["promptVersion"] == 6
            and dto["metadata"]["outputGuardVersion"] == 7
            and dto["metadata"]["schemaValid"] is True
            and dto["failure"] is None
            and baseline["standalone_guard_result"] == dto["safety"],
            "Deterministic baseline identity/guard mismatch",
        )
        for variant, version, cap in (("lora_v7", 8, 512), ("vanilla", 5, 384)):
            contract = c[variant]
            require(
                contract["prompt_version"] == version and contract["max_output_tokens"] == cap,
                "Runtime contract changed",
            )
            require(contract["native_inference_timeout_ms"] == 120000, "Runtime timeout changed")
            require(
                contract["assistant_prefill"]
                == ('{"schema_version":2,"summary":"' if variant == "lora_v7" else "")
                and contract["generated_continuation_prefix_reassembled"] is (variant == "lora_v7"),
                "Assistant continuation contract changed",
            )
            for kind in ("prompt", "grammar"):
                filename = contract[f"{kind}_file"]
                if filename is None:
                    require(
                        variant == "vanilla" and kind == "grammar", "Unexpected absent contract"
                    )
                    continue
                require(
                    Path(filename).name == filename and not filename.startswith("."),
                    "Unsafe rendered path",
                )
                suffix = "prompt.txt" if kind == "prompt" else "grammar.gbnf"
                require(
                    filename == f"{r['case_id']}.{variant}.{suffix}",
                    "Wrong rendered case/variant file",
                )
                data = (root / "rendered" / filename).read_bytes()
                require(
                    digest(data) == contract[f"{kind}_sha256"]
                    and len(data) == contract[f"{kind}_bytes"],
                    "Rendered bytes changed",
                )
                units = len(data.decode("utf-8").encode("utf-16-le")) // 2
                require(units == contract[f"{kind}_utf16_code_units"], "Rendered length changed")
                require(units <= (24000 if kind == "prompt" else 8192), "Host contract too large")
    for family in FAMILIES:
        selected = [r for r in projections if r["family_id"] == family]
        for key in (
            "evidence_hash",
            "evidence_bundle_id",
            "analysis_run_id",
            "canonical_input_hash",
            "evidence_snapshot_sha256",
        ):
            require(
                len({r[key] for r in selected}) == 1, f"Intent-independent identity changed: {key}"
            )
    metadata = read_json(root / "input-export-metadata.json")
    require(
        metadata["model_attempts"] == 0 and metadata["request_count"] == 15,
        "Not a no-inference freeze",
    )
    for key, value in {
        "schema": "emulator-semantic-input-export-v1",
        "split": "inspected_development",
        "raw_family_count": 5,
        "normalization_version": 1,
        "analysis_version": 7,
        "promotion_policy_version": 2,
        "projection_schema": "explainer-v8",
        "deterministic_fallback_version": 6,
        "output_guard_version": 7,
        "analytical_clock_utc": "2026-09-20T12:00:00.000Z",
        "deterministic_baseline_is_llm_target": False,
    }.items():
        require(metadata[key] == value, f"Input metadata changed: {key}")
    host = read_json(root / "rendered/host-export-metadata.json")
    require(
        host["input_sha256"] == digest((root / "app-projections.jsonl").read_bytes()),
        "Renderer input binding changed",
    )
    for key in (
        "model_loaded",
        "model_inference_performed",
        "context_fit_verified",
        "native_grammar_initialization_verified",
        "normal_candidate_activation",
    ):
        require(host[key] is False, f"Unverified runtime claim: {key}")
    require(
        host["tokenizer_prompt_token_ids"] is None and host["tokenizer_prompt_token_count"] is None,
        "Fabricated tokenizer result",
    )
    require(bool(host["known_comparison_confound"]), "Missing vanilla comparison confound")


def validate_candidate(candidate: dict) -> None:
    require(
        candidate["status"] == "held_candidate_semantic_contract_failed", "Candidate hold changed"
    )
    artifact = candidate["artifact"]
    require(
        artifact["base_model"] == "google/medgemma-1.5-4b-it"
        and artifact["quantization"] == "Q4_K_M"
        and artifact["size_bytes"] == 2489893568
        and artifact["sha256"]
        == "dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234",
        "Candidate identity changed",
    )
    contract = candidate["runtime_contract"]
    require(
        contract["normal_build_inference_enabled"] is False
        and contract["android_prompt_version"] == 8
        and contract["vanilla_android_prompt_version"] == 5
        and contract["dart_output_guard_version"] == 7,
        "Candidate activation/version mismatch",
    )


def write_new(path: Path, value: dict) -> None:
    with path.open("x", encoding="utf-8") as file:
        file.write(json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False) + "\n")


def seal(root: Path, repo: Path, parent_commit: str) -> None:
    require(not (root / "manifest.json").exists(), "Already sealed; never overwrite")
    validate_inputs(root)
    source_files = {}
    for name in SOURCE_FILES:
        data = (repo / name).read_bytes()
        source_files[name] = {"sha256": digest(data), "bytes": len(data)}
    candidate = read_json(repo / "experiments/readiness/phone-lora-v7-candidate-v1.json")
    validate_candidate(candidate)
    write_new(root / "candidate-artifact-manifest.json", candidate)
    review = {
        "schema": "emulator-semantic-pending-review-v1",
        "model_attempts": 0,
        "note": "Pending slots are not verdicts. No LLM outputs exist in this package.",
        "cases": [
            {
                "case_id": case,
                "variant": variant,
                "status": "not_run",
                "output_sha256": None,
                "grounding": None,
                "uncertainty": None,
                "safety": None,
                "usefulness": None,
                "verdict": None,
                "evidence_references": [],
                "justification": None,
            }
            for case in CASES
            for variant in ("lora_v7", "vanilla")
        ],
    }
    write_new(root / "pending-semantic-review.json", review)
    write_new(
        root / "manifest.json",
        {
            "schema": "emulator-semantic-freeze-v1",
            "split": "inspected_development",
            "families": list(FAMILIES),
            "intents": list(INTENTS),
            "request_count": 15,
            "rendered_prompt_count": 30,
            "model_attempts": 0,
            "candidate_activation": False,
            "source_parent_commit": parent_commit,
            "source_identity_note": (
                "Exporters were uncommitted at capture; per-file hashes identify exact as-run "
                "source. Parent commit is not exporter identity."
            ),
            "source_files": source_files,
            "artifact_verification": (
                "Copied retained candidate metadata only; no weights rehashed, "
                "downloaded or loaded in this freeze."
            ),
            "comparison_status": (
                "Production prompts differ, including vanilla v5 positive_count semantics; "
                "this is not a controlled training-only comparison."
            ),
            "reproducibility": (
                "Replay frozen bytes. New production run IDs are wall-clock dependent; "
                "independent construction is not byte-identical."
            ),
            "scope_limitations": (
                "Five inspected correlated families, not fifteen independent samples or a hidden "
                "final test. No person/song identity, unknown health windows, timezone "
                "or dirty-control coverage."
            ),
            "files": inventory(root),
        },
    )
    verify(root)


def verify(root: Path) -> dict:
    manifest = read_json(root / "manifest.json")
    require(manifest["schema"] == "emulator-semantic-freeze-v1", "Unknown package schema")
    require(
        manifest["model_attempts"] == 0 and manifest["candidate_activation"] is False,
        "Unexpected model activation",
    )
    require(manifest["files"] == inventory(root), "Package file inventory/hash mismatch")
    validate_inputs(root)
    require(set(manifest["source_files"]) == set(SOURCE_FILES), "Source inventory mismatch")
    host = read_json(root / "rendered/host-export-metadata.json")
    native = host["native_source_contract"]
    require(
        native["source_sha256"] == manifest["source_files"][native["source_file"]]["sha256"],
        "Native source hash mismatch",
    )
    validate_candidate(read_json(root / "candidate-artifact-manifest.json"))
    review = read_json(root / "pending-semantic-review.json")
    require(
        review["model_attempts"] == 0 and len(review["cases"]) == 30, "Unexpected review outputs"
    )
    require(
        [(r["case_id"], r["variant"]) for r in review["cases"]]
        == [(case, variant) for case in CASES for variant in ("lora_v7", "vanilla")],
        "Review matrix changed",
    )
    require(
        all(
            r["status"] == "not_run"
            and all(
                r[k] is None
                for k in (
                    "output_sha256",
                    "grounding",
                    "uncertainty",
                    "safety",
                    "usefulness",
                    "verdict",
                )
            )
            for r in review["cases"]
        ),
        "Pending review fabricated metrics",
    )
    return {"verified": True, "requests": 15, "rendered_prompts": 30, "model_attempts": 0}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("seal", "verify"))
    parser.add_argument("package", type=Path)
    parser.add_argument("--repo", type=Path)
    parser.add_argument("--parent-commit")
    args = parser.parse_args()
    if args.action == "seal":
        if not args.repo or not args.parent_commit:
            parser.error("seal requires --repo and --parent-commit")
        seal(args.package, args.repo, args.parent_commit)
    print(json.dumps(verify(args.package)))


if __name__ == "__main__":
    main()
