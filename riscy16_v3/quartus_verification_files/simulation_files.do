transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

vlog decoder_5to32.v
vlog tri_state_buffer.v
vlog register_16bit.v
vlog register_26bit.v
vlog Register_file.v
vlog fast_adder_4bit.v
vlog fast_adder_16bit.v
vlog fast_adder_32bit.v
vlog ALU_1bit.v
vlog ALU_1bit_msb.v
vlog ALU_16bit.v
vlog mul_pipelined.v
vlog mul_simd_8x8.v
vlog div_ns16.v
vlog instruction_memory.v
vlog data_memory.v
vlog program_counter.v
vlog decode.v
vlog forward_unit.v
vlog hazard_unit.v
vlog pipe_if_id.v
vlog pipe_id_ex.v
vlog pipe_ex_mem.v
vlog pipe_mem_wb.v
vlog processor.v
vlog processor_tb.v

vsim -c processor_tb
run -all
quit -f
