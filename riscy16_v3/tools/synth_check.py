#!/usr/bin/env python3
"""Validate the active RISCY-16 v3 Verilog source list."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DO = ROOT / "sim" / "run.do"


def active_verilog_files() -> list[Path]:
    files: list[Path] = []
    for raw in RUN_DO.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line.startswith("vlog "):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        files.append(ROOT / parts[-1])
    return files


def module_names(text: str) -> list[str]:
    return re.findall(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b", text)


def main() -> int:
    failures: list[str] = []
    seen_modules: dict[str, Path] = {}

    if not RUN_DO.exists():
        failures.append(f"missing simulation script: {RUN_DO}")
    else:
        files = active_verilog_files()
        if not files:
            failures.append(f"no vlog entries found in {RUN_DO}")

        for path in files:
            rel = path.relative_to(ROOT)
            if not path.exists():
                failures.append(f"missing active source: {rel}")
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            if not text.strip():
                failures.append(f"empty active source: {rel}")
                continue
            names = module_names(text)
            if not names:
                failures.append(f"no module declaration found: {rel}")
                continue
            for name in names:
                if name in seen_modules:
                    failures.append(
                        f"duplicate module {name}: {rel} and {seen_modules[name].relative_to(ROOT)}"
                    )
                seen_modules[name] = path

    required = [
        ROOT / "program.txt",
        ROOT / "tb" / "processor_tb.v",
        ROOT / "rtl" / "core" / "processor.v",
        ROOT / "docs" / "ISA.md",
        ROOT / "docs" / "ARCH.md",
        ROOT / "docs" / "PIPELINE.md",
    ]
    for path in required:
        if not path.exists():
            failures.append(f"missing required project file: {path.relative_to(ROOT)}")
        elif not path.read_text(encoding="utf-8", errors="replace").strip():
            failures.append(f"required project file is empty: {path.relative_to(ROOT)}")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1

    print(f"checked {len(active_verilog_files())} active Verilog source file(s)")
    print("active source list looks clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
