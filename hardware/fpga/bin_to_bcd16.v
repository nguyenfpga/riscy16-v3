// =============================================================================
// bin_to_bcd16.v -- 16-bit binary to 5-digit BCD (decimal) converter
//
// Uses the "double-dabble" / shift-and-add-3 algorithm, fully unrolled into
// combinational logic. Maximum input value is 65535, requiring 5 BCD digits.
// =============================================================================
module bin_to_bcd16(
    input  [15:0] bin,
    output [3:0]  d0,   // ones
    output [3:0]  d1,   // tens
    output [3:0]  d2,   // hundreds
    output [3:0]  d3,   // thousands
    output [3:0]  d4    // ten-thousands
);
    integer i;
    reg [35:0] shift;   // [35:32]=d4, [31:28]=d3, [27:24]=d2, [23:20]=d1, [19:16]=d0, [15:0]=bin

    always @(*) begin
        shift = {20'b0, bin};

        for (i = 0; i < 16; i = i + 1) begin
            // For each BCD digit: if >= 5, add 3 (so the next shift produces a valid BCD)
            if (shift[19:16] >= 4'd5) shift[19:16] = shift[19:16] + 4'd3;
            if (shift[23:20] >= 4'd5) shift[23:20] = shift[23:20] + 4'd3;
            if (shift[27:24] >= 4'd5) shift[27:24] = shift[27:24] + 4'd3;
            if (shift[31:28] >= 4'd5) shift[31:28] = shift[31:28] + 4'd3;
            if (shift[35:32] >= 4'd5) shift[35:32] = shift[35:32] + 4'd3;

            // Shift left by 1 (a binary bit moves up into the BCD area)
            shift = shift << 1;
        end
    end

    assign d0 = shift[19:16];
    assign d1 = shift[23:20];
    assign d2 = shift[27:24];
    assign d3 = shift[31:28];
    assign d4 = shift[35:32];
endmodule
