// =============================================================================
// pipe_if_id.v -- fetch to decode pipeline register
// =============================================================================
module pipe_if_id(clk,reset,stall,flush,valid_in,pc_in,instr_in,valid_out,pc_out,instr_out);
	input clk, reset, stall, flush, valid_in;
	input [15:0] pc_in;
	input [25:0] instr_in;
	output reg valid_out;
	output reg [15:0] pc_out;
	output reg [25:0] instr_out;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			valid_out <= 1'b0;
			pc_out <= 16'b0;
			instr_out <= 26'b0;
		end else if (flush) begin
			valid_out <= 1'b0;
			pc_out <= 16'b0;
			instr_out <= 26'b0;
		end else if (stall) begin
			valid_out <= valid_out;
			pc_out <= pc_out;
			instr_out <= instr_out;
		end else begin
			valid_out <= valid_in;
			pc_out <= pc_in;
			instr_out <= instr_in;
		end
	end
endmodule
