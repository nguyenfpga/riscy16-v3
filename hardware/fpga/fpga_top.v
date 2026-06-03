// =============================================================================
// fpga_top.v -- DE1-SoC top-level wrapper for the RISCY-16 v3 processor
//
// Switch / button assignment:
//   SW[9]    - reset  (active-high)
//   SW[8]    - start  (pulse high to release the processor from IDLE)
//   SW[7]    - view mode:
//                  0 = display selected register R[reg_sel] in decimal
//                  1 = display current instruction number (PC) in decimal
//   SW[4:0]  - select which register (R0..R31) to view (when SW[7]=0)
//
// Display:
//   HEX4..HEX0 - selected value in decimal (5 digits, max 65535)
//   HEX5       - blank
//   LEDR[6:0]  - current pipeline/control state (handy for debugging)
//   LEDR[7]    - view-mode indicator (lit = viewing PC, dark = viewing register)
//
// Clock:
//   The processor runs directly from the 50 MHz CLOCK_50 board clock.
// =============================================================================
module fpga_top(
    input        CLOCK_50,
    input  [9:0] SW,
    input  [3:0] KEY,
    output [9:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

    // -------------------------------------------------------------------------
    // Switch / button mapping
    // -------------------------------------------------------------------------
    wire        reset     = SW[9];
    wire        start     = SW[8];
    wire        view_mode = SW[7];     // 0 = register view, 1 = PC view
    wire [4:0]  reg_sel   = SW[4:0];

    // -------------------------------------------------------------------------
    // The RISCY-16 v3 processor (with debug ports added in riscy16_v3_fpga.v)
    // -------------------------------------------------------------------------
    wire [15:0] view_reg;
    wire [15:0] view_pc;
    wire [6:0]  control_state;

    riscy16_v3_fpga cpu(
        .clk        (CLOCK_50),
        .reset      (reset),
        .start      (start),
        .view_addr  (reg_sel),
        .view_reg   (view_reg),
        .view_pc    (view_pc),
        .view_state (control_state)
    );

    // -------------------------------------------------------------------------
    // Display source mux
    //   view_mode = 0 -> show contents of R[reg_sel]
    //   view_mode = 1 -> show current PC (the address of the instruction
    //                    that the CPU has fetched / is about to fetch)
    // -------------------------------------------------------------------------
    wire [15:0] display_value = view_mode ? view_pc : view_reg;

    // -------------------------------------------------------------------------
    // Binary-to-BCD conversion (16-bit -> 5 BCD digits, max 65535)
    // -------------------------------------------------------------------------
    wire [3:0] d0, d1, d2, d3, d4;
    bin_to_bcd16 bcd (
        .bin (display_value),
        .d0  (d0),
        .d1  (d1),
        .d2  (d2),
        .d3  (d3),
        .d4  (d4)
    );

    // -------------------------------------------------------------------------
    // 7-segment displays (active LOW on DE1-SoC)
    // -------------------------------------------------------------------------
    seg7_decoder seg0 (.bcd(d0), .seg(HEX0));
    seg7_decoder seg1 (.bcd(d1), .seg(HEX1));
    seg7_decoder seg2 (.bcd(d2), .seg(HEX2));
    seg7_decoder seg3 (.bcd(d3), .seg(HEX3));
    seg7_decoder seg4 (.bcd(d4), .seg(HEX4));

    // HEX5 blanked
    assign HEX5 = 7'b1111111;

    // -------------------------------------------------------------------------
    // LEDs
    // -------------------------------------------------------------------------
    assign LEDR[6:0] = control_state;
    assign LEDR[7]   = view_mode;   // lit when viewing PC
    assign LEDR[9:8] = 2'b00;

endmodule
