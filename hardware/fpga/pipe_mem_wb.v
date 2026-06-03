// =============================================================================
//  memory to writeback pipeline register
// =============================================================================
// Signal guide:
//   clk,reset        : sequential control for this pipeline register.
//   valid_in/out     : marks whether the bundled instruction is live.
//   wb_data_*        : primary writeback value for Rx.
//   write_addr_*     : primary destination register.
//   write_data2_*    : secondary writeback value for Rx+1.
//   write_addr2_*    : secondary destination register.
//   reg_write_*      : enables primary writeback.
//   dual_write_*     : enables secondary writeback.
module pipe_mem_wb(clk,reset,valid_in,wb_data_in,write_addr_in,write_data2_in,write_addr2_in,reg_write_in,dual_write_in,valid_out,wb_data_out,write_addr_out,write_data2_out,write_addr2_out,reg_write_out,dual_write_out);
	input clk, reset, valid_in;
	input [15:0] wb_data_in, write_data2_in;
	input [4:0] write_addr_in, write_addr2_in;
	input reg_write_in, dual_write_in;
	output reg valid_out;
	output reg [15:0] wb_data_out, write_data2_out;
	output reg [4:0] write_addr_out, write_addr2_out;
	output reg reg_write_out, dual_write_out;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			valid_out <= 1'b0;
			wb_data_out <= 16'b0;
			write_data2_out <= 16'b0;
			write_addr_out <= 5'b0;
			write_addr2_out <= 5'b0;
			reg_write_out <= 1'b0;
			dual_write_out <= 1'b0;
		end else begin
			valid_out <= valid_in;
			wb_data_out <= wb_data_in;
			write_data2_out <= write_data2_in;
			write_addr_out <= write_addr_in;
			write_addr2_out <= write_addr2_in;
			reg_write_out <= reg_write_in;
			dual_write_out <= dual_write_in;
		end
	end
endmodule
