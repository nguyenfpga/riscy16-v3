// =============================================================================
// pipe_ex_mem.v -- execute to memory pipeline register
// =============================================================================
module pipe_ex_mem(clk,reset,flush,valid_in,result_in,store_data_in,mem_addr_in,write_addr_in,write_addr2_in,write_data2_in,reg_write_in,mem_read_in,mem_write_in,dual_write_in,valid_out,result_out,store_data_out,mem_addr_out,write_addr_out,write_addr2_out,write_data2_out,reg_write_out,mem_read_out,mem_write_out,dual_write_out);
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
