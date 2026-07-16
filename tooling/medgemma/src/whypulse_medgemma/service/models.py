"""Versioned, bounded DTOs for the Demo-only development service."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Annotated, Any, Literal, Protocol, Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

Version = Annotated[
    str,
    Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9][A-Za-z0-9._-]*$"),
]
BoundedJson = Annotated[str, Field(min_length=2, max_length=32_768)]


class ServiceModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class ExplainerPayload(ServiceModel):
    """HTTP representation of Person 1's frozen Pigeon ExplainerRequest."""

    schemaVersion: Version
    evidenceVersion: Version
    findingState: Annotated[str, Field(min_length=1, max_length=64)]
    metricsJson: BoundedJson
    promotionGatesJson: BoundedJson
    exclusionsJson: BoundedJson
    counterevidenceJson: BoundedJson
    unresolvedInfluencesJson: BoundedJson
    approvedNextObservations: list[Annotated[str, Field(min_length=1, max_length=180)]] = Field(
        max_length=3
    )
    askIntent: Annotated[str, Field(min_length=1, max_length=64)]

    @model_validator(mode="after")
    def embedded_json_is_valid(self) -> Self:
        for name in (
            "metricsJson",
            "promotionGatesJson",
            "exclusionsJson",
            "counterevidenceJson",
            "unresolvedInfluencesJson",
        ):
            try:
                value = json.loads(getattr(self, name))
            except json.JSONDecodeError as error:
                raise ValueError(f"{name} must contain valid JSON") from error
            if not isinstance(value, (dict, list)):
                raise ValueError(f"{name} must contain a JSON object or array")
        return self


class DemoExplainEnvelope(ServiceModel):
    schemaVersion: Literal["whypulse-model-service-v1"]
    store: Literal["demo", "live"]
    request: ExplainerPayload
    timeoutMillis: int = Field(default=30_000, ge=1_000, le=120_000)
    maxOutputTokens: int = Field(default=384, ge=1, le=512)


class ServiceExplainerOutput(ServiceModel):
    """Raw model shape consumed by the frozen Pigeon ExplainerOutput mapper."""

    summary: Annotated[str, Field(min_length=1, max_length=180)]
    citedParagraphsJson: Annotated[str, Field(min_length=2, max_length=2_048)]
    uncertainty: Annotated[str, Field(min_length=1, max_length=180)]
    citedUnresolvedInfluences: list[
        Annotated[str, Field(min_length=1, max_length=64)]
    ] = Field(max_length=3)
    approvedNextObservation: Annotated[str, Field(min_length=1, max_length=180)] | None = None

    @model_validator(mode="after")
    def cited_paragraphs_are_structured(self) -> Self:
        try:
            paragraphs = json.loads(self.citedParagraphsJson)
        except json.JSONDecodeError as error:
            raise ValueError("citedParagraphsJson must contain valid JSON") from error
        if not isinstance(paragraphs, list) or not 1 <= len(paragraphs) <= 2:
            raise ValueError("citedParagraphsJson must contain one or two paragraphs")
        for paragraph in paragraphs:
            if not isinstance(paragraph, dict):
                raise ValueError("each cited paragraph must be an object")
            if not isinstance(paragraph.get("text"), str) or not paragraph["text"].strip():
                raise ValueError("each cited paragraph must contain text")
            citations = paragraph.get("citations")
            if not isinstance(citations, list) or not 1 <= len(citations) <= 3:
                raise ValueError("each cited paragraph must contain one to three citations")
            if any(not isinstance(value, str) or not value.strip() for value in citations):
                raise ValueError("citation IDs must be non-empty strings")
        return self


@dataclass(frozen=True)
class BackendInferenceResult:
    raw_output: str
    model_name: str
    prompt_version: int
    load_millis: int | None
    time_to_first_token_millis: int | None
    latency_millis: int
    schema_valid: bool
    extra_metadata: dict[str, Any] = field(default_factory=dict)


class BackendFailure(RuntimeError):
    """Stable backend failure surfaced by both fake and llama.cpp backends."""

    def __init__(self, code: str, message: str, *, retryable: bool) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.retryable = retryable


class InferenceBackend(Protocol):
    @property
    def ready(self) -> bool: ...

    def infer(self, request: DemoExplainEnvelope) -> BackendInferenceResult: ...

    def cancel(self) -> bool: ...

    def close(self) -> None: ...
