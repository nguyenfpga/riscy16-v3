#!/usr/bin/env python3
"""Lightweight cosim smoke entry point.

Full RTL cosimulation requires a simulator transcript from ModelSim/Questa.
This script keeps the Makefile target useful in environments without that tool
by validating the program image with the architectural ISS.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from iss import Machine, read_program  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("program", type=Path, nargs="?", default=Path("program.txt"))
    parser.add_argument("--max-cycles", type=int, default=512)
    args = parser.parse_args()

    machine = Machine(read_program(args.program))
    machine.run(args.max_cycles)
    print(f"ISS smoke passed: cycles={machine.cycles} pc={machine.pc}")
    print("Run `make sim` for the RTL regression in ModelSim/Questa.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
