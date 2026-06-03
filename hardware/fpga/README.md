# RISCY-16 v3 DE1-SoC FPGA Wrapper

This folder adds an FPGA-facing wrapper for the simulation-only RISCY-16 v3 project in `riscy16_v3/quartus_verification_files`. It follows the board wiring and display style from the reference project at `D:\Verilog proj\Advance Hardware`, and contains local copies of the processor RTL files needed for a Quartus FPGA build.

## Pin Map

- `CLOCK_50`: 50 MHz DE1-SoC clock.
- `SW[9]`: reset, active high.
- `SW[8]`: start, releases the processor from its reset/idle hold.
- `SW[7]`: view mode, `0` shows the selected register and `1` shows PC.
- `SW[4:0]`: register number to display when `SW[7] = 0`.
- `HEX4..HEX0`: five decimal digits for the selected 16-bit value.
- `HEX5`: blank, `7'b1111111`.
- `LEDR[6:0]`: pipeline/control debug state.
- `LEDR[7]`: view-mode indicator, lit when viewing PC.
- `LEDR[9:8]`: tied to `2'b00`.
- `KEY[3:0]`: present for the board pin contract, unused.

The CPU runs directly on `CLOCK_50`; there is no 1 Hz divider in this FPGA wrapper.

## Wrapped Simulation Files

`riscy16_v3_fpga.v` is an FPGA-instrumented copy of `riscy16_v3/quartus_verification_files/processor.v`. The original simulation file is not edited. The wrapper copy preserves the processor datapath/control and adds these debug taps:

- `view_addr`: register index selected by `SW[4:0]`.
- `view_reg`: value from a passive 32 x 16 shadow register file.
- `view_pc`: current 16-bit PC / instruction address.
- `view_state`: 7-bit pipeline/control activity vector.

The shadow register file snoops the simulation processor writeback signals:

- primary write port: `wb_write_en`, `wb_addr`, `wb_data`
- secondary write port: `wb_write_en2`, `wb_addr2`, `wb_data2`

The register file is 32 registers x 16 bits. Register `R0` is hardwired to zero in the real register file, so the shadow array also ignores writes to address zero.

## Assumptions And Deviations

- The v3 processor is a five-stage pipeline, not the reference single-bus FSM. There is no single `current_state` register to expose. Therefore `view_state` is a compact debug vector:
  `{running, div_wait, load_use_stall, mem_wb_valid, ex_mem_valid, id_ex_valid, if_id_valid}`.
- `bin_to_bcd16.v` and `seg7_decoder.v` are copied/equivalent display helpers from the reference board project. `seg7_decoder.v` has only a banner comment added in this folder to match the requested header style; the reference original was not modified.
- `instruction_memory.v` loads `program.txt` using `$readmemb("program.txt", mem)`. For Quartus, keep `program.txt` available in the Quartus project working directory or add it as a memory initialization/support file.

## Quartus File List

Add these files from `hardware/fpga`:

- `fpga_top.v`
- `riscy16_v3_fpga.v`
- `bin_to_bcd16.v`
- `seg7_decoder.v`
- `ALU_16bit.v`
- `ALU_1bit.v`
- `ALU_1bit_msb.v`
- `data_memory.v`
- `decode.v`
- `decoder_5to32.v`
- `div_ns16.v`
- `fast_adder_16bit.v`
- `fast_adder_32bit.v`
- `fast_adder_4bit.v`
- `forward_unit.v`
- `hazard_unit.v`
- `instruction_memory.v`
- `mul_pipelined.v`
- `mul_simd_8x8.v`
- `pipe_ex_mem.v`
- `pipe_id_ex.v`
- `pipe_if_id.v`
- `pipe_mem_wb.v`
- `program_counter.v`
- `register_16bit.v`
- `register_26bit.v`
- `Register_file.v`
- `tri_state_buffer.v`

Also include `hardware/fpga/program.txt` for instruction memory initialization. Do not add `processor.v` or `processor_tb.v` to the FPGA build; `riscy16_v3_fpga.v` replaces the simulation top for the board.
