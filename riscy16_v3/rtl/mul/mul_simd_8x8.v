// =============================================================================
// SIMD packed-byte multiplier: 2 x (8x8 -> 16-bit) lanes
//   product[15:0]  = A[7:0]  * B[7:0]    (low lane)
//   product[31:16] = A[15:8] * B[15:8]   (high lane)
//
// Each 8x8 multiplier uses 8 partial products (16 bits each) reduced through
// a 3-level binary tree of fast_adder_16bit -> 7 CLA instances per lane.
// Total: 14 fast_adder_16bit instances. Critical path = 3 CLA delays.
// =============================================================================
module mul_simd_8x8(A, B, product);
	input  [15:0] A, B;
	output [31:0] product;

	wire [7:0] Al = A[ 7:0];   // low  lane operand from A
	wire [7:0] Bl = B[ 7:0];   // low  lane operand from B
	wire [7:0] Ah = A[15:8];   // high lane operand from A
	wire [7:0] Bh = B[15:8];   // high lane operand from B

	wire [15:0] prod_low;
	wire [15:0] prod_high;

	// =====================================================================
	// LOW LANE: Al * Bl
	// =====================================================================
	wire [15:0] ppL0, ppL1, ppL2, ppL3, ppL4, ppL5, ppL6, ppL7;
	assign ppL0 = Bl[0] ? {8'b0, Al} : 16'b0;
	assign ppL1 = Bl[1] ? {7'b0, Al,  1'b0} : 16'b0;
	assign ppL2 = Bl[2] ? {6'b0, Al,  2'b0} : 16'b0;
	assign ppL3 = Bl[3] ? {5'b0, Al,  3'b0} : 16'b0;
	assign ppL4 = Bl[4] ? {4'b0, Al,  4'b0} : 16'b0;
	assign ppL5 = Bl[5] ? {3'b0, Al,  5'b0} : 16'b0;
	assign ppL6 = Bl[6] ? {2'b0, Al,  6'b0} : 16'b0;
	assign ppL7 = Bl[7] ? {1'b0, Al,  7'b0} : 16'b0;

	wire [15:0] L1_0, L1_1, L1_2, L1_3;
	wire [15:0] L2_0, L2_1;

	fast_adder_16bit FAL_l1_0(.a(ppL0), .b(ppL1), .cin(1'b0), .sum(L1_0), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAL_l1_1(.a(ppL2), .b(ppL3), .cin(1'b0), .sum(L1_1), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAL_l1_2(.a(ppL4), .b(ppL5), .cin(1'b0), .sum(L1_2), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAL_l1_3(.a(ppL6), .b(ppL7), .cin(1'b0), .sum(L1_3), .cout(), .Ggroup_out(), .Pgroup_out());

	fast_adder_16bit FAL_l2_0(.a(L1_0), .b(L1_1), .cin(1'b0), .sum(L2_0), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAL_l2_1(.a(L1_2), .b(L1_3), .cin(1'b0), .sum(L2_1), .cout(), .Ggroup_out(), .Pgroup_out());

	fast_adder_16bit FAL_final(.a(L2_0), .b(L2_1), .cin(1'b0), .sum(prod_low), .cout(), .Ggroup_out(), .Pgroup_out());

	// =====================================================================
	// HIGH LANE: Ah * Bh
	// =====================================================================
	wire [15:0] ppH0, ppH1, ppH2, ppH3, ppH4, ppH5, ppH6, ppH7;
	assign ppH0 = Bh[0] ? {8'b0, Ah} : 16'b0;
	assign ppH1 = Bh[1] ? {7'b0, Ah,  1'b0} : 16'b0;
	assign ppH2 = Bh[2] ? {6'b0, Ah,  2'b0} : 16'b0;
	assign ppH3 = Bh[3] ? {5'b0, Ah,  3'b0} : 16'b0;
	assign ppH4 = Bh[4] ? {4'b0, Ah,  4'b0} : 16'b0;
	assign ppH5 = Bh[5] ? {3'b0, Ah,  5'b0} : 16'b0;
	assign ppH6 = Bh[6] ? {2'b0, Ah,  6'b0} : 16'b0;
	assign ppH7 = Bh[7] ? {1'b0, Ah,  7'b0} : 16'b0;

	wire [15:0] H1_0, H1_1, H1_2, H1_3;
	wire [15:0] H2_0, H2_1;

	fast_adder_16bit FAH_l1_0(.a(ppH0), .b(ppH1), .cin(1'b0), .sum(H1_0), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAH_l1_1(.a(ppH2), .b(ppH3), .cin(1'b0), .sum(H1_1), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAH_l1_2(.a(ppH4), .b(ppH5), .cin(1'b0), .sum(H1_2), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAH_l1_3(.a(ppH6), .b(ppH7), .cin(1'b0), .sum(H1_3), .cout(), .Ggroup_out(), .Pgroup_out());

	fast_adder_16bit FAH_l2_0(.a(H1_0), .b(H1_1), .cin(1'b0), .sum(H2_0), .cout(), .Ggroup_out(), .Pgroup_out());
	fast_adder_16bit FAH_l2_1(.a(H1_2), .b(H1_3), .cin(1'b0), .sum(H2_1), .cout(), .Ggroup_out(), .Pgroup_out());

	fast_adder_16bit FAH_final(.a(H2_0), .b(H2_1), .cin(1'b0), .sum(prod_high), .cout(), .Ggroup_out(), .Pgroup_out());

	// =====================================================================
	// Pack: high lane result in upper 16 bits, low lane in lower 16 bits
	// =====================================================================
	assign product = {prod_high, prod_low};

endmodule
