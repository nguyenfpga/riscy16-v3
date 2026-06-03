// =============================================================================
// register_16bit.v -- enabled 16-bit register with async reset
// =============================================================================
// Signal guide:
//   clk,reset : sequential control.
//   en        : loads in when high.
//   in        : 16-bit next value.
//   out       : stored 16-bit value.
module register_16bit(clk,reset, en,in,out);
	input clk, en, reset;
	input [15:0] in;
	output reg [15:0] out;

	always@(posedge clk or posedge reset) begin
		if (reset)
			out<=16'b0;
		else begin
			if (en)
				out<=in;
		end
	end
endmodule
