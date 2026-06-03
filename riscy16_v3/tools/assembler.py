#!/usr/bin/env python3
"""Assembler for the RISCY-16 v3 26-bit instruction format."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


OPCODES = {
    "LDI": 0b00000,
    "MOV": 0b00001,
    "ADD": 0b00010,
    "SUB": 0b00011,
    "OR": 0b00100,
    "AND": 0b00101,
    "NOR": 0b00110,
    "JUMP": 0b00111,
    "LDS": 0b01000,
    "STS": 0b01001,
    "BREQ": 0b01010,
    "BRNE": 0b01011,
    "BRLT": 0b01100,
    "BRVS": 0b01101,
    "SHL": 0b01110,
    "SHR": 0b01111,
    "SAR": 0b10000,
    "ROL": 0b10001,
    "MUL": 0b10010,
    "ADD.B": 0b10011,
    "SUB.B": 0b10100,
    "MUL.B": 0b10101,
    "DIV": 0b10110,
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


class AsmError(ValueError):
    """Assembly input is invalid."""


def strip_comment(line: str) -> str:
    for marker in ("//", ";", "#"):
        line = line.split(marker, 1)[0]
    return line.strip()


def split_labels(line: str) -> tuple[list[str], str]:
    labels: list[str] = []
    rest = line
    while True:
        match = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*):", rest)
        if not match:
            return labels, rest.strip()
        labels.append(match.group(1))
        rest = rest[match.end() :]


def tokenize(line: str) -> list[str]:
    return [part for part in re.split(r"[\s,]+", line.strip()) if part]


def parse_register(token: str) -> int:
    match = re.fullmatch(r"[Rr](\d+)", token)
    if not match:
        raise AsmError(f"expected register, got {token!r}")
    value = int(match.group(1), 10)
    if not 0 <= value <= 31:
        raise AsmError(f"register out of range: {token!r}")
    return value


def parse_value(token: str, labels: dict[str, int]) -> int:
    if token in labels:
        return labels[token]
    try:
        return int(token.replace("_", ""), 0)
    except ValueError as exc:
        raise AsmError(f"unknown label or number: {token!r}") from exc


def require_width(value: int, bits: int, what: str) -> int:
    mask = (1 << bits) - 1
    if value < 0:
        value = (1 << bits) + value
    if not 0 <= value <= mask:
        raise AsmError(f"{what} {value!r} does not fit in {bits} bits")
    return value & mask


def collect_statements(source: str) -> tuple[list[tuple[int, str]], dict[str, int]]:
    statements: list[tuple[int, str]] = []
    labels: dict[str, int] = {}
    pc = 0

    for line_no, raw in enumerate(source.splitlines(), 1):
        line = strip_comment(raw)
        if not line:
            continue
        found_labels, rest = split_labels(line)
        for label in found_labels:
            if label in labels:
                raise AsmError(f"line {line_no}: duplicate label {label!r}")
            labels[label] = pc
        if rest:
            statements.append((line_no, rest))
            pc += 1

    return statements, labels


def encode_statement(line_no: int, statement: str, labels: dict[str, int]) -> int:
    parts = tokenize(statement)
    if not parts:
        raise AsmError(f"line {line_no}: empty statement")

    mnemonic = parts[0].upper()
    args = parts[1:]
    if mnemonic not in OPCODES:
        raise AsmError(f"line {line_no}: unknown instruction {parts[0]!r}")

    opcode = OPCODES[mnemonic]

    if mnemonic in REG_REG:
        if len(args) != 2:
            raise AsmError(f"line {line_no}: {mnemonic} expects Rx, Ry")
        rx = parse_register(args[0])
        ry = parse_register(args[1])
        return (opcode << 21) | (rx << 16) | (ry << 11)

    if mnemonic in IMM16:
        if len(args) != 2:
            raise AsmError(f"line {line_no}: {mnemonic} expects Rx, imm16")
        rx = parse_register(args[0])
        imm = require_width(parse_value(args[1], labels), 16, "immediate")
        return (opcode << 21) | (rx << 16) | imm

    if mnemonic in BRANCH:
        if len(args) != 3:
            raise AsmError(f"line {line_no}: {mnemonic} expects Rx, Ry, target")
        rx = parse_register(args[0])
        ry = parse_register(args[1])
        target = require_width(parse_value(args[2], labels), 11, "branch target")
        return (opcode << 21) | (rx << 16) | (ry << 11) | target

    if mnemonic == "JUMP":
        if len(args) != 1:
            raise AsmError(f"line {line_no}: JUMP expects target")
        target = require_width(parse_value(args[0], labels), 16, "jump target")
        return (opcode << 21) | target

    raise AsmError(f"line {line_no}: unsupported instruction {mnemonic!r}")


def assemble(source: str) -> list[int]:
    statements, labels = collect_statements(source)
    return [encode_statement(line_no, stmt, labels) for line_no, stmt in statements]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="assembly source")
    parser.add_argument("output", type=Path, help="program memory text output")
    args = parser.parse_args(argv)

    try:
        words = assemble(args.input.read_text(encoding="utf-8"))
    except AsmError as exc:
        print(f"assembler: {exc}", file=sys.stderr)
        return 1

    args.output.write_text(
        "\n".join(f"{word:026b}" for word in words) + "\n",
        encoding="utf-8",
    )
    print(f"assembled {len(words)} instruction(s) -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
