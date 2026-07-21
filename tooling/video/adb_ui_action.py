#!/usr/bin/env python3
"""Small accessibility-driven helper for repeatable emulator recordings."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET


def adb_command() -> list[str]:
    adb = os.environ.get(
        "ADB_BIN", "/Users/rakesh/Library/Android/sdk/platform-tools/adb"
    )
    serial = os.environ.get("SERIAL", "emulator-5554")
    return [adb, "-s", serial]


def dump_tree() -> ET.Element:
    result = subprocess.run(
        [*adb_command(), "exec-out", "uiautomator", "dump", "/dev/tty"],
        check=True,
        capture_output=True,
        text=True,
    )
    start = result.stdout.find("<?xml")
    end = result.stdout.rfind("</hierarchy>")
    if start < 0 or end < 0:
        raise RuntimeError("uiautomator did not return an XML hierarchy")
    return ET.fromstring(result.stdout[start : end + len("</hierarchy>")])


def label(node: ET.Element) -> str:
    return node.attrib.get("content-desc") or node.attrib.get("text") or ""


def find_node(expected: str, contains: bool) -> ET.Element | None:
    matches = []
    for node in dump_tree().iter("node"):
        current = label(node)
        if (expected in current if contains else expected == current):
            matches.append(node)
    if not matches:
        return None
    clickable = [node for node in matches if node.attrib.get("clickable") == "true"]
    return (clickable or matches)[0]


def center(node: ET.Element) -> tuple[int, int]:
    values = [int(value) for value in re.findall(r"\d+", node.attrib["bounds"])]
    if len(values) != 4:
        raise RuntimeError(f"invalid bounds: {node.attrib.get('bounds')}")
    left, top, right, bottom = values
    return ((left + right) // 2, (top + bottom) // 2)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("tap", "wait", "bounds", "labels"))
    parser.add_argument("label", nargs="?", default="")
    parser.add_argument("--contains", action="store_true")
    parser.add_argument("--timeout", type=float, default=15)
    args = parser.parse_args()

    if args.action == "labels":
        for node in dump_tree().iter("node"):
            current = label(node).strip()
            if current:
                print(f"{node.attrib.get('bounds')}\t{current}")
        return 0

    deadline = time.monotonic() + args.timeout
    node = None
    while time.monotonic() < deadline:
        node = find_node(args.label, args.contains)
        if node is not None:
            break
        time.sleep(0.35)
    if node is None:
        print(f"UI label not found: {args.label!r}", file=sys.stderr)
        return 2

    x, y = center(node)
    if args.action == "bounds":
        print(f"{x} {y} {node.attrib['bounds']}")
    elif args.action == "tap":
        subprocess.run(
            [*adb_command(), "shell", "input", "tap", str(x), str(y)], check=True
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
