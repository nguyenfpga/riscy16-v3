module register_26bit(clk,reset, en,in,out);
	input clk, en, reset;
	input [25:0] in;
	output reg [25:0] out;

	always@(posedge clk or posedge reset) begin
		if (reset)
			out<=26'b0;
		else begin
			if (en)
				out<=in;
		end
	end
endmodule