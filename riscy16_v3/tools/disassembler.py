#!/usr/bin/env python3
"""Disassemble RISCY-16 v3 26-bit memory images."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


MNEMONICS = {
    0b00000: "LDI",
    0b00001: "MOV",
    0b00010: "ADD",
    0b00011: "SUB",
    0b00100: "OR",
    0b00101: "AND",
    0b00110: "NOR",
    0b00111: "JUMP",
    0b01000: "LDS",
    0b01001: "STS",
    0b01010: "BREQ",
    0b01011: "BRNE",
    0b01100: "BRLT",
    0b01101: "BRVS",
    0b01110: "SHL",
    0b01111: "SHR",
    0b10000: "SAR",
    0b10001: "ROL",
    0b10010: "MUL",
    0b10011: "ADD.B",
    0b10100: "SUB.B",
    0b10101: "MUL.B",
    0b10110: "DIV",
}

REG_REG = {
    "MOV",
    "ADD",
    "SUB",
    "OR",
    "AND",
    "NOR",
    "SHL",
    "SHR",
    "SAR",
    "ROL",
    "MUL",
    "ADD.B",
    "SUB.B",
    "MUL.B",
    "DIV",
}
IMM16 = {"LDI", "LDS", "STS"}
BRANCH = {"BREQ", "BRNE", "BRLT", "BRVS"}


def strip_comment(line: str) -> str:
    for marker in ("//", ";", "#"):
        line = line.split(marker, 1)[0]
    return line.strip()


def read_words(path: Path) -> list[int]:
    words: list[int] = []
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = strip_comment(raw).replace("_", "")
        if not line:
            continue
        if len(line) == 26 and set(line) <= {"0", "1"}:
            words.append(int(line, 2))
        else:
            try:
                words.append(int(line, 0))
            except ValueError as exc:
                raise ValueError(f"line {line_no}: invalid instruction word {line!r}") from exc
    return words


def disassemble_word(word: int) -> str:
    opcode = (word >> 21) & 0x1F
    rx = (word >> 16) & 0x1F
    ry = (word >> 11) & 0x1F
    imm16 = word & 0xFFFF
    target11 = word & 0x7FF
    mnemonic = MNEMONICS.get(opcode, f".OP{opcode:02X}")

    if mnemonic in REG_REG:
        return f"{mnemonic.lower()} r{rx}, r{ry}"
    if mnemonic in IMM16:
        return f"{mnemonic.lower()} r{rx}, 0x{imm16:04X}"
    if mnemonic in BRANCH:
        return f"{mnemonic.lower()} r{rx}, r{ry}, {target11}"
    if mnemonic == "JUMP":
        return f"jump {imm16}"
    return f".word 0b{word:026b}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="program memory text file")
    args = parser.parse_args(argv)

    try:
        words = read_words(args.input)
    except ValueError as exc:
        print(f"disassembler: {exc}", file=sys.stderr)
        return 1

    for addr, word in enumerate(words):
        print(f"{addr:04d}: {disassemble_word(word)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
