// =============================================================================
// fast_adder_16bit.v -- 16-bit carry-lookahead adder from four 4-bit blocks
// =============================================================================
// Signal guide:
//   a,b                  : 16-bit add operands.
//   cin                  : carry input into bit 0.
//   sum                  : 16-bit sum output.
//   cout                 : carry output from bit 15.
//   Ggroup_out,Pgroup_out: block generate/propagate for parent adders.
module fast_adder_16bit(
    input  [15:0] a,
    input  [15:0] b,
    input         cin,
    output [15:0] sum,
    output        cout,
	 output Ggroup_out, Pgroup_out
);
    wire [3:0] Pgroup, Ggroup;
    wire c4, c8, c12;
    wire [3:0] block_cout;  // optional, not needed for top-level carry logic

    // Second-level carry lookahead between 4-bit blocks
    assign c4  = Ggroup[0] | (Pgroup[0] & cin);

    assign c8  = Ggroup[1] |
                 (Pgroup[1] & Ggroup[0]) |
                 (Pgroup[1] & Pgroup[0] & cin);

    assign c12 = Ggroup[2] |
                 (Pgroup[2] & Ggroup[1]) |
                 (Pgroup[2] & Pgroup[1] & Ggroup[0]) |
                 (Pgroup[2] & Pgroup[1] & Pgroup[0] & cin);



	 assign Ggroup_out= Ggroup[3] |
                  (Pgroup[3] & Ggroup[2]) |
                  (Pgroup[3] & Pgroup[2] & Ggroup[1]) |
                  (Pgroup[3] & Pgroup[2] & Pgroup[1] & Ggroup[0]);
	 assign Pgroup_out= Pgroup[3] & Pgroup[2] & Pgroup[1] & Pgroup[0];


	 assign cout= Ggroup_out|(Pgroup_out&cin);

    // 4-bit block 0
    fast_adder_4bit u0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .out(sum[3:0]),
        .cout(block_cout[0]),
        .Pgroup(Pgroup[0]),
        .Ggroup(Ggroup[0])
    );

    // 4-bit block 1
    fast_adder_4bit u1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c4),
        .out(sum[7:4]),
        .cout(block_cout[1]),
        .Pgroup(Pgroup[1]),
        .Ggroup(Ggroup[1])
    );

    // 4-bit block 2
    fast_adder_4bit u2 (
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(c8),
        .out(sum[11:8]),
        .cout(block_cout[2]),
        .Pgroup(Pgroup[2]),
        .Ggroup(Ggroup[2])
    );

    // 4-bit block 3
    fast_adder_4bit u3 (
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(c12),
        .out(sum[15:12]),
        .cout(block_cout[3]),
        .Pgroup(Pgroup[3]),
        .Ggroup(Ggroup[3])
    );
endmodule
