// =============================================================================
// program_counter.v -- 16-bit program counter
// =============================================================================
module program_counter(clk,reset,in,address,inc_pc,pc_en,hold);
	input clk, reset, inc_pc, pc_en, hold;
	input [15:0] in;
	output reg [15:0] address;

	wire [15:0] address_inc;

	assign address_inc[0]  = ~address[0];
	assign address_inc[1]  =  address[1]  ^  address[0];
	assign address_inc[2]  =  address[2]  ^ (address[1]  & address[0]);
	assign address_inc[3]  =  address[3]  ^ (address[2]  & address[1]  & address[0]);
	assign address_inc[4]  =  address[4]  ^ (address[3]  & address[2]  & address[1]  & address[0]);
	assign address_inc[5]  =  address[5]  ^ (address[4]  & address[3]  & address[2]  & address[1]  & address[0]);
	assign address_inc[6]  =  address[6]  ^ (address[5]  & address[4]  & address[3]  & address[2]  & address[1]  & address[0]);
	assign address_inc[7]  =  address[7]  ^ (address[6]  & address[5]  & address[4]  & address[3]  & address[2]  & address[1]  & address[0]);
	assign address_inc[8]  =  address[8]  ^ (address[7]  & address[6]  & address[5]  & address[4]  & address[3]  & address[2]  & address[1] & address[0]);
	assign address_inc[9]  =  address[9]  ^ (address[8]  & address[7]  & address[6]  & address[5]  & address[4]  & address[3]  & address[2] & address[1] & address[0]);
	assign address_inc[10] =  address[10] ^ (address[9]  & address[8]  & address[7]  & address[6]  & address[5]  & address[4]  & address[3] & address[2] & address[1] & address[0]);
	assign address_inc[11] =  address[11] ^ (address[10] & address[9]  & address[8]  & address[7]  & address[6]  & address[5]  & address[4] & address[3] & address[2] & address[1] & address[0]);
	assign address_inc[12] =  address[12] ^ (address[11] & address[10] & address[9]  & address[8]  & address[7]  & address[6]  & address[5] & address[4] & address[3] & address[2] & address[1] & address[0]);
	assign address_inc[13] =  address[13] ^ (address[12] & address[11] & address[10] & address[9]  & address[8]  & address[7]  & address[6] & address[5] & address[4] & address[3] & address[2] & address[1] & address[0]);
	assign address_inc[14] =  address[14] ^ (address[13] & address[12] & address[11] & address[10] & address[9]  & address[8]  & address[7] & address[6] & address[5] & address[4] & address[3] & address[2] & address[1] & address[0]);
	assign address_inc[15] =  address[15] ^ (address[14] & address[13] & address[12] & address[11] & address[10] & address[9]  & address[8] & address[7] & address[6] & address[5] & address[4] & address[3] & address[2] & address[1] & address[0]);

	always @(posedge clk or posedge reset) begin
		if (reset)
			address <= 16'b0;
		else if (hold)
			address <= address;
		else if (pc_en)
			address <= in;
		else if (inc_pc)
			address <= address_inc;
	end
endmodule
