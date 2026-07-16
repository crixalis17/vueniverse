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
if [[ ! -f "$LLAMA_CPP_DIR/CMakeLists.txt" ]]; then
  echo "Run bootstrap_llama_cpp.sh before building the real JNI runtime" >&2
  exit 1
fi

NDK_DIR="$ANDROID_SDK_ROOT/ndk/$NDK_VERSION"
CMAKE="$ANDROID_SDK_ROOT/cmake/$CMAKE_VERSION/bin/cmake"
BUILD_DIR="$TOOL_DIR/.cache/android/medgemma-jni-arm64-v8a"

env LLAMA_CPP_DIR="$LLAMA_CPP_DIR" "$CMAKE" \
  -S "$REPO_DIR/android/app/src/main/cpp" \
  -B "$BUILD_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-28 \
  -DANDROID_STL=c++_shared

"$CMAKE" --build "$BUILD_DIR" --target medgemma_jni --config Release -j 8
echo "$BUILD_DIR/libmedgemma_jni.so"
