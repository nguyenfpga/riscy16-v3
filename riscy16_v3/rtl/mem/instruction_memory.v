// =============================================================================
// instruction_memory.v -- 26-bit instruction ROM for pipeline fetch
//   The array remains visible to the legacy regression testbench.
// =============================================================================
module instruction_memory(clk,reset,address,op_code);
	input clk, reset;
	input [15:0] address;
	output [25:0] op_code;

	reg [25:0] mem [0:65535];

	initial begin
		$readmemb("program.txt", mem);
	end

	assign op_code = reset ? 26'b0 : mem[address];
endmodule
