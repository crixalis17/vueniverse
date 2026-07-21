from datetime import UTC, datetime

import pytest

from vueniverse_medgemma.runtime_metrics import RuntimeBenchmark, summarize_runtime

Q4_SHA256 = "9f3480a68099ab445cc5224aebfc00f0e3c471cacc4a1b8a36a98631e79e0a63"


def _report(*, kind: str = "physical_phone", overrides: dict[int, dict] | None = None):
    overrides = overrides or {}
    calls = []
    for index in range(1, 11):
        payload = {
            "call_index": index,
            "cold_start": index == 1,
            "completed": True,
            "load_seconds": 2.0 if index == 1 else None,
            "time_to_first_token_seconds": 0.8,
            "total_seconds": 4.0 + index / 100,
            "peak_incremental_rss_bytes": 3_000_000_000,
            "raw_schema_valid": True,
            "guard_accepted": True,
            "fallback_used": False,
            "thermal_state": "nominal",
            "battery_level_percent": 90 - index / 10,
            "battery_temperature_celsius": 32 + index / 10,
        }
        payload.update(overrides.get(index, {}))
        calls.append(payload)
    calls.append(
        {
            "call_index": 11,
            "completed": False,
            "cancelled": True,
            "error_code": "cancelled",
            "thermal_state": "nominal",
        }
    )
    return RuntimeBenchmark.model_validate(
        {
            "created_at_utc": datetime.now(UTC),
            "artifact": {
                "model_id": "unsloth/medgemma-1.5-4b-it-GGUF",
                "model_revision": "1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30",
                "quantization": "Q4_K_M",
                "artifact_bytes": 2_489_894_144,
                "artifact_sha256": Q4_SHA256,
                "llama_cpp_revision": "5839ba352471b2a7b45e7ba401619a6896f10f8b",
            },
            "device": {
                "kind": kind,
                "name": "fictional-test-device",
                "os_version": "test",
                "api_level": 36 if kind != "host" else None,
                "abi": "arm64-v8a" if kind != "host" else "arm64",
            },
            "runtime_backend": "llama.cpp JNI",
            "runtime_revision": "wave1-test",
            "calls": calls,
        }
    )


def test_complete_physical_phone_measurements_pass() -> None:
    summary = summarize_runtime(_report())

    assert summary.status == "pass"
    assert summary.reasons == []
    assert summary.warm_latency_count == 9
    assert summary.warm_p95_seconds == pytest.approx(4.096)
    assert summary.cancellation_count == 1
    assert summary.battery_sample_count == 10
    assert summary.battery_drop_percent == pytest.approx(0.9)


@pytest.mark.parametrize("kind", ["host", "emulator"])
def test_non_phone_measurements_can_never_pass(kind: str) -> None:
    summary = summarize_runtime(_report(kind=kind))

    assert summary.status == "incomplete"
    assert "physical_phone_required" in summary.reasons


def test_threshold_failures_are_reported_independently() -> None:
    report = _report(
        overrides={
            2: {"total_seconds": 9.0},
            3: {"total_seconds": 9.0, "peak_incremental_rss_bytes": 3_600_000_000},
            4: {"raw_schema_valid": False},
            5: {"thermal_state": "serious"},
            6: {
                "completed": False,
                "total_seconds": None,
                "crashed": True,
                "error_code": "native_crash",
            },
            7: {
                "completed": False,
                "total_seconds": None,
                "out_of_memory": True,
                "error_code": "out_of_memory",
            },
        }
    )

    summary = summarize_runtime(report)

    assert summary.status == "fail"
    assert "crash_detected" in summary.reasons
    assert "out_of_memory_detected" in summary.reasons
    assert "warm_p95_exceeds_8_seconds" in summary.reasons
    assert "peak_incremental_rss_exceeds_3_5_gb" in summary.reasons
    assert "raw_schema_validity_below_95_percent" in summary.reasons
    assert "severe_thermal_state_detected" in summary.reasons


def test_empty_and_partial_runs_serialize_as_incomplete() -> None:
    report = _report().model_copy(update={"calls": []})

    summary = summarize_runtime(report)

    assert summary.status == "incomplete"
    assert summary.call_count == 0
    assert summary.warm_p95_seconds is None
    assert summary.raw_schema_valid_rate is None
    assert {
        "ten_calls_required",
        "warm_latency_samples_missing",
        "peak_rss_missing",
        "schema_measurements_missing",
    } <= set(summary.reasons)


def test_incoherent_completed_call_is_rejected() -> None:
    with pytest.raises(ValueError, match="completed calls require total_seconds"):
        _report(overrides={1: {"total_seconds": None}})


def test_duplicate_call_indexes_are_rejected() -> None:
    report = _report().model_dump()
    report["calls"][1]["call_index"] = 1

    with pytest.raises(ValueError, match="call indexes must be unique"):
        RuntimeBenchmark.model_validate(report)
