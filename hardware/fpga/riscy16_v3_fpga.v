// =============================================================================
// riscy16_v3_fpga.v -- FPGA-instrumented RISCY-16 v3 processor
//
// Functionally identical to the simulation processor, but exposes debug taps
// needed by fpga_top.v:
//
//   view_addr  (in)  -- which register to peek at (R0..R31)
//   view_reg   (out) -- current value of that register
//   view_pc    (out) -- current PC / instruction address
//   view_state (out) -- compact pipeline-control activity vector
//
// The register tap is implemented by a passive 32 x 16 shadow array. It snoops
// the processor writeback ports after MEM/WB, including the second writeback
// lane used by dual-result instructions such as MUL/DIV. This lets the board
// read any architectural register without modifying Register_file.v or changing
// the running processor datapath.
// =============================================================================
// Signal guide:
//   clk,reset,start : top-level processor control.
//   view_*          : FPGA debug taps for register, PC, and control display.
//   pc_*            : fetch address, redirect target, and PC enables.
//   if_id_*         : fetch/decode pipeline bundle.
//   dec_*           : control outputs from decode.v.
//   id_ex_*         : decode/execute pipeline bundle and controls.
//   ex_mem_*        : execute/memory pipeline bundle and controls.
//   mem_wb_*        : memory/writeback pipeline bundle and controls.
//   wb_*            : final register-file writeback signals.
//   fwd_*           : forwarded execute operands.
//   div_*           : sequential divider start/busy/done/result signals.
module riscy16_v3_fpga(
    input            clk,
    input            reset,
    input            start,
    input      [4:0] view_addr,
    output     [15:0] view_reg,
    output     [15:0] view_pc,
    output     [6:0]  view_state
);

	wire [15:0] pc_address;
	wire [15:0] pc_target;
	wire pc_en, pc_inc, pc_hold;
	wire [25:0] fetched_instr;
	reg running;
	wire id_ex_valid;
	wire [25:0] id_ex_instr;
	wire [15:0] id_ex_src_a, id_ex_src_b, id_ex_imm;
	wire [4:0] id_ex_rx, id_ex_ry, id_ex_alu_operation;
	wire id_ex_reg_write, id_ex_mem_read, id_ex_mem_write, id_ex_branch, id_ex_jump;
	wire id_ex_A_invert, id_ex_B_negate, id_ex_simd_mode, id_ex_dual_write;
	wire [2:0] id_ex_result_sel;
	wire ex_mem_valid;
	wire [15:0] ex_mem_result, ex_mem_store_data, ex_mem_mem_addr, ex_mem_write_data2;
	wire [4:0] ex_mem_write_addr, ex_mem_write_addr2;
	wire ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write, ex_mem_dual_write;
	wire mem_wb_valid;
	wire [15:0] mem_wb_data, mem_wb_data2;
	wire [4:0] mem_wb_write_addr, mem_wb_write_addr2;
	wire mem_wb_reg_write, mem_wb_dual_write;

	always @(posedge clk or posedge reset) begin
		if (reset)
			running <= 1'b0;
		else if (start)
			running <= 1'b1;
	end

	program_counter pc(.clk(clk),.reset(reset),.in(pc_target),.address(pc_address),.inc_pc(pc_inc),.pc_en(pc_en),.hold(pc_hold));
	instruction_memory ir_mem(.clk(clk),.reset(reset),.address(pc_address),.op_code(fetched_instr));

	wire if_id_valid;
	wire [15:0] if_id_pc;
	wire [25:0] if_id_instr;

	wire id_flush;
	wire load_use_stall;
	wire ex_branch_taken;
	wire div_wait;

	assign pc_en = ex_branch_taken;
	assign pc_target = id_ex_jump ? id_ex_imm : {5'b0, id_ex_instr[10:0]};
	assign pc_inc = running & ~load_use_stall & ~div_wait & ~ex_branch_taken;
	assign pc_hold = ~running | load_use_stall | div_wait;
	assign id_flush = ex_branch_taken;

	pipe_if_id if_id(.clk(clk),.reset(reset),.stall(load_use_stall | div_wait),.flush(id_flush),.valid_in(running),.pc_in(pc_address),
	                 .instr_in(fetched_instr),.valid_out(if_id_valid),.pc_out(if_id_pc),.instr_out(if_id_instr));

	wire [4:0] id_rx, id_ry;
	wire [15:0] id_imm;
	wire [15:0] reg_a, reg_b;
	wire dec_reg_write, dec_mem_read, dec_mem_write, dec_branch, dec_jump;
	wire [4:0] dec_alu_operation;
	wire dec_A_invert, dec_B_negate, dec_simd_mode, dec_dual_write, dec_uses_rx, dec_uses_ry;
	wire [2:0] dec_result_sel;

	assign id_rx = if_id_instr[20:16];
	assign id_ry = if_id_instr[15:11];
	assign id_imm = if_id_instr[15:0];

	decode decoder(.instr(if_id_instr),.reg_write(dec_reg_write),.mem_read(dec_mem_read),.mem_write(dec_mem_write),.branch(dec_branch),
	               .jump(dec_jump),.alu_operation(dec_alu_operation),.A_invert(dec_A_invert),.B_negate(dec_B_negate),
	               .simd_mode(dec_simd_mode),.result_sel(dec_result_sel),.dual_write(dec_dual_write),.uses_rx(dec_uses_rx),.uses_ry(dec_uses_ry));

	wire wb_write_en, wb_write_en2;
	wire [15:0] wb_data, wb_data2;
	wire [4:0] wb_addr, wb_addr2;

	Register_file regs(.clk(clk),.reset(reset),.data_in(wb_data),.write_addr(wb_addr),.write_en(wb_write_en),
	                   .data_in2(wb_data2),.write_addr2(wb_addr2),.write_en2(wb_write_en2),
	                   .Ra_addr(id_rx),.Rb_addr(id_ry),.Ra_out(reg_a),.Rb_out(reg_b));

	wire [15:0] id_src_a, id_src_b;
	forward_unit id_forward_a(.src_addr(id_rx),.reg_value(reg_a),.ex_mem_valid(ex_mem_valid),.ex_mem_reg_write(ex_mem_reg_write),
	                          .ex_mem_mem_read(ex_mem_mem_read),.ex_mem_write_addr(ex_mem_write_addr),.ex_mem_result(ex_mem_result),
	                          .ex_mem_dual_write(ex_mem_dual_write),.ex_mem_write_addr2(ex_mem_write_addr2),.ex_mem_write_data2(ex_mem_write_data2),
	                          .mem_wb_valid(mem_wb_valid),.mem_wb_reg_write(mem_wb_reg_write),.mem_wb_write_addr(mem_wb_write_addr),
	                          .mem_wb_data(mem_wb_data),.mem_wb_dual_write(mem_wb_dual_write),.mem_wb_write_addr2(mem_wb_write_addr2),
	                          .mem_wb_data2(mem_wb_data2),.forwarded_value(id_src_a));
	forward_unit id_forward_b(.src_addr(id_ry),.reg_value(reg_b),.ex_mem_valid(ex_mem_valid),.ex_mem_reg_write(ex_mem_reg_write),
	                          .ex_mem_mem_read(ex_mem_mem_read),.ex_mem_write_addr(ex_mem_write_addr),.ex_mem_result(ex_mem_result),
	                          .ex_mem_dual_write(ex_mem_dual_write),.ex_mem_write_addr2(ex_mem_write_addr2),.ex_mem_write_data2(ex_mem_write_data2),
	                          .mem_wb_valid(mem_wb_valid),.mem_wb_reg_write(mem_wb_reg_write),.mem_wb_write_addr(mem_wb_write_addr),
	                          .mem_wb_data(mem_wb_data),.mem_wb_dual_write(mem_wb_dual_write),.mem_wb_write_addr2(mem_wb_write_addr2),
	                          .mem_wb_data2(mem_wb_data2),.forwarded_value(id_src_b));

	hazard_unit load_interlock(.id_ex_valid(id_ex_valid),.id_ex_mem_read(id_ex_mem_read),.id_ex_write_addr(id_ex_rx),
	                           .if_id_valid(if_id_valid),.id_rx(id_rx),.id_ry(id_ry),.uses_rx(dec_uses_rx),.uses_ry(dec_uses_ry),
	                           .load_use_stall(load_use_stall));

	pipe_id_ex id_ex(.clk(clk),.reset(reset),.flush(id_flush | load_use_stall),.stall(div_wait),.valid_in(if_id_valid),.instr_in(if_id_instr),
	                 .src_a_in(id_src_a),.src_b_in(id_src_b),.imm_in(id_imm),.rx_in(id_rx),.ry_in(id_ry),.reg_write_in(dec_reg_write),
	                 .mem_read_in(dec_mem_read),.mem_write_in(dec_mem_write),.branch_in(dec_branch),.jump_in(dec_jump),
	                 .alu_operation_in(dec_alu_operation),.A_invert_in(dec_A_invert),.B_negate_in(dec_B_negate),
	                 .simd_mode_in(dec_simd_mode),.result_sel_in(dec_result_sel),.dual_write_in(dec_dual_write),
	                 .valid_out(id_ex_valid),.instr_out(id_ex_instr),.src_a_out(id_ex_src_a),.src_b_out(id_ex_src_b),
	                 .imm_out(id_ex_imm),.rx_out(id_ex_rx),.ry_out(id_ex_ry),.reg_write_out(id_ex_reg_write),
	                 .mem_read_out(id_ex_mem_read),.mem_write_out(id_ex_mem_write),.branch_out(id_ex_branch),.jump_out(id_ex_jump),
	                 .alu_operation_out(id_ex_alu_operation),.A_invert_out(id_ex_A_invert),.B_negate_out(id_ex_B_negate),
	                 .simd_mode_out(id_ex_simd_mode),.result_sel_out(id_ex_result_sel),.dual_write_out(id_ex_dual_write));

	wire [15:0] fwd_a_ex, fwd_b_ex;
	forward_unit ex_forward_a(.src_addr(id_ex_rx),.reg_value(id_ex_src_a),.ex_mem_valid(ex_mem_valid),.ex_mem_reg_write(ex_mem_reg_write),
	                          .ex_mem_mem_read(ex_mem_mem_read),.ex_mem_write_addr(ex_mem_write_addr),.ex_mem_result(ex_mem_result),
	                          .ex_mem_dual_write(ex_mem_dual_write),.ex_mem_write_addr2(ex_mem_write_addr2),.ex_mem_write_data2(ex_mem_write_data2),
	                          .mem_wb_valid(mem_wb_valid),.mem_wb_reg_write(mem_wb_reg_write),.mem_wb_write_addr(mem_wb_write_addr),
	                          .mem_wb_data(mem_wb_data),.mem_wb_dual_write(mem_wb_dual_write),.mem_wb_write_addr2(mem_wb_write_addr2),
	                          .mem_wb_data2(mem_wb_data2),.forwarded_value(fwd_a_ex));
	forward_unit ex_forward_b(.src_addr(id_ex_ry),.reg_value(id_ex_src_b),.ex_mem_valid(ex_mem_valid),.ex_mem_reg_write(ex_mem_reg_write),
	                          .ex_mem_mem_read(ex_mem_mem_read),.ex_mem_write_addr(ex_mem_write_addr),.ex_mem_result(ex_mem_result),
	                          .ex_mem_dual_write(ex_mem_dual_write),.ex_mem_write_addr2(ex_mem_write_addr2),.ex_mem_write_data2(ex_mem_write_data2),
	                          .mem_wb_valid(mem_wb_valid),.mem_wb_reg_write(mem_wb_reg_write),.mem_wb_write_addr(mem_wb_write_addr),
	                          .mem_wb_data(mem_wb_data),.mem_wb_dual_write(mem_wb_dual_write),.mem_wb_write_addr2(mem_wb_write_addr2),
	                          .mem_wb_data2(mem_wb_data2),.forwarded_value(fwd_b_ex));

	wire [15:0] alu_result;
	wire alu_zero, alu_overflow, alu_cout, alu_less;
	ALU_16bit alu(.A(fwd_a_ex),.B(fwd_b_ex),.A_invert(id_ex_A_invert),.B_negate(id_ex_B_negate),
	              .ALU_operation(id_ex_alu_operation),.result(alu_result),.zero(alu_zero),.overflow(alu_overflow),
	              .cout(alu_cout),.less_result(alu_less),.simd_mode(id_ex_simd_mode));

	wire [31:0] scalar_mul_result, simd_mul_result;
	mul_pipelined scalar_mul(.A(fwd_a_ex),.B(fwd_b_ex),.product(scalar_mul_result));
	mul_simd_8x8 simd_mul(.A(fwd_a_ex),.B(fwd_b_ex),.product(simd_mul_result));

	wire ex_is_div;
	wire div_start, div_busy, div_done, div_by_zero;
	wire [15:0] div_quotient, div_remainder;
	assign ex_is_div = id_ex_valid & (id_ex_result_sel == 3'b110);
	assign div_start = ex_is_div & ~div_busy & ~div_done;
	assign div_wait = ex_is_div & ~div_done;
	div_ns16 divider(.clk(clk),.reset(reset),.start(div_start),.dividend(fwd_a_ex),.divisor(fwd_b_ex),
	                 .quotient(div_quotient),.remainder(div_remainder),.busy(div_busy),.done(div_done),.divide_by_zero(div_by_zero));

	wire [4:0] rx_plus_1;
	assign rx_plus_1[0] = ~id_ex_rx[0];
	assign rx_plus_1[1] = id_ex_rx[1] ^ id_ex_rx[0];
	assign rx_plus_1[2] = id_ex_rx[2] ^ (id_ex_rx[1] & id_ex_rx[0]);
	assign rx_plus_1[3] = id_ex_rx[3] ^ (id_ex_rx[2] & id_ex_rx[1] & id_ex_rx[0]);
	assign rx_plus_1[4] = id_ex_rx[4] ^ (id_ex_rx[3] & id_ex_rx[2] & id_ex_rx[1] & id_ex_rx[0]);

	wire [4:0] ex_opcode;
	wire ex_breq, ex_brne, ex_brlt, ex_brvs;
	assign ex_opcode = id_ex_instr[25:21];
	assign ex_breq = (ex_opcode == 5'b01010) & alu_zero;
	assign ex_brne = (ex_opcode == 5'b01011) & ~alu_zero;
	assign ex_brlt = (ex_opcode == 5'b01100) & alu_less;
	assign ex_brvs = (ex_opcode == 5'b01101) & alu_overflow;
	assign ex_branch_taken = id_ex_valid & (id_ex_jump | (id_ex_branch & (ex_breq | ex_brne | ex_brlt | ex_brvs)));

	wire [15:0] ex_result;
	wire [15:0] ex_write_data2;
	assign ex_result = (id_ex_result_sel == 3'b001) ? id_ex_imm :
	                   (id_ex_result_sel == 3'b010) ? fwd_b_ex :
	                   (id_ex_result_sel == 3'b011) ? id_ex_imm :
	                   (id_ex_result_sel == 3'b100) ? scalar_mul_result[15:0] :
	                   (id_ex_result_sel == 3'b101) ? simd_mul_result[15:0] :
	                   (id_ex_result_sel == 3'b110) ? div_quotient : alu_result;
	assign ex_write_data2 = (id_ex_result_sel == 3'b101) ? simd_mul_result[31:16] :
	                        (id_ex_result_sel == 3'b110) ? div_remainder : scalar_mul_result[31:16];

	pipe_ex_mem ex_mem(.clk(clk),.reset(reset),.flush(1'b0),.valid_in(id_ex_valid & ~ex_branch_taken & (~ex_is_div | div_done)),.result_in(ex_result),
	                   .store_data_in(fwd_a_ex),.mem_addr_in(id_ex_imm),.write_addr_in(id_ex_rx),.write_addr2_in(rx_plus_1),
	                   .write_data2_in(ex_write_data2),.reg_write_in(id_ex_reg_write),.mem_read_in(id_ex_mem_read),
	                   .mem_write_in(id_ex_mem_write),.dual_write_in(id_ex_dual_write),.valid_out(ex_mem_valid),
	                   .result_out(ex_mem_result),.store_data_out(ex_mem_store_data),.mem_addr_out(ex_mem_mem_addr),
	                   .write_addr_out(ex_mem_write_addr),.write_addr2_out(ex_mem_write_addr2),.write_data2_out(ex_mem_write_data2),
	                   .reg_write_out(ex_mem_reg_write),.mem_read_out(ex_mem_mem_read),.mem_write_out(ex_mem_mem_write),
	                   .dual_write_out(ex_mem_dual_write));

	wire [15:0] data_mem_out;
	data_memory data_memo(.clk(clk),.reset(reset),.write_en(ex_mem_valid & ex_mem_mem_write),.address(ex_mem_mem_addr),
	                      .data_in(ex_mem_store_data),.data_out(data_mem_out),.out_sig(ex_mem_mem_read));

	wire [15:0] mem_stage_data;
	assign mem_stage_data = ex_mem_mem_read ? data_mem_out : ex_mem_result;

	pipe_mem_wb mem_wb(.clk(clk),.reset(reset),.valid_in(ex_mem_valid),.wb_data_in(mem_stage_data),.write_addr_in(ex_mem_write_addr),
	                   .write_data2_in(ex_mem_write_data2),.write_addr2_in(ex_mem_write_addr2),.reg_write_in(ex_mem_reg_write),
	                   .dual_write_in(ex_mem_dual_write),.valid_out(mem_wb_valid),.wb_data_out(mem_wb_data),
	                   .write_addr_out(mem_wb_write_addr),.write_data2_out(mem_wb_data2),.write_addr2_out(mem_wb_write_addr2),
	                   .reg_write_out(mem_wb_reg_write),.dual_write_out(mem_wb_dual_write));

	assign wb_write_en = mem_wb_valid & mem_wb_reg_write;
	assign wb_write_en2 = mem_wb_valid & mem_wb_dual_write;
	assign wb_data = mem_wb_data;
	assign wb_data2 = mem_wb_data2;
	assign wb_addr = mem_wb_write_addr;
	assign wb_addr2 = mem_wb_write_addr2;

	// ========================================================================
	// Debug taps
	// ========================================================================
	assign view_pc = pc_address;

	// The v3 design is a pipeline, not a single-bus FSM.  The LED state is a
	// compact control vector: {running, div_wait, load_stall, MEM/WB, EX/MEM,
	// ID/EX, IF/ID}.
	assign view_state = {running, div_wait, load_use_stall, mem_wb_valid,
	                     ex_mem_valid, id_ex_valid, if_id_valid};

	// Shadow register file: snoops the real register-file writeback ports.
	// R0 is hardwired to zero in Register_file.v, so writes to R0 are ignored.
	reg [15:0] shadow_regs [0:31];
	integer k;

	initial begin
		for (k = 0; k < 32; k = k + 1)
			shadow_regs[k] = 16'b0;
	end

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			for (k = 0; k < 32; k = k + 1)
				shadow_regs[k] <= 16'b0;
		end else begin
			if (wb_write_en & (wb_addr != 5'b0))
				shadow_regs[wb_addr] <= wb_data;
			if (wb_write_en2 & (wb_addr2 != 5'b0))
				shadow_regs[wb_addr2] <= wb_data2;
		end
	end

	assign view_reg = shadow_regs[view_addr];
endmodule
