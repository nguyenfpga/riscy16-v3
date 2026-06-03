# Architecture

RISCY-16 v3 is a five-stage in-order processor built around a 16-bit datapath
and a fixed 26-bit instruction word. The current top-level module is
`rtl/core/processor.v`.

## Top-Level Blocks

- `program_counter` holds the fetch address and supports increment, hold, and
  redirected target loads.
- `instruction_memory` is a 65,536-entry 26-bit ROM initialized with
  `program.txt`.
- `decode` maps the 5-bit opcode to control signals, operand-use hints, ALU
  controls, result selection, and dual-write controls.
- `Register_file` provides two read ports and two write ports for multiply,
  SIMD multiply, and divide result pairs.
- `ALU_16bit` implements scalar arithmetic/logic plus shifts, rotates, and
  packed-byte SIMD add/subtract.
- `mul_pipelined` and `mul_simd_8x8` produce scalar and packed-byte products.
- `div_ns16` is a 16-cycle unsigned non-restoring divider.
- `data_memory` is a 65,536-entry 16-bit RAM with synchronous write and
  asynchronous read.

## Data Path

The core uses explicit wires and pipeline registers rather than internal
tri-state buses. ALU, multiply, SIMD multiply, divide, load, and immediate
results are selected in execute/memory before reaching writeback.

Dual-write operations use `Rx` for the low/result value and `Rx+1` for the
high/remainder value:

- `MUL`: low 16 bits to `Rx`, high 16 bits to `Rx+1`.
- `MUL.B`: low-lane byte product to `Rx`, high-lane byte product to `Rx+1`.
- `DIV`: quotient to `Rx`, remainder to `Rx+1`.

## Memory Model

Instruction and data memories are separate arrays. The instruction memory is
loaded once at elaboration with `$readmemb("program.txt", mem)`. The data
memory has no reset initialization and is written by `STS`.

## FPGA Wrapper

`hardware/fpga` contains a DE1-SoC-facing wrapper that exposes register/PC
state through switches, LEDs, and seven-segment displays. It keeps a local
copy of the active RTL files needed for Quartus builds.
