// =============================================================================
// Register_file.v -- 32 by 16 register file with generated read buses
//   R0 is hardwired to zero. R31 is reserved as the stack pointer for later
//   stages. The generated instance names keep v1 testbench peeks stable.
// =============================================================================
module Register_file(clk,reset,data_in,write_addr,write_en,data_in2,write_addr2,write_en2,Ra_addr,Rb_addr,Ra_out,Rb_out);
	input clk, reset, write_en, write_en2;
	input [15:0] data_in, data_in2;
	input [4:0] write_addr, write_addr2, Ra_addr, Rb_addr;
	output [15:0] Ra_out, Rb_out;

	wire [31:0] write_sel, write_sel2;
	wire [31:0] Ra_sel, Rb_sel;
	wire [15:0] reg_out [31:0];
	wire [31:0] write_gated, write_gated2;
	wire [15:0] write_data [31:0];

	decoder_5to32 write_decoder(.en(write_en),.address(write_addr),.out(write_sel));
	decoder_5to32 write_decoder2(.en(write_en2),.address(write_addr2),.out(write_sel2));
	decoder_5to32 Ra_decoder(.en(1'b1),.address(Ra_addr),.out(Ra_sel));
	decoder_5to32 Rb_decoder(.en(1'b1),.address(Rb_addr),.out(Rb_sel));

	assign write_gated = {write_sel[31:1], 1'b0};
	assign write_gated2 = {write_sel2[31:1], 1'b0};

	genvar i, j;
	generate
		for (i=1; i<32; i=i+1) begin: registers
			assign write_data[i] = write_gated2[i] ? data_in2 : data_in;
			register_16bit register(.clk(clk),.reset(reset),.en(write_gated[i] | write_gated2[i]),.in(write_data[i]),.out(reg_out[i]));
		end
	endgenerate

	assign reg_out[0] = 16'b0;

	generate
		for (j=0; j<32; j=j+1) begin: read_mux
			tri_state_buffer Ra_driver(.in(reg_out[j]),.en(Ra_sel[j]),.out(Ra_out));
			tri_state_buffer Rb_driver(.in(reg_out[j]),.en(Rb_sel[j]),.out(Rb_out));
		end
	endgenerate
endmodule
