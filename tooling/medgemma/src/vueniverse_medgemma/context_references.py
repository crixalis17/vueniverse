"""Derive stable, non-reversible references for private canonical contexts.

The raw source identifier is used only at the local ingestion boundary.  The returned
reference is safe to place in an evidence bundle: the same source item resolves to the
same reference for one person, while a different secret produces a different reference.
"""

from __future__ import annotations

import hashlib
import hmac

from vueniverse_medgemma.schemas import Identifier


def derive_context_reference(
    *, context_family: Identifier, stable_source_key: str, secret: bytes
) -> str:
    """Return a stable opaque reference without retaining a raw source identifier.

    ``stable_source_key`` is a source-local key such as a calendar recurrence ID,
    Spotify track ID, contact lookup key, or user-selected journal-tag signature. It
    must be available only inside the private ingestion process.  ``secret`` belongs in
    an OS-backed keystore or equivalent secret manager, never in the dataset or cloud
    training artifacts.
    """

    if not stable_source_key.strip():
        raise ValueError("stable_source_key must not be blank")
    if len(secret) < 16:
        raise ValueError("context-reference secret must contain at least 16 bytes")
    payload = f"{context_family}\x00{stable_source_key}".encode()
    digest = hmac.new(secret, payload, hashlib.sha256).hexdigest()[:20]
    return f"ctx_{digest}"
