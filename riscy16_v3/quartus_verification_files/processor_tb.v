`timescale 1ns / 1ps

// =============================================================================
// RISCY-16 v3 processor testbench
// Tests: LDI, MOV, ADD, SUB, OR, AND, NOR, JUMP, LDS, STS,
//        BREQ, BRNE, SHL, SHR, SAR, ROL, DIV
// =============================================================================
// Signal guide:
//   clk,reset,start : stimulus controls for the processor instance.
//   uut             : processor under test.
//   R(n),MEM(n)     : hierarchical probes used by self-checks.
//   PC,IFIR         : fetch trace probes.
//   pass/fail_count : final regression result counters.
module processor_tb();
    reg clk;
    reg reset;
    reg start;
	 reg [15:0] test_address;

    // Instantiate the processor
    processor uut(
        .clk(clk),
        .reset(reset),
        .start(start),
		  .test_pc_address(test_pc_address)
    );

    // Clock: 10ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Hierarchical references for peeking inside the design
    `define R(n)    uut.regs.registers[n].register.out
    `define MEM(n)  uut.data_memo.mem[n]
    `define PC      uut.pc_address
    `define IFIR    uut.if_id_instr

    integer pass_count;
    integer fail_count;

    // ---------------------------------------------------------------
    // Helper task: check a register against an expected value
    // ---------------------------------------------------------------
    task check_reg;
        input [4:0]  reg_num;
        input [15:0] expected;
        input [15:0] actual;
        begin
            if (actual === expected) begin
                $display("  PASS  R%0d = 0x%04h", reg_num, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  R%0d = 0x%04h  (expected 0x%04h)",
                         reg_num, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_mem;
        input [15:0] addr;
        input [15:0] expected;
        input [15:0] actual;
        begin
            if (actual === expected) begin
                $display("  PASS  MEM[%0d] = 0x%04h", addr, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  MEM[%0d] = 0x%04h  (expected 0x%04h)",
                         addr, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ---------------------------------------------------------------
    // Main stimulus
    // ---------------------------------------------------------------
    initial begin
        // Init counters
        pass_count = 0;
        fail_count = 0;

        // Waveform dump (for ModelSim)
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);

        // Initial values
        reset = 1;
        start = 0;

        // Hold reset for a few cycles
        #20 reset = 0;

        // ----- Verify program loaded correctly -----
        #1;
        $display("\n========================================");
        $display("    INSTRUCTION MEMORY CHECK");
        $display("========================================");
        $display("mem[0] = %07h  (expected 0010005)", uut.ir_mem.mem[0]);
        $display("mem[1] = %07h  (expected 002000A)", uut.ir_mem.mem[1]);
        $display("mem[2] = %07h  (expected 0411000)", uut.ir_mem.mem[2]);
        if (uut.ir_mem.mem[0] === 26'h0010005) begin
            $display("Program loaded successfully.");
        end else begin
            $display("*** PROGRAM NOT LOADED - check file path ***");
            $display("Make sure program.txt is in ModelSim's working directory.");
            $display("Type 'pwd' in ModelSim to see where it's looking.");
            $finish;
        end

        // ----- Pulse start high for one cycle -----
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        $display("\n========================================");
        $display("    EXECUTION TRACE (PC at each fetch)");
        $display("========================================");

        // 50 instructions plus two 16-cycle DIV stalls.
        // Using 4000ns (400 cycles) for safety.
        #4000;

        // ----- Final state report -----
        $display("\n========================================");
        $display("    FINAL PROCESSOR STATE");
        $display("========================================");
        $display("PC = %0d\n", `PC);


        $display("--- Existing instruction tests ---");
        check_reg(1,  16'h000F, `R(1));   // R1 = 5 + 10
        check_reg(2,  16'h000A, `R(2));   // LDI 10
        check_reg(3,  16'h0005, `R(3));   // SUB: 15 - 10
        check_reg(4,  16'h000A, `R(4));   // AND: 15 & 10
        check_reg(5,  16'hFFF0, `R(5));   // NOR: ~(0|15)
        check_reg(6,  16'hABCD, `R(6));   // LDS from MEM[100]
        check_reg(7,  16'hBEEF, `R(7));   // LDI after JUMP (0xDEAD skipped)
        check_reg(8,  16'h0000, `R(8));   // LDI 0
        check_reg(9,  16'hC001, `R(9));   // LDI after BREQ (0xBAD1 skipped)
        check_reg(10, 16'h0005, `R(10));  // LDI 5
        check_reg(11, 16'hCAFE, `R(11)); // LDI after BRNE (0xBAD2 skipped)
        check_mem(100, 16'hABCD, `MEM(100));

        $display("\n--- Barrel shifter tests ---");
        // SHL: 0x00FF << 4 = 0x0FF0, then SHR: 0x0FF0 >> 2 = 0x03FC
        check_reg(12, 16'h03FC, `R(12));
        // Shift amounts (unchanged)
        check_reg(13, 16'h0004, `R(13));
        check_reg(14, 16'h0002, `R(14));
        // SAR: 0xFF80 (= -128) >>> 4 = 0xFFF8 (= -8)
        check_reg(15, 16'hFFF8, `R(15));
        // ROL: 0x8001 rotated left by 4 = (0x8001<<4)|(0x8001>>12) = 0x0010|0x0008 = 0x0018
        check_reg(16, 16'h0018, `R(16));

        $display("\n--- MUL test (32-bit result, binary reduction tree) ---");
        // MUL R17, R19: 0xFFFF * 0xFFFF = 0xFFFE0001 (32 bits)
        // Low half  -> Rx   (R17) = 0x0001
        // High half -> Rx+1 (R18) = 0xFFFE
        check_reg(17, 16'h0001, `R(17));   // low  half of product
        check_reg(18, 16'hFFFE, `R(18));   // high half of product (written to Rx+1)
        check_reg(19, 16'hFFFF, `R(19));   // R19 unchanged

        $display("\n--- SIMD packed-byte tests (2 x 8-bit lanes) ---");
        // ADD.B 0x80FF + 0x0102:
        //   high lane: 0x80 + 0x01 = 0x81 (no carry into 0x82 from low lane)
        //   low  lane: 0xFF + 0x02 = 0x101 -> 0x01 (carry truncated)
        // Scalar ADD would give 0x8201; SIMD gives 0x8101.
        check_reg(20, 16'h8101, `R(20));
        check_reg(21, 16'h0102, `R(21));   // R21 unchanged

        // SUB.B 0x1010 - 0x0820:
        //   high lane: 0x10 - 0x08 = 0x08 (no borrow from low lane)
        //   low  lane: 0x10 - 0x20 = 0xF0 (borrow truncated)
        // Scalar SUB would give 0x07F0; SIMD gives 0x08F0.
        check_reg(22, 16'h08F0, `R(22));
        check_reg(23, 16'h0820, `R(23));   // R23 unchanged

        // MUL.B 0x0F0A * 0x0205:
        //   low  lane: 10 * 5  = 0x32 -> R24 (Rx)
        //   high lane: 15 * 2  = 0x1E -> R25 (Rx+1)
        check_reg(24, 16'h0032, `R(24));   // low lane product
        check_reg(25, 16'h001E, `R(25));   // high lane product (written to Rx+1)
        check_reg(26, 16'h0205, `R(26));   // R26 unchanged

        $display("\n--- DIV tests (16-cycle unsigned divider) ---");
        // DIV R27, R29: 100 / 7 = quotient 14, remainder 2.
        check_reg(27, 16'h000E, `R(27));
        check_reg(28, 16'h0002, `R(28));
        check_reg(29, 16'h0007, `R(29));   // divisor unchanged
        // DIV R30, R0: divide-by-zero returns quotient 0xFFFF, remainder dividend.
        check_reg(30, 16'hFFFF, `R(30));
        check_reg(31, 16'h007B, `R(31));

        // ----- Summary -----
        $display("\n========================================");
        $display("    SUMMARY:  %0d passed, %0d failed", pass_count, fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("*** ALL TESTS PASSED ***\n");
        else
            $display("*** %0d TEST(S) FAILED ***\n", fail_count);

        $finish;
    end

    // ---------------------------------------------------------------
    // Trace fetch/decode progress in the pipelined core
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (uut.if_id_valid && !reset) begin
            $display("  t=%4t  PC=%2d  IR=%07h",
                     $time, uut.if_id_pc, `IFIR);
        end
    end

endmodule
