// =============================================================================
// ALU_1bit_msb.v -- MSB ALU bit slice with overflow/set outputs
// =============================================================================
// Signal guide:
//   A,B           : most-significant operand bits.
//   A_invert      : selects A or ~A before logic/add.
//   B_invert      : selects B or ~B before logic/add.
//   cin,cout      : carry input/output for bit 15.
//   less          : SLT input, kept for slice interface consistency.
//   ALU_operation : selects AND, OR, ADD, or SLT bit result.
//   ALU_out       : selected MSB result.
//   overflow      : signed overflow flag for add/sub.
//   set           : raw MSB sum bit used for less-than.
module ALU_1bit_msb(ALU_operation, A, B, ALU_out, A_invert, B_invert, cin, less, overflow,set,cout);
	input[4:0]ALU_operation;
	input A,B, A_invert, B_invert;
	input cin;
	input less; //use for slt-set less than
	output reg ALU_out;
	output overflow;
	output set;
	output cout;


	reg A1,B1;
	reg add_wire;

	//slt will produce 1 in rd if rs1<rs2 and 0 otherwise

	//A_invert mux
	always@(*) begin
		if(A_invert)
			A1=~A;
		else
			A1=A;
	end
	//B_invert mux
	always@(*) begin
		if(B_invert)
			B1=~B;
		else
			B1=B;
	end

	assign cout=A1&B1|A1&cin|B1&cin;
	//add block
	always@(*) begin
		add_wire=A1^B1^cin;

	end

	//overflow detection
	assign overflow=cin^cout;
	assign set=add_wire;

	//result mux

	always@(*) begin
		case(ALU_operation)
			5'b00101: begin ALU_out=A1&B1; end //and
			5'b00100: begin ALU_out=A1|B1; end //or
			5'b00010: begin ALU_out=add_wire; end // add
			5'b11111: begin ALU_out=less; end //slt
			default: begin ALU_out=1'b0; end
		endcase
	end
endmodule
