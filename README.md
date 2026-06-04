# RISCY-16 v3

RISCY-16 v3 is a Verilog implementation of a 16-bit educational processor that is being migrated from a legacy multi-cycle bus design into a five-stage in-order pipeline. The repository includes the active RTL, a regression testbench, Python tooling for the sample program, architecture notes, and a DE1-SoC FPGA wrapper.


## Repository Layout

- `riscy16_v3/rtl/` - active CPU RTL, organized by core, ALU, memory, multiply/divide, register file, and primitives.
- `riscy16_v3/tb/processor_tb.v` - main regression testbench for the pipeline shell.
- `riscy16_v3/sim/run.do` - ModelSim/Questa script for compiling and running the active simulation.
- `riscy16_v3/tests/basic.asm` - source for the bundled regression program.
- `riscy16_v3/program.txt` - assembled instruction-memory image loaded by `$readmemb`.
- `riscy16_v3/tools/` - assembler, disassembler, simple linker, and source-tree checks.
- `riscy16_v3/docs/` - ISA, architecture, and pipeline notes.
- `hardware/fpga/` - DE1-SoC FPGA wrapper and Quartus project sources.

Generated simulator and Quartus directories such as `work/`, `db/`, `incremental_db/`, `output_files/`, waveforms, transcripts, and `.sof` files are intentionally ignored.

## Quick Start

From `riscy16_v3`:

```sh
make assemble
make iss
make synth-check
```

Run the RTL regression with ModelSim/Questa:

```sh
make sim
```

The simulation script expects `program.txt` in the `riscy16_v3` working directory and should finish with `*** ALL TESTS PASSED ***` when the RTL and simulator environment are aligned.

## Status

The active design implements the five-stage pipeline shell, forwarding, load-use interlock, branch flushing, scalar ALU operations, packed-byte SIMD add/sub/multiply, unsigned divide, data memory, and instruction ROM. Some future-extension directories are present locally as planning scaffolds, but the clean GitHub project focuses on the implemented core, documentation, and reproducible sample program flow.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
