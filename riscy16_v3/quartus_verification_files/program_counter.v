// =============================================================================
// program_counter.v -- 16-bit program counter
// =============================================================================
// Signal guide:
//   clk,reset : sequential PC control.
//   in        : branch/jump target address.
//   address   : current PC value.
//   inc_pc    : increments PC for normal sequential fetch.
//   pc_en     : loads in as the next PC.
//   hold      : keeps address unchanged during stalls.
module program_counter(clk,reset,in,address,inc_pc,pc_en,hold);
	input clk, reset, inc_pc, pc_en, hold;
	input [15:0] in;
	output reg [15:0] address;

	always @(posedge clk or posedge reset) begin
		if (reset)
			address <= 16'b0;
		else if (hold)
			address <= address;
		else if (pc_en)
			address <= in;
		else if (inc_pc)
			address <= address + 1'b1;
	end
endmodule
