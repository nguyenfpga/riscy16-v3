#!/usr/bin/env python3
"""Tiny RISCY-16 text linker.

The current flow is intentionally simple: concatenate one or more assembled
memory-image text files into a single output file.
"""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("inputs", nargs="+", type=Path)
    args = parser.parse_args()

    lines: list[str] = []
    for input_path in args.inputs:
        text = input_path.read_text(encoding="utf-8")
        for line in text.splitlines():
            if line.strip():
                lines.append(line.rstrip())

    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"linked {len(args.inputs)} file(s), {len(lines)} line(s) -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
