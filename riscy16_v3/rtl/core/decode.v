// =============================================================================
// decode.v -- legacy opcode decode for the first pipelined shell
// =============================================================================
// Signal guide:
//   instr         : 26-bit instruction word from IF/ID.
//   opcode        : instr[25:21], selects the instruction decode row.
//   reg_write     : enables register writeback for instructions that produce Rx.
//   mem_read      : selects data memory readback in the memory/writeback stages.
//   mem_write     : enables a data memory store.
//   branch        : marks a conditional branch for execute-stage resolution.
//   jump          : marks an unconditional PC redirect.
//   alu_operation : selects the ALU function used in execute.
//   A_invert      : inverts ALU operand A for logic operations such as NOR.
//   B_negate      : negates ALU operand B for subtract/compare operations.
//   simd_mode     : enables packed byte ALU operation.
//   result_sel    : selects the execute result source before memory/writeback.
//   dual_write    : writes Rx and Rx+1 for full-width multiply results.
//   uses_rx       : tells hazard logic that the Rx source register is read.
//   uses_ry       : tells hazard logic that the Ry source register is read.
module decode(instr,reg_write,mem_read,mem_write,branch,jump,alu_operation,A_invert,B_negate,simd_mode,result_sel,dual_write,uses_rx,uses_ry);
	input [25:0] instr;
	output reg reg_write, mem_read, mem_write, branch, jump;
	output reg [4:0] alu_operation;
	output reg A_invert, B_negate, simd_mode, dual_write, uses_rx, uses_ry;
	output reg [2:0] result_sel;

	wire [4:0] opcode;
	assign opcode = instr[25:21];

	always @(*) begin
		reg_write = 1'b0;
		mem_read = 1'b0;
		mem_write = 1'b0;
		branch = 1'b0;
		jump = 1'b0;
		alu_operation = 5'b00010;
		A_invert = 1'b0;
		B_negate = 1'b0;
		simd_mode = 1'b0;
		result_sel = 3'b000;
		dual_write = 1'b0;
		uses_rx = 1'b0;
		uses_ry = 1'b0;

		case (opcode)
			5'b00000: begin reg_write = 1'b1; result_sel = 3'b001; end // LDI - Rx = immediate
			5'b00001: begin reg_write = 1'b1; result_sel = 3'b010; uses_ry = 1'b1; end // MOV - Rx = Ry
			5'b00010: begin reg_write = 1'b1; alu_operation = 5'b00010; uses_rx = 1'b1; uses_ry = 1'b1; end // ADD - Rx = Rx + Ry
			5'b00011: begin reg_write = 1'b1; alu_operation = 5'b00010; B_negate = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // SUB - Rx = Rx - Ry
			5'b00100: begin reg_write = 1'b1; alu_operation = 5'b00100; uses_rx = 1'b1; uses_ry = 1'b1; end // OR - Rx = Rx | Ry
			5'b00101: begin reg_write = 1'b1; alu_operation = 5'b00101; uses_rx = 1'b1; uses_ry = 1'b1; end // AND - Rx = Rx & Ry
			5'b00110: begin reg_write = 1'b1; alu_operation = 5'b00101; A_invert = 1'b1; B_negate = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // NOR - Rx = ~(Rx | Ry)
			5'b00111: begin jump = 1'b1; end // JUMP - PC = target
			5'b01000: begin reg_write = 1'b1; mem_read = 1'b1; result_sel = 3'b011; end // LDS - Rx = memory[address]
			5'b01001: begin mem_write = 1'b1; uses_rx = 1'b1; end // STS - memory[address] = Rx
			5'b01010: begin branch = 1'b1; alu_operation = 5'b00010; B_negate = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // BREQ - branch if Rx == Ry
			5'b01011: begin branch = 1'b1; alu_operation = 5'b00010; B_negate = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // BRNE - branch if Rx != Ry
			5'b01100: begin branch = 1'b1; alu_operation = 5'b00010; B_negate = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // BRLT - branch if Rx < Ry
			5'b01101: begin branch = 1'b1; alu_operation = 5'b00010; uses_rx = 1'b1; uses_ry = 1'b1; end // BRVS - branch on overflow
			5'b01110: begin reg_write = 1'b1; alu_operation = 5'b01110; uses_rx = 1'b1; uses_ry = 1'b1; end // SHL - Rx = Rx << Ry
			5'b01111: begin reg_write = 1'b1; alu_operation = 5'b01111; uses_rx = 1'b1; uses_ry = 1'b1; end // SHR - Rx = Rx >> Ry
			5'b10000: begin reg_write = 1'b1; alu_operation = 5'b10000; uses_rx = 1'b1; uses_ry = 1'b1; end // SAR - Rx = signed Rx >>> Ry
			5'b10001: begin reg_write = 1'b1; alu_operation = 5'b10001; uses_rx = 1'b1; uses_ry = 1'b1; end // ROL - Rx = rotate-left Rx by Ry
			5'b10010: begin reg_write = 1'b1; result_sel = 3'b100; dual_write = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // MUL - {Rx+1,Rx} = Rx * Ry
			5'b10011: begin reg_write = 1'b1; alu_operation = 5'b00010; simd_mode = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // ADD.B - byte lanes Rx = Rx + Ry
			5'b10100: begin reg_write = 1'b1; alu_operation = 5'b00010; B_negate = 1'b1; simd_mode = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // SUB.B - byte lanes Rx = Rx - Ry
			5'b10101: begin reg_write = 1'b1; result_sel = 3'b101; dual_write = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // MUL.B - byte products to Rx,Rx+1
			5'b10110: begin reg_write = 1'b1; result_sel = 3'b110; dual_write = 1'b1; uses_rx = 1'b1; uses_ry = 1'b1; end // DIV - Rx=quotient, Rx+1=remainder
			default: begin end
		endcase
	end
endmodule
