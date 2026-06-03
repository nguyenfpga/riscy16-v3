# Pipeline

The RISCY-16 v3 core uses an in-order five-stage pipeline:

```text
IF -> ID -> EX -> MEM -> WB
```

## IF

The fetch stage reads `instruction_memory` at the current PC. The PC normally
increments while the processor is running. It holds during reset, before
`start`, during load-use stalls, and while the divider is busy.

## ID

Decode extracts `Rx`, `Ry`, and the immediate field, reads the register file,
and produces control signals. Forwarding is also applied in decode so branch
and operand values can see newer EX/MEM or MEM/WB results when available.

## EX

Execute performs ALU, shift, rotate, multiply, SIMD, divide, branch, and jump
work. Branches and jumps resolve in EX. A taken redirect flushes the fetch and
decode path so the wrong-path instruction does not retire.

The divider asserts a wait condition for the active divide instruction until
the quotient and remainder are ready. Divide by zero completes immediately with
quotient `0xffff` and remainder equal to the dividend.

## MEM

Loads select data memory output for writeback. Stores write `Rx` data to the
address carried in the instruction immediate field.

## WB

Writeback updates `Rx` for normal register-writing instructions. Dual-write
operations also write `Rx+1`.

## Hazards

`hazard_unit` detects load-use dependencies when the instruction in ID needs a
register that the instruction in EX is still loading from memory. The PC and
IF/ID register hold for one cycle while ID/EX receives a bubble.

`forward_unit` can forward from:

- EX/MEM primary result.
- EX/MEM secondary dual-write result.
- MEM/WB primary result.
- MEM/WB secondary dual-write result.

Memory loads are not forwarded from EX/MEM because the loaded value is not
available until the memory stage.
