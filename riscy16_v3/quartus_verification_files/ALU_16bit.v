// =============================================================================
// ALU_16bit.v -- 16-bit ALU with scalar and packed-byte SIMD modes
// =============================================================================
// Signal guide:
//   A,B           : 16-bit operands from the execute stage.
//   A_invert      : inverts operand A before bit-slice logic.
//   B_negate      : inverts operand B and seeds carry-in for subtract/NOR.
//   ALU_operation : selects add, logic, compare, shift, or rotate output.
//   simd_mode     : splits add/sub carry chain into two byte lanes.
//   result        : selected 16-bit ALU result.
//   zero          : high when result is zero.
//   overflow      : signed overflow from the MSB slice.
//   cout          : final carry out from bit 15.
//   less_result   : signed less-than helper from overflow and sign.
module ALU_16bit(A,B,A_invert,B_negate,ALU_operation,result,zero,overflow,cout,less_result,simd_mode);
	input [15:0] A,B ;
	input [4:0] ALU_operation;
	input A_invert, B_negate; //B negate use for B_invert and cin of first ALU_unit
	input simd_mode;          // 1 = treat A,B as packed bytes; break carry chain between bit 7 and bit 8
	output reg [15:0] result;
	output zero, overflow;
	output cout;
	output less_result;

	wire negative_flag;
	wire [15:0] carry_wire;
	wire [15:0] output_temp;

	// In SIMD mode, the high lane (bits 15:8) starts a fresh add/sub chain,
	// so its bit 8 cin = B_negate (matches bit 0's cin pattern). In scalar
	// mode, bit 8 takes the natural carry from bit 7.
	wire bit8_cin = simd_mode ? B_negate : carry_wire[8];

	assign less_result= overflow^negative_flag;

	ALU_1bit ALU_block0(.A(A[0]),.B(B[0]),.ALU_operation(ALU_operation),.A_invert(A_invert),.B_invert(B_negate),
										.cin(B_negate),.less(less_result),.ALU_out(output_temp[0]),.cout(carry_wire[1]));

	// Bits 1-7 -- low lane upper bits, normal ripple
	genvar i;
	generate
		for (i=1; i<8; i=i+1) begin: low_lane_ALU
			ALU_1bit ALU_block(.A(A[i]),.B(B[i]),.ALU_operation(ALU_operation),.A_invert(A_invert),.B_invert(B_negate),
										.cin(carry_wire[i]),.less(1'b0),.ALU_out(output_temp[i]),.cout(carry_wire[i+1]));
		end
	endgenerate

	// Bit 8 -- lane boundary; cin is muxed by simd_mode
	ALU_1bit ALU_block8(.A(A[8]),.B(B[8]),.ALU_operation(ALU_operation),.A_invert(A_invert),.B_invert(B_negate),
										.cin(bit8_cin),.less(1'b0),.ALU_out(output_temp[8]),.cout(carry_wire[9]));

	// Bits 9-14 -- high lane lower/middle bits, normal ripple
	generate
		for (i=9; i<15; i=i+1) begin: high_lane_ALU
			ALU_1bit ALU_block(.A(A[i]),.B(B[i]),.ALU_operation(ALU_operation),.A_invert(A_invert),.B_invert(B_negate),
										.cin(carry_wire[i]),.less(1'b0),.ALU_out(output_temp[i]),.cout(carry_wire[i+1]));
		end
	endgenerate

	ALU_1bit_msb ALU_block15(.ALU_operation(ALU_operation), .A(A[15]), .B(B[15]), .ALU_out(output_temp[15]), .A_invert(A_invert),
										.B_invert(B_negate), .cin(carry_wire[15]), .less(1'b0), .overflow(overflow),.set(negative_flag),.cout(cout));



	wire [3:0] sh = B[3:0];
	wire       sgn = A[15];                 // sign bit (used by SAR)

	// ---------- SHL : Logical Shift Left ----------
	wire [15:0] shl_s0, shl_s1, shl_s2, shl_s3;
	assign shl_s0 = sh[0] ? {A     [14:0], 1'b0}     : A;
	assign shl_s1 = sh[1] ? {shl_s0[13:0], 2'b0}     : shl_s0;
	assign shl_s2 = sh[2] ? {shl_s1[11:0], 4'b0}     : shl_s1;
	assign shl_s3 = sh[3] ? {shl_s2[ 7:0], 8'b0}     : shl_s2;

	// ---------- SHR : Logical Shift Right ----------
	wire [15:0] shr_s0, shr_s1, shr_s2, shr_s3;
	assign shr_s0 = sh[0] ? {1'b0, A     [15:1]}     : A;
	assign shr_s1 = sh[1] ? {2'b0, shr_s0[15:2]}     : shr_s0;
	assign shr_s2 = sh[2] ? {4'b0, shr_s1[15:4]}     : shr_s1;
	assign shr_s3 = sh[3] ? {8'b0, shr_s2[15:8]}     : shr_s2;

	// ---------- SAR : Arithmetic Shift Right (fills with sign bit) ----------
	wire [15:0] sar_s0, sar_s1, sar_s2, sar_s3;
	assign sar_s0 = sh[0] ? {sgn,        A     [15:1]} : A;
	assign sar_s1 = sh[1] ? {{2{sgn}},   sar_s0[15:2]} : sar_s0;
	assign sar_s2 = sh[2] ? {{4{sgn}},   sar_s1[15:4]} : sar_s1;
	assign sar_s3 = sh[3] ? {{8{sgn}},   sar_s2[15:8]} : sar_s2;

	// ---------- ROL : Rotate Left (bits wrap around) ----------
	wire [15:0] rol_s0, rol_s1, rol_s2, rol_s3;
	assign rol_s0 = sh[0] ? {A     [14:0], A     [15]   } : A;
	assign rol_s1 = sh[1] ? {rol_s0[13:0], rol_s0[15:14]} : rol_s0;
	assign rol_s2 = sh[2] ? {rol_s1[11:0], rol_s1[15:12]} : rol_s1;
	assign rol_s3 = sh[3] ? {rol_s2[ 7:0], rol_s2[15: 8]} : rol_s2;

	// Final result mux
	always@(*) begin
		case(ALU_operation)
			5'b01110: result = shl_s3;   // SHL
			5'b01111: result = shr_s3;   // SHR
			5'b10000: result = sar_s3;   // SAR
			5'b10001: result = rol_s3;   // ROL
			default:  result = output_temp;
		endcase
	end

	assign zero = ~(|result);

endmodule
