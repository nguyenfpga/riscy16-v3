// =============================================================================
// instruction_memory.v -- 26-bit instruction ROM loaded from program.txt
// =============================================================================
// Signal guide:
//   clk     : present for the processor memory interface.
//   reset   : returns a zero instruction while asserted.
//   address : 16-bit program counter address.
//   op_code : 26-bit instruction word fetched from memory.
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
