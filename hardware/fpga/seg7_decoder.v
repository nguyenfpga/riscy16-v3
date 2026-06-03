// =============================================================================
// seg7_decoder.v -- BCD digit to active-LOW DE1-SoC 7-segment pattern
// =============================================================================
module seg7_decoder(
    input  [3:0] bcd,
    output reg [6:0] seg
);
    always @(*) begin
        case (bcd)
            4'd0:    seg = 7'b1000000;  // 0
            4'd1:    seg = 7'b1111001;  // 1
            4'd2:    seg = 7'b0100100;  // 2
            4'd3:    seg = 7'b0110000;  // 3
            4'd4:    seg = 7'b0011001;  // 4
            4'd5:    seg = 7'b0010010;  // 5
            4'd6:    seg = 7'b0000010;  // 6
            4'd7:    seg = 7'b1111000;  // 7
            4'd8:    seg = 7'b0000000;  // 8
            4'd9:    seg = 7'b0010000;  // 9
            default: seg = 7'b1111111;  // blank for any non-decimal value
        endcase
    end
endmodule
