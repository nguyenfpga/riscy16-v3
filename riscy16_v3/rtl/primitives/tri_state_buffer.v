// =============================================================================
// tri_state_buffer.v -- 16-bit tri-state driver for shared read buses
// =============================================================================
module tri_state_buffer(in,en,out);
	input en;
	input [15:0] in;
	output [15:0] out;

	assign out = en ? in : 16'bz;
endmodule
