#!/usr/bin/env python3
"""Architectural instruction-set simulator for RISCY-16 v3."""

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


def u16(value: int) -> int:
    return value & 0xFFFF


def s16(value: int) -> int:
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def strip_comment(line: str) -> str:
    for marker in ("//", ";", "#"):
        line = line.split(marker, 1)[0]
    return line.strip()


def read_program(path: Path) -> list[int]:
    words: list[int] = []
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = strip_comment(raw).replace("_", "")
        if not line:
            continue
        if len(line) == 26 and set(line) <= {"0", "1"}:
            words.append(int(line, 2))
            continue
        try:
            words.append(int(line, 0) & 0x3FFFFFF)
        except ValueError as exc:
            raise ValueError(f"line {line_no}: invalid instruction word {line!r}") from exc
    return words


class Machine:
    def __init__(self, program: list[int]) -> None:
        self.program = program
        self.reg = [0] * 32
        self.mem: dict[int, int] = {}
        self.pc = 0
        self.cycles = 0
        self.halted = False

    def write_reg(self, index: int, value: int) -> None:
        index &= 0x1F
        if index != 0:
            self.reg[index] = u16(value)

    def step(self) -> None:
        if not 0 <= self.pc < len(self.program):
            self.halted = True
            return

        word = self.program[self.pc]
        opcode = (word >> 21) & 0x1F
        rx = (word >> 16) & 0x1F
        ry = (word >> 11) & 0x1F
        imm16 = word & 0xFFFF
        target11 = word & 0x7FF
        next_pc = self.pc + 1
        a = self.reg[rx]
        b = self.reg[ry]
        mnemonic = MNEMONICS.get(opcode, "UNKNOWN")

        if mnemonic == "LDI":
            self.write_reg(rx, imm16)
        elif mnemonic == "MOV":
            self.write_reg(rx, b)
        elif mnemonic == "ADD":
            self.write_reg(rx, a + b)
        elif mnemonic == "SUB":
            self.write_reg(rx, a - b)
        elif mnemonic == "OR":
            self.write_reg(rx, a | b)
        elif mnemonic == "AND":
            self.write_reg(rx, a & b)
        elif mnemonic == "NOR":
            self.write_reg(rx, ~(a | b))
        elif mnemonic == "JUMP":
            next_pc = imm16
            if next_pc == self.pc:
                self.halted = True
        elif mnemonic == "LDS":
            self.write_reg(rx, self.mem.get(imm16, 0))
        elif mnemonic == "STS":
            self.mem[imm16] = a
        elif mnemonic == "BREQ":
            if a == b:
                next_pc = target11
        elif mnemonic == "BRNE":
            if a != b:
                next_pc = target11
        elif mnemonic == "BRLT":
            if s16(a) < s16(b):
                next_pc = target11
        elif mnemonic == "BRVS":
            total = s16(a) + s16(b)
            if total < -32768 or total > 32767:
                next_pc = target11
        elif mnemonic == "SHL":
            self.write_reg(rx, a << (b & 0xF))
        elif mnemonic == "SHR":
            self.write_reg(rx, a >> (b & 0xF))
        elif mnemonic == "SAR":
            self.write_reg(rx, s16(a) >> (b & 0xF))
        elif mnemonic == "ROL":
            shift = b & 0xF
            self.write_reg(rx, (a << shift) | (a >> (16 - shift if shift else 16)))
        elif mnemonic == "MUL":
            product = a * b
            self.write_reg(rx, product)
            self.write_reg(rx + 1, product >> 16)
        elif mnemonic == "ADD.B":
            lo = (a & 0xFF) + (b & 0xFF)
            hi = ((a >> 8) & 0xFF) + ((b >> 8) & 0xFF)
            self.write_reg(rx, ((hi & 0xFF) << 8) | (lo & 0xFF))
        elif mnemonic == "SUB.B":
            lo = (a & 0xFF) - (b & 0xFF)
            hi = ((a >> 8) & 0xFF) - ((b >> 8) & 0xFF)
            self.write_reg(rx, ((hi & 0xFF) << 8) | (lo & 0xFF))
        elif mnemonic == "MUL.B":
            lo = (a & 0xFF) * (b & 0xFF)
            hi = ((a >> 8) & 0xFF) * ((b >> 8) & 0xFF)
            self.write_reg(rx, lo)
            self.write_reg(rx + 1, hi)
        elif mnemonic == "DIV":
            if b == 0:
                self.write_reg(rx, 0xFFFF)
                self.write_reg(rx + 1, a)
            else:
                self.write_reg(rx, a // b)
                self.write_reg(rx + 1, a % b)
        else:
            raise RuntimeError(f"unsupported opcode {opcode:05b} at pc {self.pc}")

        self.reg[0] = 0
        self.pc = next_pc & 0xFFFF
        self.cycles += 1

    def run(self, max_cycles: int) -> None:
        while not self.halted and self.cycles < max_cycles:
            self.step()
        if not self.halted and self.cycles >= max_cycles:
            raise RuntimeError(f"stopped after max cycle count ({max_cycles})")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("program", type=Path, help="program memory text file")
    parser.add_argument("--max-cycles", type=int, default=512)
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args(argv)

    try:
        machine = Machine(read_program(args.program))
        machine.run(args.max_cycles)
    except (RuntimeError, ValueError) as exc:
        print(f"iss: {exc}", file=sys.stderr)
        return 1

    if not args.quiet:
        print(f"cycles={machine.cycles} pc={machine.pc}")
        for index, value in enumerate(machine.reg):
            if value:
                print(f"R{index}=0x{value:04X}")
        for addr in sorted(machine.mem):
            print(f"MEM[{addr}]=0x{machine.mem[addr]:04X}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
