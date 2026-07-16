#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$TOOL_DIR/../.." && pwd)"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$TOOL_DIR/.cache/llama.cpp}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
NDK_VERSION="${NDK_VERSION:-28.2.13676358}"
CMAKE_VERSION="${CMAKE_VERSION:-3.31.6}"

if [[ -z "$ANDROID_SDK_ROOT" && -f "$REPO_DIR/android/local.properties" ]]; then
  ANDROID_SDK_ROOT="$(sed -n 's/^sdk.dir=//p' "$REPO_DIR/android/local.properties")"
fi
if [[ -z "$ANDROID_SDK_ROOT" ]]; then
  echo "Set ANDROID_SDK_ROOT or configure android/local.properties" >&2
  exit 1
fi

NDK_DIR="$ANDROID_SDK_ROOT/ndk/$NDK_VERSION"
CMAKE="$ANDROID_SDK_ROOT/cmake/$CMAKE_VERSION/bin/cmake"
BUILD_DIR="$TOOL_DIR/.cache/android/arm64-v8a"

if [[ ! -f "$LLAMA_CPP_DIR/CMakeLists.txt" ]]; then
  echo "Run scripts/bootstrap_llama_cpp.sh first" >&2
  exit 1
fi
if [[ ! -x "$CMAKE" || ! -f "$NDK_DIR/build/cmake/android.toolchain.cmake" ]]; then
  echo "Android NDK $NDK_VERSION or CMake $CMAKE_VERSION is missing" >&2
  exit 1
fi

"$CMAKE" -S "$LLAMA_CPP_DIR" -B "$BUILD_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-28 \
  -DANDROID_STL=c++_static \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_OPENMP=OFF \
  -DGGML_LLAMAFILE=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DLLAMA_CURL=OFF

"$CMAKE" --build "$BUILD_DIR" --config Release --target llama-completion -j 8
echo "$BUILD_DIR/bin/llama-completion"
