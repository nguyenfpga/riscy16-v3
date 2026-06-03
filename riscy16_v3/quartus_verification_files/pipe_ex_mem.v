// =============================================================================
// execute to memory pipeline register
// =============================================================================
// Signal guide:
//   clk,reset        : sequential control for this pipeline register.
//   flush            : clears valid/control/data outputs.
//   valid_in/out     : marks whether the bundled instruction is live.
//   result_*         : EX result or selected functional-unit result.
//   store_data_*     : value written by store instructions.
//   mem_addr_*       : data memory address.
//   write_addr*      : destination registers for writeback.
//   write_data2_*    : second writeback value for Rx+1.
//   reg/mem/dual_*   : control bits passed toward MEM/WB.
module pipe_ex_mem(clk,reset,flush,valid_in,result_in,store_data_in,mem_addr_in,write_addr_in,write_addr2_in,write_data2_in,reg_write_in,mem_read_in,
						mem_write_in,dual_write_in,valid_out,result_out,store_data_out,mem_addr_out,write_addr_out,write_addr2_out,write_data2_out,
						reg_write_out,mem_read_out,mem_write_out,dual_write_out);
	input clk, reset, flush, valid_in;
	input [15:0] result_in, store_data_in, mem_addr_in, write_data2_in;
	input [4:0] write_addr_in, write_addr2_in;
	input reg_write_in, mem_read_in, mem_write_in, dual_write_in;
	output reg valid_out;
	output reg [15:0] result_out, store_data_out, mem_addr_out, write_data2_out;
	output reg [4:0] write_addr_out, write_addr2_out;
	output reg reg_write_out, mem_read_out, mem_write_out, dual_write_out;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			valid_out <= 1'b0;
			result_out <= 16'b0;
			store_data_out <= 16'b0;
			mem_addr_out <= 16'b0;
			write_data2_out <= 16'b0;
			write_addr_out <= 5'b0;
			write_addr2_out <= 5'b0;
			reg_write_out <= 1'b0;
			mem_read_out <= 1'b0;
			mem_write_out <= 1'b0;
			dual_write_out <= 1'b0;
		end else if (flush) begin
			valid_out <= 1'b0;
			result_out <= 16'b0;
			store_data_out <= 16'b0;
			mem_addr_out <= 16'b0;
			write_data2_out <= 16'b0;
			write_addr_out <= 5'b0;
			write_addr2_out <= 5'b0;
			reg_write_out <= 1'b0;
			mem_read_out <= 1'b0;
			mem_write_out <= 1'b0;
			dual_write_out <= 1'b0;
		end else begin
			valid_out <= valid_in;
			result_out <= result_in;
			store_data_out <= store_data_in;
			mem_addr_out <= mem_addr_in;
			write_data2_out <= write_data2_in;
			write_addr_out <= write_addr_in;
			write_addr2_out <= write_addr2_in;
			reg_write_out <= reg_write_in;
			mem_read_out <= mem_read_in;
			mem_write_out <= mem_write_in;
			dual_write_out <= dual_write_in;
		end
	end
endmodule
