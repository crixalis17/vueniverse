"""Compile the actual JNI token-storage helper with optimized UBSan checks."""

import shutil
import subprocess
from pathlib import Path

import pytest


def test_borrowed_decode_token_outlives_sampling_iteration(tmp_path: Path) -> None:
    compiler = shutil.which("clang++")
    if compiler is None:
        pytest.skip("clang++ is required for the native lifetime regression")
    repo = Path(__file__).resolve().parents[3]
    cpp = repo / "android/app/src/main/cpp"
    test_source = repo / "android/app/src/test/cpp/stable_sampled_token_test.cpp"
    executable = tmp_path / "stable-sampled-token-test"
    subprocess.run(
        [
            compiler,
            "-std=c++17",
            "-O3",
            "-fsanitize=undefined",
            "-fno-omit-frame-pointer",
            f"-I{cpp}",
            str(test_source),
            "-o",
            str(executable),
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=60,
    )
    subprocess.run([str(executable)], check=True, capture_output=True, text=True, timeout=10)
    # Confirm the exercised helper is the actual next-batch storage, not a
    # disconnected test double that leaves the former dangling pointer intact.
    native_source = (cpp / "medgemma_jni.cpp").read_text()
    assert "llama_batch_get_one(next_token_storage.store(token), 1)" in native_source
    assert "llama_batch_get_one(&token, 1)" not in native_source
