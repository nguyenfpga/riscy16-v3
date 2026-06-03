// =============================================================================
// fast_adder_32bit.v -- 32-bit adder from two 16-bit CLA blocks
// =============================================================================
// Signal guide:
//   a,b     : 32-bit add operands.
//   cin     : carry input into the low half.
//   sum     : 32-bit sum output.
//   cout    : carry output from the high half.
//   mid_carry: carry between low and high 16-bit adders.
module fast_adder_32bit(
	input  [31:0] a,
	input  [31:0] b,
	input         cin,
	output [31:0] sum,
	output        cout
);
	wire mid_carry;

	fast_adder_16bit fa_low (.a(a[15:0]),  .b(b[15:0]),  .cin(cin),
	                        .sum(sum[15:0]),  .cout(mid_carry),
	                        .Ggroup_out(), .Pgroup_out());

	fast_adder_16bit fa_high(.a(a[31:16]), .b(b[31:16]), .cin(mid_carry),
	                        .sum(sum[31:16]), .cout(cout),
	                        .Ggroup_out(), .Pgroup_out());

endmodule
