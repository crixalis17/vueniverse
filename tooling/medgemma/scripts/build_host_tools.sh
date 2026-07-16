#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$TOOL_DIR/.cache/llama.cpp}"
BUILD_DIR="$LLAMA_CPP_DIR/build"
CMAKE="${CMAKE:-$(command -v cmake || true)}"

if [[ ! -f "$LLAMA_CPP_DIR/CMakeLists.txt" ]]; then
  echo "Run scripts/bootstrap_llama_cpp.sh first" >&2
  exit 1
fi
if [[ -z "$CMAKE" || ! -x "$CMAKE" ]]; then
  echo "CMake is missing" >&2
  exit 1
fi

"$CMAKE" -S "$LLAMA_CPP_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_METAL=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_SERVER=ON \
  -DLLAMA_BUILD_UI=OFF \
  -DLLAMA_CURL=OFF

"$CMAKE" --build "$BUILD_DIR" --config Release \
  --target llama-quantize llama-completion llama-server -j 8

echo "$BUILD_DIR/bin/llama-quantize"
echo "$BUILD_DIR/bin/llama-completion"
echo "$BUILD_DIR/bin/llama-server"
