#!/usr/bin/env bash
set -euo pipefail

REVISION="5839ba352471b2a7b45e7ba401619a6896f10f8b"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$TOOL_DIR/.cache/llama.cpp}"

if [[ ! -d "$LLAMA_CPP_DIR/.git" ]]; then
  git clone --filter=blob:none https://github.com/ggml-org/llama.cpp "$LLAMA_CPP_DIR"
fi

git -C "$LLAMA_CPP_DIR" fetch --depth 1 origin "$REVISION"
git -C "$LLAMA_CPP_DIR" checkout --detach "$REVISION"

actual="$(git -C "$LLAMA_CPP_DIR" rev-parse HEAD)"
if [[ "$actual" != "$REVISION" ]]; then
  echo "Expected llama.cpp $REVISION, found $actual" >&2
  exit 1
fi

echo "$LLAMA_CPP_DIR"
