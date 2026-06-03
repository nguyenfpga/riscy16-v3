transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

vlog rtl/primitives/decoder_5to32.v
vlog rtl/primitives/tri_state_buffer.v
vlog rtl/regfile/register_16bit.v
vlog rtl/regfile/register_26bit.v
vlog rtl/regfile/Register_file.v
vlog rtl/adders/fast_adder_4bit.v
vlog rtl/adders/fast_adder_16bit.v
vlog rtl/adders/fast_adder_32bit.v
vlog rtl/alu/ALU_1bit.v
vlog rtl/alu/ALU_1bit_msb.v
vlog rtl/alu/ALU_16bit.v
vlog rtl/mul/mul_pipelined.v
vlog rtl/mul/mul_simd_8x8.v
vlog rtl/mul/div_ns16.v
vlog rtl/mem/instruction_memory.v
vlog rtl/mem/data_memory.v
vlog rtl/pc/program_counter.v
vlog rtl/core/decode.v
vlog rtl/core/forward_unit.v
vlog rtl/core/hazard_unit.v
vlog rtl/core/pipe_if_id.v
vlog rtl/core/pipe_id_ex.v
vlog rtl/core/pipe_ex_mem.v
vlog rtl/core/pipe_mem_wb.v
vlog rtl/core/processor.v
vlog tb/processor_tb.v

vsim -c processor_tb
run -all
quit -f
