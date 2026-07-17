"""Versioned runtime measurements and strict phone-local pass evaluation."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Literal, Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

NonNegativeFloat = Annotated[float, Field(ge=0)]
NonNegativeInt = Annotated[int, Field(ge=0)]


class MetricsModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class ArtifactIdentity(MetricsModel):
    model_id: str = Field(min_length=1, max_length=120)
    model_revision: str = Field(min_length=1, max_length=64)
    quantization: str = Field(min_length=1, max_length=32)
    artifact_bytes: int = Field(gt=0)
    artifact_sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    llama_cpp_revision: str = Field(min_length=7, max_length=64)


class DeviceIdentity(MetricsModel):
    kind: Literal["host", "emulator", "physical_phone"]
    name: str = Field(min_length=1, max_length=120)
    os_version: str = Field(min_length=1, max_length=80)
    api_level: int | None = Field(default=None, ge=1, le=100)
    abi: str = Field(min_length=1, max_length=32)


class RuntimeCall(MetricsModel):
    call_index: int = Field(ge=1, le=100)
    cold_start: bool = False
    completed: bool
    load_seconds: NonNegativeFloat | None = None
    time_to_first_token_seconds: NonNegativeFloat | None = None
    total_seconds: NonNegativeFloat | None = None
    peak_incremental_rss_bytes: NonNegativeInt | None = None
    raw_schema_valid: bool | None = None
    guard_accepted: bool | None = None
    fallback_used: bool | None = None
    cancelled: bool = False
    crashed: bool = False
    out_of_memory: bool = False
    thermal_state: Literal["nominal", "fair", "serious", "critical", "unknown"] = "unknown"
    battery_level_percent: float | None = Field(default=None, ge=0, le=100)
    battery_temperature_celsius: float | None = Field(default=None, ge=-40, le=100)
    error_code: str | None = Field(default=None, min_length=1, max_length=64)

    @model_validator(mode="after")
    def outcome_is_coherent(self) -> Self:
        if self.completed and self.total_seconds is None:
            raise ValueError("completed calls require total_seconds")
        if self.completed and (self.crashed or self.out_of_memory or self.cancelled):
            raise ValueError("completed calls cannot be crash, OOM, or cancellation outcomes")
        if not self.completed and self.error_code is None:
            raise ValueError("incomplete calls require an error_code")
        return self


class RuntimeBenchmark(MetricsModel):
    schema_version: Literal[1] = 1
    created_at_utc: datetime
    artifact: ArtifactIdentity
    device: DeviceIdentity
    runtime_backend: str = Field(min_length=1, max_length=120)
    runtime_revision: str = Field(min_length=1, max_length=64)
    calls: list[RuntimeCall] = Field(max_length=100)

    @model_validator(mode="after")
    def call_indexes_are_unique(self) -> Self:
        indexes = [call.call_index for call in self.calls]
        if len(indexes) != len(set(indexes)):
            raise ValueError("call indexes must be unique")
        return self


class RuntimeSummary(MetricsModel):
    status: Literal["pass", "fail", "incomplete"]
    reasons: list[str]
    call_count: int
    completed_count: int
    warm_latency_count: int
    warm_p50_seconds: float | None
    warm_p95_seconds: float | None
    peak_incremental_rss_bytes: int | None
    raw_schema_valid_count: int
    raw_schema_measured_count: int
    raw_schema_valid_rate: float | None
    crash_count: int
    out_of_memory_count: int
    severe_thermal_count: int
    cancellation_count: int
    battery_sample_count: int
    battery_start_percent: float | None
    battery_end_percent: float | None
    battery_drop_percent: float | None
    peak_battery_temperature_celsius: float | None


def _percentile(values: list[float], percentile: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    position = (len(ordered) - 1) * percentile
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    fraction = position - lower
    return ordered[lower] + (ordered[upper] - ordered[lower]) * fraction


def summarize_runtime(report: RuntimeBenchmark) -> RuntimeSummary:
    completed = [call for call in report.calls if call.completed]
    warm_latencies = [
        call.total_seconds
        for call in completed
        if not call.cold_start and call.total_seconds is not None
    ]
    rss_values = [
        call.peak_incremental_rss_bytes
        for call in report.calls
        if call.peak_incremental_rss_bytes is not None
    ]
    schema_measurements = [
        call.raw_schema_valid for call in report.calls if call.raw_schema_valid is not None
    ]
    schema_valid_count = sum(value is True for value in schema_measurements)
    schema_rate = schema_valid_count / len(schema_measurements) if schema_measurements else None
    crashes = sum(call.crashed for call in report.calls)
    oom = sum(call.out_of_memory for call in report.calls)
    severe_thermal = sum(call.thermal_state in {"serious", "critical"} for call in report.calls)
    cancellation_count = sum(call.cancelled for call in report.calls)
    battery_calls = [call for call in report.calls if call.battery_level_percent is not None]
    battery_temperatures = [
        call.battery_temperature_celsius
        for call in report.calls
        if call.battery_temperature_celsius is not None
    ]
    battery_start = battery_calls[0].battery_level_percent if battery_calls else None
    battery_end = battery_calls[-1].battery_level_percent if battery_calls else None
    battery_drop = (
        max(0.0, battery_start - battery_end)
        if battery_start is not None and battery_end is not None
        else None
    )
    warm_p95 = _percentile(warm_latencies, 0.95)
    peak_rss = max(rss_values, default=None)

    incomplete_reasons: list[str] = []
    failure_reasons: list[str] = []
    if report.device.kind != "physical_phone":
        incomplete_reasons.append("physical_phone_required")
    if len(report.calls) < 10:
        incomplete_reasons.append("ten_calls_required")
    if len(warm_latencies) < 9:
        incomplete_reasons.append("warm_latency_samples_missing")
    if peak_rss is None:
        incomplete_reasons.append("peak_rss_missing")
    if len(schema_measurements) < 10:
        incomplete_reasons.append("schema_measurements_missing")
    if any(call.thermal_state == "unknown" for call in report.calls):
        incomplete_reasons.append("thermal_measurements_missing")
    if cancellation_count < 1:
        incomplete_reasons.append("cancellation_sample_missing")
    if len(battery_calls) < 10 or len(battery_temperatures) < 10:
        incomplete_reasons.append("battery_measurements_missing")

    if crashes:
        failure_reasons.append("crash_detected")
    if oom:
        failure_reasons.append("out_of_memory_detected")
    if warm_p95 is not None and warm_p95 > 8:
        failure_reasons.append("warm_p95_exceeds_8_seconds")
    if peak_rss is not None and peak_rss > 3_500_000_000:
        failure_reasons.append("peak_incremental_rss_exceeds_3_5_gb")
    if schema_rate is not None and schema_rate < 0.95:
        failure_reasons.append("raw_schema_validity_below_95_percent")
    if severe_thermal:
        failure_reasons.append("severe_thermal_state_detected")
    if any(not call.completed and not call.cancelled for call in report.calls):
        failure_reasons.append("inference_failure_detected")

    if failure_reasons:
        status = "fail"
        reasons = failure_reasons + incomplete_reasons
    elif incomplete_reasons:
        status = "incomplete"
        reasons = incomplete_reasons
    else:
        status = "pass"
        reasons = []

    return RuntimeSummary(
        status=status,
        reasons=reasons,
        call_count=len(report.calls),
        completed_count=len(completed),
        warm_latency_count=len(warm_latencies),
        warm_p50_seconds=_percentile(warm_latencies, 0.50),
        warm_p95_seconds=warm_p95,
        peak_incremental_rss_bytes=peak_rss,
        raw_schema_valid_count=schema_valid_count,
        raw_schema_measured_count=len(schema_measurements),
        raw_schema_valid_rate=schema_rate,
        crash_count=crashes,
        out_of_memory_count=oom,
        severe_thermal_count=severe_thermal,
        cancellation_count=cancellation_count,
        battery_sample_count=len(battery_calls),
        battery_start_percent=battery_start,
        battery_end_percent=battery_end,
        battery_drop_percent=battery_drop,
        peak_battery_temperature_celsius=max(battery_temperatures, default=None),
    )
