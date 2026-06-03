// =============================================================================
// data_memory.v -- 16-bit data RAM for load/store instructions
// =============================================================================
// Signal guide:
//   clk           : writes occur on the rising edge.
//   reset         : forces read output to zero while asserted.
//   write_en      : writes data_in to mem[address].
//   out_sig       : enables combinational readback on data_out.
//   address       : 16-bit memory address.
//   data_in       : store data from the processor.
//   data_out      : load data returned to the processor.
module data_memory(clk,reset,write_en,address,data_in,data_out,out_sig);
	input clk, reset, write_en, out_sig;
	input [15:0] address;
	input [15:0] data_in;
	output [15:0] data_out;

	reg [15:0] mem [0:1000];

	always @(posedge clk) begin
		if (write_en)
			mem[address] <= data_in;
	end

	assign data_out = (reset | ~out_sig) ? 16'b0 : mem[address];
endmodule
