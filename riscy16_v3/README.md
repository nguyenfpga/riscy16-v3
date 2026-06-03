# RISCY-16 v3 Core

This directory contains the active RISCY-16 v3 processor implementation. The
design keeps the legacy 26-bit instruction word while moving the core into a
five-stage in-order pipeline with explicit pipeline registers, forwarding,
hazard detection, branch flushing, and multi-cycle divide support.

## Implemented Features

- 32 x 16-bit register file with `R0` held at zero.
- 26-bit fixed-width instruction memory loaded from `program.txt`.
- IF, ID, EX, MEM, and WB pipeline stages.
- Data forwarding from EX/MEM and MEM/WB into decode and execute operands.
- Load-use interlock and divide stall handling.
- Execute-stage branch and jump redirect with fetch/decode flush.
- Scalar add, subtract, logic, shift, rotate, load, store, branch, and jump.
- Packed-byte SIMD add, subtract, and multiply.
- 16-cycle unsigned divider with quotient/remainder dual writeback.
- ModelSim/Questa regression testbench.
- Python assembler, disassembler, ISS, and source-tree sanity checker.

## Commands

```sh
make assemble
make iss
make synth-check
```

`make assemble` rebuilds `program.txt` from `tests/basic.asm`.
`make iss` runs the architectural simulator against `program.txt`.
`make synth-check` validates the active source list used by `sim/run.do`.

Run the RTL regression with ModelSim/Questa:

```sh
make sim
```

The testbench checks the bundled program and should print
`*** ALL TESTS PASSED ***`.

## Documentation

- `docs/ISA.md` describes the instruction encoding.
- `docs/ARCH.md` describes the top-level microarchitecture.
- `docs/PIPELINE.md` describes stage flow, bypassing, stalls, and redirects.
- `CHANGES.md` records staged project changes.

## Notes

The source tree also contains planned extension areas for branch prediction,
caches, MMIO, peripherals, and richer verification. Those pieces are not part
of the active simulation path until they are wired into `sim/run.do` and the
top-level processor.

## License

This project is licensed under the MIT License. See [../LICENSE](../LICENSE).
