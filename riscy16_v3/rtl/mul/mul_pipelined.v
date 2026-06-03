// =============================================================================
// mul_pipelined.v -- stage 1 scalar multiply datapath placeholder
//   This keeps the v1 structural reduction tree under the v3 module name.
//   Later stages will insert Booth recoding and pipeline registers.
// =============================================================================
module mul_pipelined(A,B,product);
	input [15:0] A, B;
	output [31:0] product;

	wire [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
	wire [31:0] pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15;

	assign pp0  = B[0]  ? {16'b0, A} : 32'b0;
	assign pp1  = B[1]  ? {15'b0, A, 1'b0} : 32'b0;
	assign pp2  = B[2]  ? {14'b0, A, 2'b0} : 32'b0;
	assign pp3  = B[3]  ? {13'b0, A, 3'b0} : 32'b0;
	assign pp4  = B[4]  ? {12'b0, A, 4'b0} : 32'b0;
	assign pp5  = B[5]  ? {11'b0, A, 5'b0} : 32'b0;
	assign pp6  = B[6]  ? {10'b0, A, 6'b0} : 32'b0;
	assign pp7  = B[7]  ? {9'b0, A, 7'b0} : 32'b0;
	assign pp8  = B[8]  ? {8'b0, A, 8'b0} : 32'b0;
	assign pp9  = B[9]  ? {7'b0, A, 9'b0} : 32'b0;
	assign pp10 = B[10] ? {6'b0, A, 10'b0} : 32'b0;
	assign pp11 = B[11] ? {5'b0, A, 11'b0} : 32'b0;
	assign pp12 = B[12] ? {4'b0, A, 12'b0} : 32'b0;
	assign pp13 = B[13] ? {3'b0, A, 13'b0} : 32'b0;
	assign pp14 = B[14] ? {2'b0, A, 14'b0} : 32'b0;
	assign pp15 = B[15] ? {1'b0, A, 15'b0} : 32'b0;

	wire [31:0] l1_0, l1_1, l1_2, l1_3, l1_4, l1_5, l1_6, l1_7;
	wire [31:0] l2_0, l2_1, l2_2, l2_3;
	wire [31:0] l3_0, l3_1;

	fast_adder_32bit FA_l1_0(.a(pp0), .b(pp1), .cin(1'b0), .sum(l1_0), .cout());
	fast_adder_32bit FA_l1_1(.a(pp2), .b(pp3), .cin(1'b0), .sum(l1_1), .cout());
	fast_adder_32bit FA_l1_2(.a(pp4), .b(pp5), .cin(1'b0), .sum(l1_2), .cout());
	fast_adder_32bit FA_l1_3(.a(pp6), .b(pp7), .cin(1'b0), .sum(l1_3), .cout());
	fast_adder_32bit FA_l1_4(.a(pp8), .b(pp9), .cin(1'b0), .sum(l1_4), .cout());
	fast_adder_32bit FA_l1_5(.a(pp10), .b(pp11), .cin(1'b0), .sum(l1_5), .cout());
	fast_adder_32bit FA_l1_6(.a(pp12), .b(pp13), .cin(1'b0), .sum(l1_6), .cout());
	fast_adder_32bit FA_l1_7(.a(pp14), .b(pp15), .cin(1'b0), .sum(l1_7), .cout());
	fast_adder_32bit FA_l2_0(.a(l1_0), .b(l1_1), .cin(1'b0), .sum(l2_0), .cout());
	fast_adder_32bit FA_l2_1(.a(l1_2), .b(l1_3), .cin(1'b0), .sum(l2_1), .cout());
	fast_adder_32bit FA_l2_2(.a(l1_4), .b(l1_5), .cin(1'b0), .sum(l2_2), .cout());
	fast_adder_32bit FA_l2_3(.a(l1_6), .b(l1_7), .cin(1'b0), .sum(l2_3), .cout());
	fast_adder_32bit FA_l3_0(.a(l2_0), .b(l2_1), .cin(1'b0), .sum(l3_0), .cout());
	fast_adder_32bit FA_l3_1(.a(l2_2), .b(l2_3), .cin(1'b0), .sum(l3_1), .cout());
	fast_adder_32bit FA_final(.a(l3_0), .b(l3_1), .cin(1'b0), .sum(product), .cout());
endmodule
