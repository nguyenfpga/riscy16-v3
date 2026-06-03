// =============================================================================
// bin_to_bcd16.v -- 16-bit binary to 5-digit BCD (decimal) converter
//
// Pure combinational, fully structural double-dabble:
//   16 cascaded "shift-and-add-3" stages, each instantiated as a sub-block.
//
// How double-dabble works:
//   The 36-bit register holds [d4 d3 d2 d1 d0 | bin] = 4+4+4+4+4+16 = 36 bits.
//   At each of 16 stages:
//     (1) For every BCD digit, if it is >= 5, add 3 to it. Reason: after the
//         next left-shift, a digit that was 5..9 would become 10..18, which
//         is no longer a valid BCD digit. Pre-adding 3 turns 5..9 into 8..12,
//         and after the shift the high bit (now 1) carries cleanly into the
//         next BCD digit, leaving 0..9 behind in the current digit.
//     (2) Shift the whole register left by 1. A binary bit migrates out of
//         the bin[] area and into the BCD digits area.
//
//   After 16 stages every binary bit has migrated out, and the BCD digits
//   sit in shift[35:16].
// =============================================================================


// -----------------------------------------------------------------------------
// One double-dabble stage: per-digit fix-up, then shift left by 1.
// All combinational; every signal is a wire driven by an assign.
// -----------------------------------------------------------------------------
module dd_stage(
    input  [35:0] in,
    output [35:0] out
);
    wire [3:0] d0_fix, d1_fix, d2_fix, d3_fix, d4_fix;

    // For each 4-bit BCD digit: if value >= 5, add 3, else pass through.
    assign d0_fix = (in[19:16] >= 4'd5) ? in[19:16] + 4'd3 : in[19:16];
    assign d1_fix = (in[23:20] >= 4'd5) ? in[23:20] + 4'd3 : in[23:20];
    assign d2_fix = (in[27:24] >= 4'd5) ? in[27:24] + 4'd3 : in[27:24];
    assign d3_fix = (in[31:28] >= 4'd5) ? in[31:28] + 4'd3 : in[31:28];
    assign d4_fix = (in[35:32] >= 4'd5) ? in[35:32] + 4'd3 : in[35:32];

    // Reassemble the register with the fixed-up digits, then shift left by 1.
    // The binary part (in[15:0]) is unchanged before the shift; after the
    // shift, its top bit migrates into d0's LSB.
    assign out = {d4_fix, d3_fix, d2_fix, d1_fix, d0_fix, in[15:0]} << 1;
endmodule


// -----------------------------------------------------------------------------
// Top level: 16 cascaded dd_stage instances.
// -----------------------------------------------------------------------------
module bin_to_bcd16(
    input  [15:0] bin,
    output [3:0]  d0,   // ones
    output [3:0]  d1,   // tens
    output [3:0]  d2,   // hundreds
    output [3:0]  d3,   // thousands
    output [3:0]  d4    // ten-thousands
);
    // Per-stage register snapshots: s0 = initial, s16 = final.
    wire [35:0] s0,  s1,  s2,  s3,  s4,  s5,  s6,  s7,  s8;
    wire [35:0] s9,  s10, s11, s12, s13, s14, s15, s16;

    // Initial value: binary input in low 16 bits, BCD area cleared.
    assign s0 = {20'b0, bin};

    // Cascade of 16 double-dabble stages.
    dd_stage stage_01 (.in(s0 ), .out(s1 ));
    dd_stage stage_02 (.in(s1 ), .out(s2 ));
    dd_stage stage_03 (.in(s2 ), .out(s3 ));
    dd_stage stage_04 (.in(s3 ), .out(s4 ));
    dd_stage stage_05 (.in(s4 ), .out(s5 ));
    dd_stage stage_06 (.in(s5 ), .out(s6 ));
    dd_stage stage_07 (.in(s6 ), .out(s7 ));
    dd_stage stage_08 (.in(s7 ), .out(s8 ));
    dd_stage stage_09 (.in(s8 ), .out(s9 ));
    dd_stage stage_10 (.in(s9 ), .out(s10));
    dd_stage stage_11 (.in(s10), .out(s11));
    dd_stage stage_12 (.in(s11), .out(s12));
    dd_stage stage_13 (.in(s12), .out(s13));
    dd_stage stage_14 (.in(s13), .out(s14));
    dd_stage stage_15 (.in(s14), .out(s15));
    dd_stage stage_16 (.in(s15), .out(s16));

    // Extract the 5 BCD digits from the final stage's register.
    assign d0 = s16[19:16];
    assign d1 = s16[23:20];
    assign d2 = s16[27:24];
    assign d3 = s16[31:28];
    assign d4 = s16[35:32];

endmodule
