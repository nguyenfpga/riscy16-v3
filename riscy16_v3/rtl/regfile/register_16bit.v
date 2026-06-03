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