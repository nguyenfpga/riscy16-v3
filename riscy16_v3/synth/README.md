# Synthesis Notes

The active simulation/synthesis entry point is `rtl/core/processor.v`.

This directory is reserved for timing constraints and synthesis-specific
documentation. `processor.sdc` can hold clock and IO constraints when a target
tool flow is selected. The DE1-SoC FPGA wrapper has its Quartus project files
under `../hardware/fpga` at the repository root.

For a tool-independent source sanity check, run:

```sh
make synth-check
```

That check validates the active Verilog list used by `sim/run.do`; it does not
replace full synthesis in Quartus, Yosys, or another FPGA/ASIC flow.
