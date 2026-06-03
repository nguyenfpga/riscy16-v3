# RISCY-16 v3 ISA

RISCY-16 v3 keeps the legacy 26-bit instruction word. Bits are numbered from
most significant to least significant:

```text
25          21 20          16 15          11 10          0
+--------------+--------------+--------------+-------------+
| opcode[4:0]  | rx[4:0]      | ry[4:0]      | low[10:0]   |
+--------------+--------------+--------------+-------------+
```

For immediate, load, store, and jump forms, bits `[15:0]` are used as a 16-bit
immediate/address field. For conditional branches, bits `[10:0]` hold the
branch target and `rx`/`ry` name the comparison registers.

All register names are `R0` through `R31`. `R0` is hardwired to zero.

## Instruction Set

| Opcode | Mnemonic | Form | Operation |
| --- | --- | --- | --- |
| `00000` | `LDI` | `LDI Rx, imm16` | `Rx = imm16` |
| `00001` | `MOV` | `MOV Rx, Ry` | `Rx = Ry` |
| `00010` | `ADD` | `ADD Rx, Ry` | `Rx = Rx + Ry` |
| `00011` | `SUB` | `SUB Rx, Ry` | `Rx = Rx - Ry` |
| `00100` | `OR` | `OR Rx, Ry` | `Rx = Rx \| Ry` |
| `00101` | `AND` | `AND Rx, Ry` | `Rx = Rx & Ry` |
| `00110` | `NOR` | `NOR Rx, Ry` | `Rx = ~(Rx \| Ry)` |
| `00111` | `JUMP` | `JUMP target` | `PC = target` |
| `01000` | `LDS` | `LDS Rx, addr16` | `Rx = MEM[addr16]` |
| `01001` | `STS` | `STS Rx, addr16` | `MEM[addr16] = Rx` |
| `01010` | `BREQ` | `BREQ Rx, Ry, target` | branch when `Rx == Ry` |
| `01011` | `BRNE` | `BRNE Rx, Ry, target` | branch when `Rx != Ry` |
| `01100` | `BRLT` | `BRLT Rx, Ry, target` | branch when signed `Rx < Ry` |
| `01101` | `BRVS` | `BRVS Rx, Ry, target` | branch on signed add overflow |
| `01110` | `SHL` | `SHL Rx, Ry` | `Rx = Rx << Ry[3:0]` |
| `01111` | `SHR` | `SHR Rx, Ry` | `Rx = Rx >> Ry[3:0]` |
| `10000` | `SAR` | `SAR Rx, Ry` | arithmetic right shift by `Ry[3:0]` |
| `10001` | `ROL` | `ROL Rx, Ry` | rotate left by `Ry[3:0]` |
| `10010` | `MUL` | `MUL Rx, Ry` | `{Rx+1, Rx} = Rx * Ry` |
| `10011` | `ADD.B` | `ADD.B Rx, Ry` | two independent unsigned byte adds |
| `10100` | `SUB.B` | `SUB.B Rx, Ry` | two independent unsigned byte subtracts |
| `10101` | `MUL.B` | `MUL.B Rx, Ry` | low byte product to `Rx`, high byte product to `Rx+1` |
| `10110` | `DIV` | `DIV Rx, Ry` | `Rx = quotient`, `Rx+1 = remainder` |

`Rx+1` wraps through the 5-bit register index. Writes to `R0` are ignored by
the register file.

## Assembly Syntax

The bundled assembler accepts one instruction per line. Comments start with
`;`, `#`, or `//`. Labels use `name:` and can be used as jump or branch
targets.

```asm
start:
    ldi r1, 5
    ldi r2, 10
    add r1, r2
halt:
    jump halt
```
