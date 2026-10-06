"""Decode checksummed synthetic replay records; never infer semantic correctness."""

from __future__ import annotations

import argparse
import base64
import json
import statistics
from pathlib import Path

from .emulator_semantic_package import CASES, digest, parse, require, rows, verify, write_new

CHUNK = "VUENIVERSE_PHONE_CONTRACT_CHUNK "
EVENT = "VUENIVERSE_SEMANTIC_EVENT "


def decode_capture(text: str, run_id: str, package: Path) -> dict:
    verify(package)
    frozen = {row["case_id"]: row for row in rows(package / "app-projections.jsonl")}
    groups, events, native = {}, [], {}
    active_case = None
    for line in text.splitlines():
        if line.startswith(EVENT):
            event = parse(line[len(EVENT) :])
            require(event["run_id"] == run_id, "Mixed replay runs")
            events.append(event)
            if event["event"] == "case_start":
                require(active_case is None, "Overlapping cases")
                active_case = event["case_id"]
            elif event["event"] == "case_end":
                require(active_case == event["case_id"], "Wrong case end")
                active_case = None
        elif line.startswith(CHUNK):
            envelope = parse(line[len(CHUNK) :])
            key = envelope["capture_id"], envelope["intent"], envelope["kind"]
            require(key[0].startswith(run_id + "-"), "Wrong capture identity")
            require(key[2] in ("model_attempt", "app_delivery"), "Wrong capture kind")
            count, index = envelope["count"], envelope["index"]
            require(
                type(count) is int
                and type(index) is int
                and 1 <= count <= 35
                and 0 <= index < count,
                "Invalid chunk bounds",
            )
            group = groups.setdefault(
                key, {"count": count, "sha256": envelope["sha256"], "chunks": {}}
            )
            require(
                group["count"] == count and group["sha256"] == envelope["sha256"],
                "Mixed chunk metadata",
            )
            require(index not in group["chunks"], "Duplicate capture chunk")
            group["chunks"][index] = base64.b64decode(envelope["data_b64"], validate=True)
        elif line.startswith('{"prompt_tokens":'):
            require(
                active_case is not None and active_case not in native,
                "Uncorrelated or duplicate native diagnostics",
            )
            native[active_case] = parse(line)
    records, incomplete = {}, []
    for (capture_id, intent, kind), group in groups.items():
        if set(group["chunks"]) != set(range(group["count"])):
            incomplete.append({"capture_id": capture_id, "intent": intent, "kind": kind})
            continue
        data = b"".join(group["chunks"][index] for index in range(group["count"]))
        require(
            len(data) <= 16384 and digest(data) == group["sha256"], "Capture checksum/size mismatch"
        )
        payload = parse(data.decode("utf-8"))
        case = payload["case_id"]
        require(
            case in frozen and payload["run_id"] == run_id and payload["variant"] == "lora_v7",
            "Wrong payload identity",
        )
        require(
            intent == frozen[case]["intent"] and capture_id == f"{run_id}-{CASES.index(case)}",
            "Wrong capture case mapping",
        )
        require(
            payload["request_wire_sha256"] == frozen[case]["request_wire_sha256"],
            "Replay used a different request",
        )
        record = records.setdefault(case, {})
        require(kind not in record, "Duplicate captured record")
        record[kind] = payload
        record[kind + "_sha256"] = group["sha256"]
        if kind == "model_attempt":
            dto = payload["raw_dto"]
            require(
                dto["evidenceVersion"] == frozen[case]["pigeon_request"]["evidenceVersion"],
                "Wrong result evidence",
            )
            require(
                dto["metadata"]["runtime"] == "phoneMedGemma"
                and dto["metadata"]["promptVersion"] == 8
                and "@lora-v7-q4-dd9c2a212672a5bb" in dto["metadata"]["modelName"],
                "Wrong generated runtime identity",
            )
            require(payload["from_cache"] is False, "Cached output")
        else:
            require(
                payload["delivery_is_simulation"] is True
                and payload["coordinator_executed"] is False
                and payload["from_cache"] is False,
                "Diagnostic delivery mislabeled as app acceptance",
            )
    starts = [event["case_id"] for event in events if event["event"] == "case_start"]
    ends = [event["case_id"] for event in events if event["event"] == "case_end"]
    require(
        starts == list(CASES[: len(starts)]) and len(starts) <= 15,
        "Not one attempt per ordered case",
    )
    require(ends == starts[: len(ends)] and len(ends) <= len(starts), "Case end matrix changed")
    complete_events = [event for event in events if event["event"] == "run_complete"]
    require(len(complete_events) <= 1, "Duplicate run completion")
    complete = bool(complete_events)
    if complete:
        final = complete_events[0]
        require(
            final["attempted_cases"] == len(starts) == len(ends)
            and final["unattempted_cases"] == 15 - len(starts),
            "Completion counts disagree",
        )
        require(
            not incomplete
            and all(
                set(records.get(case, {})) >= {"model_attempt", "app_delivery"} for case in starts
            ),
            "Completed run lost capture",
        )
    captured = [case for case in CASES if "model_attempt" in records.get(case, {})]
    latencies = [records[case]["model_attempt"]["elapsed_ms"] for case in captured]
    return {
        "schema": "emulator-semantic-capture-v1",
        "run_id": run_id,
        "log_sha256": digest(text),
        "input_package_manifest_sha256": digest((package / "manifest.json").read_bytes()),
        "planned_cases": 15,
        "scenario_clusters": 5,
        "split": "inspected_development",
        "attempted_cases": len(starts),
        "captured_model_records": len(captured),
        "unattempted_cases": 15 - len(starts),
        "run_complete_event": complete,
        "run_final_event": complete_events[0] if complete else None,
        "incomplete_capture_groups": incomplete,
        "schema_valid_count": sum(
            records[case]["model_attempt"]["raw_dto"]["metadata"]["schemaValid"]
            for case in captured
        ),
        "automated_guard_accepted_count": sum(
            records[case]["model_attempt"]["guard_result"]["accepted"] for case in captured
        ),
        "median_call_elapsed_ms": statistics.median(latencies) if latencies else None,
        "semantic_review": "pending",
        "normal_candidate_activation": False,
        "delivery_is_simulation": True,
        "events": events,
        "cases": [
            {"case_id": case, **records[case], "native_diagnostics": native.get(case)}
            for case in captured
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = decode_capture(args.log.read_text(encoding="utf-8"), args.run_id, args.package)
    if args.output:
        require(report["run_complete_event"], "Do not seal an unfinished run as complete")
        write_new(args.output, report)
    print(
        json.dumps(
            {
                key: report[key]
                for key in (
                    "attempted_cases",
                    "captured_model_records",
                    "unattempted_cases",
                    "run_complete_event",
                    "schema_valid_count",
                    "automated_guard_accepted_count",
                    "median_call_elapsed_ms",
                    "semantic_review",
                )
            }
        )
    )


if __name__ == "__main__":
    main()
