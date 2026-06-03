// =============================================================================
// decode to execute pipeline register
// =============================================================================
// Signal guide:
//   clk,reset       : sequential control for this pipeline register.
//   flush           : inserts a bubble by clearing outputs.
//   stall           : holds the current ID/EX bundle for long EX work.
//   valid_in/out    : marks whether the bundled instruction is live.
//   instr_*         : full instruction word for opcode/branch checks.
//   src_a/src_b_*   : decoded register operand values.
//   imm_*           : immediate/address field extended to 16 bits.
//   rx/ry_*         : destination/source register indexes.
//   *_in/out control: decoded EX/MEM/WB control bits.
module pipe_id_ex(clk,reset,flush,stall,valid_in,instr_in,src_a_in,src_b_in,imm_in,rx_in,ry_in,reg_write_in,mem_read_in,mem_write_in,branch_in,jump_in,
						alu_operation_in,A_invert_in,B_negate_in,simd_mode_in,result_sel_in,dual_write_in,valid_out,instr_out,src_a_out,src_b_out,imm_out,
						rx_out,ry_out,reg_write_out,mem_read_out,mem_write_out,branch_out,jump_out,alu_operation_out,A_invert_out,B_negate_out,simd_mode_out,
						result_sel_out,dual_write_out);

	input clk, reset, flush, stall, valid_in;
	input [25:0] instr_in;
	input [15:0] src_a_in, src_b_in, imm_in;
	input [4:0] rx_in, ry_in, alu_operation_in;
	input reg_write_in, mem_read_in, mem_write_in, branch_in, jump_in, A_invert_in, B_negate_in, simd_mode_in, dual_write_in;
	input [2:0] result_sel_in;
	output reg valid_out;
	output reg [25:0] instr_out;
	output reg [15:0] src_a_out, src_b_out, imm_out;
	output reg [4:0] rx_out, ry_out, alu_operation_out;
	output reg reg_write_out, mem_read_out, mem_write_out, branch_out, jump_out, A_invert_out, B_negate_out, simd_mode_out, dual_write_out;
	output reg [2:0] result_sel_out;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			valid_out <= 1'b0;
			instr_out <= 26'b0;
			src_a_out <= 16'b0;
			src_b_out <= 16'b0;
			imm_out <= 16'b0;
			rx_out <= 5'b0;
			ry_out <= 5'b0;
			reg_write_out <= 1'b0;
			mem_read_out <= 1'b0;
			mem_write_out <= 1'b0;
			branch_out <= 1'b0;
			jump_out <= 1'b0;
			alu_operation_out <= 5'b0;
			A_invert_out <= 1'b0;
			B_negate_out <= 1'b0;
			simd_mode_out <= 1'b0;
			result_sel_out <= 3'b0;
			dual_write_out <= 1'b0;
		end else if (flush) begin
			valid_out <= 1'b0;
			instr_out <= 26'b0;
			src_a_out <= 16'b0;
			src_b_out <= 16'b0;
			imm_out <= 16'b0;
			rx_out <= 5'b0;
			ry_out <= 5'b0;
			reg_write_out <= 1'b0;
			mem_read_out <= 1'b0;
			mem_write_out <= 1'b0;
			branch_out <= 1'b0;
			jump_out <= 1'b0;
			alu_operation_out <= 5'b0;
			A_invert_out <= 1'b0;
			B_negate_out <= 1'b0;
			simd_mode_out <= 1'b0;
			result_sel_out <= 3'b0;
			dual_write_out <= 1'b0;
		end else if (stall) begin
		end else begin
			valid_out <= valid_in;
			instr_out <= instr_in;
			src_a_out <= src_a_in;
			src_b_out <= src_b_in;
			imm_out <= imm_in;
			rx_out <= rx_in;
			ry_out <= ry_in;
			reg_write_out <= reg_write_in;
			mem_read_out <= mem_read_in;
			mem_write_out <= mem_write_in;
			branch_out <= branch_in;
			jump_out <= jump_in;
			alu_operation_out <= alu_operation_in;
			A_invert_out <= A_invert_in;
			B_negate_out <= B_negate_in;
			simd_mode_out <= simd_mode_in;
			result_sel_out <= result_sel_in;
			dual_write_out <= dual_write_in;
		end
	end
endmodule
