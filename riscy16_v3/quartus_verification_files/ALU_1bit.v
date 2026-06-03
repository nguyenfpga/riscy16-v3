// =============================================================================
// ALU_1bit.v -- non-MSB ALU bit slice
// =============================================================================
// Signal guide:
//   A,B           : one bit from the ALU operands.
//   A_invert      : selects A or ~A before logic/add.
//   B_invert      : selects B or ~B before logic/add.
//   cin,cout      : carry input/output for ripple arithmetic.
//   less          : set-less-than input used by the low bit.
//   ALU_operation : selects AND, OR, ADD, or SLT bit result.
//   ALU_out       : selected result bit.
module ALU_1bit(ALU_operation, A, B, ALU_out, A_invert, B_invert, cout, cin, less);
	input[4:0]ALU_operation;
	input A,B, A_invert, B_invert;
	input cin;
	input less; //use for slt-set less than
	output reg ALU_out;
	output reg cout;

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

	//add block
	always@(*) begin
		add_wire=A1^B1^cin;
		cout=A1&B1|A1&cin|B1&cin;
	end


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
