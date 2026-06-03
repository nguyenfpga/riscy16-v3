// =============================================================================
// decoder_5to32.v -- 5-to-32 one-hot decoder with enable
//   Relocated from the v1 decoder leaf and renamed to match the v3 file tree.
// =============================================================================
// Signal guide:
//   en      : enables one-hot decoding when high.
//   address : 5-bit select value.
//   out     : 32-bit one-hot decode result; zero when en is low.
module decoder_5to32(en, address, out);
    input en;
    input [4:0] address;
    output reg [31:0] out;

    always @(*) begin
        out = 32'b0;
        if (en)
            out[address] = 1'b1;
    end
endmodule
