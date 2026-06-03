# Quartus Verification File Bundle

This folder is a flat copy of the Verilog files needed to compile and simulate
the current RISCY-16 v3 pipeline shell without browsing the full source tree.

## Top Modules

- Synthesis/top-level RTL: `processor.v`
- Simulation testbench: `processor_tb.v`

## Included Support File

- `program.txt` is the instruction memory image used by `instruction_memory.v`
  and the regression testbench.

## Quartus Use

Add the RTL files listed in `rtl_files.qsf` to a Quartus project and set
`processor` as the top-level entity. The testbench is intentionally listed
separately in `simulation_files.do` because Quartus synthesis should not compile
`processor_tb.v`.

## ModelSim/Questa Use

From this folder, run the commands in `simulation_files.do` in ModelSim/Questa.
The testbench should print `*** ALL TESTS PASSED ***`.
