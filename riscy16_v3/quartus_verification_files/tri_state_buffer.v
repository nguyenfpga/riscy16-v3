// =============================================================================
// tri_state_buffer.v -- 16-bit tri-state driver for shared read buses
// =============================================================================
// Signal guide:
//   in  : 16-bit value driven when enabled.
//   en  : drives in onto out when high.
//   out : shared 16-bit bus, otherwise high impedance.
module tri_state_buffer(in,en,out);
	input en;
	input [15:0] in;
	output [15:0] out;

	assign out = en ? in : 16'bz;
endmodule
