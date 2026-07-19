"""Versioned, privacy-safe schemas used by model evaluation tooling."""

from __future__ import annotations

from typing import Annotated, Literal, Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

Identifier = Annotated[
    str,
    Field(min_length=1, max_length=64, pattern=r"^[a-z][a-z0-9_]*$"),
]
Label = Annotated[str, Field(min_length=1, max_length=80)]
Description = Annotated[str, Field(min_length=1, max_length=180)]
MetricValue = Annotated[str, Field(min_length=1, max_length=64)]
VersionIdentifier = Annotated[
    str,
    Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9][A-Za-z0-9._-]*$"),
]
FindingState = Literal[
    "supported",
    "developing",
    "null",
    "contradictory",
    "insufficient_data",
    "stale",
    "invalidated",
]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class EvidenceMetric(StrictModel):
    citation_id: Identifier
    label: Label
    value_text: MetricValue
    definition: Description
    source: Label


class ExplainerRequest(StrictModel):
    schema_version: Literal[1] = 1
    evidence_version: VersionIdentifier
    finding_state: FindingState
    metrics: list[EvidenceMetric] = Field(min_length=1, max_length=16)
    exclusion_ids: list[Identifier] = Field(max_length=16)
    counterevidence_ids: list[Identifier] = Field(max_length=16)
    unresolved_influence_ids: list[Identifier] = Field(max_length=3)
    approved_next_observations: dict[Identifier, Description] = Field(max_length=3)
    ask_intent: Literal[
        "explain",
        "what_weakens",
        "what_is_missing",
        "what_disagrees",
        "observe_next",
        "promotion_gate",
    ]
    user_question: str = Field(min_length=1, max_length=500)

    @model_validator(mode="after")
    def identifiers_are_unique(self) -> Self:
        citation_ids = [metric.citation_id for metric in self.metrics]
        if len(citation_ids) != len(set(citation_ids)):
            raise ValueError("metric citation IDs must be unique")
        for name in ("exclusion_ids", "counterevidence_ids", "unresolved_influence_ids"):
            values = getattr(self, name)
            if len(values) != len(set(values)):
                raise ValueError(f"{name} must contain unique values")
        return self


class CitedParagraph(StrictModel):
    text: str = Field(min_length=1, max_length=280)
    citations: list[Identifier] = Field(
        min_length=1,
        max_length=3,
        json_schema_extra={"uniqueItems": True},
    )

    @model_validator(mode="after")
    def citations_are_unique(self) -> Self:
        if len(self.citations) != len(set(self.citations)):
            raise ValueError("citations must contain unique values")
        return self


class ExplainerOutput(StrictModel):
    schema_version: Literal[2] = 2
    summary: str = Field(min_length=1, max_length=180)
    paragraphs: list[CitedParagraph] = Field(min_length=1, max_length=2)
    uncertainty: str = Field(min_length=1, max_length=180)
    unresolved_influence_ids: list[Identifier] = Field(
        max_length=3,
        json_schema_extra={"uniqueItems": True},
    )
    next_observation_id: Identifier | None = None

    @model_validator(mode="after")
    def influences_are_unique(self) -> Self:
        if len(self.unresolved_influence_ids) != len(set(self.unresolved_influence_ids)):
            raise ValueError("unresolved influence IDs must be unique")
        return self


def explainer_output_schema(request: ExplainerRequest) -> dict[str, object]:
    """Restrict identifiers to values supplied in one EvidenceBundle."""
    schema = ExplainerOutput.model_json_schema()
    paragraph = schema["$defs"]["CitedParagraph"]
    paragraph["properties"]["citations"]["items"] = {
        "type": "string",
        "enum": [metric.citation_id for metric in request.metrics],
    }
    influence_schema = schema["properties"]["unresolved_influence_ids"]
    if request.unresolved_influence_ids:
        influence_schema["items"] = {
            "type": "string",
            "enum": request.unresolved_influence_ids,
        }
    else:
        influence_schema["maxItems"] = 0

    next_observation_ids = list(request.approved_next_observations)
    if next_observation_ids:
        schema["properties"]["next_observation_id"]["anyOf"][0] = {
            "type": "string",
            "enum": next_observation_ids,
        }
    else:
        schema["properties"]["next_observation_id"] = {
            "default": None,
            "type": "null",
        }
    return schema


def explainer_model_view(request: ExplainerRequest) -> dict[str, object]:
    """Project privacy-safe, exact result values into the model boundary."""
    return {
        "finding_state": request.finding_state,
        "metrics": [
            {
                "citation_id": metric.citation_id,
                "label": metric.label,
                "value_text": metric.value_text,
                "definition": metric.definition,
                "source": metric.source,
            }
            for metric in request.metrics
        ],
        "exclusion_ids": request.exclusion_ids,
        "counterevidence_available": bool(request.counterevidence_ids),
        "unresolved_influence_ids": request.unresolved_influence_ids,
        "approved_next_observations": request.approved_next_observations,
        "ask_intent": request.ask_intent,
        "user_question": request.user_question,
    }


class ExplorerOperation(StrictModel):
    operation_id: Literal[
        "compare_repeated_event",
        "inspect_recovery",
        "check_logged_influence",
    ]
    event_category_id: Identifier
    influence_id: Identifier | None = None


class ExplorerRequest(StrictModel):
    schema_version: Literal[1] = 1
    summary_version: VersionIdentifier
    available_event_category_ids: list[Identifier] = Field(min_length=1, max_length=16)
    available_influence_ids: list[Identifier] = Field(max_length=16)
    allowed_operations: list[
        Literal[
            "compare_repeated_event",
            "inspect_recovery",
            "check_logged_influence",
        ]
    ] = Field(min_length=1, max_length=3)


class ExplorerDecision(StrictModel):
    schema_version: Literal[1] = 1
    decision: ExplorerOperation
    rationale: str = Field(min_length=1, max_length=280)
