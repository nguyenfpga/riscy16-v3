// =============================================================================
// data_memory.v -- 16-bit data RAM with synchronous write and async read
//   The memory array name is preserved for regression testbench inspection.
// =============================================================================
module data_memory(clk,reset,write_en,address,data_in,data_out,out_sig);
	input clk, reset, write_en, out_sig;
	input [15:0] address;
	input [15:0] data_in;
	output [15:0] data_out;

	reg [15:0] mem [0:65535];

	always @(posedge clk) begin
		if (write_en)
			mem[address] <= data_in;
	end

	assign data_out = (reset | ~out_sig) ? 16'b0 : mem[address];
endmodule
