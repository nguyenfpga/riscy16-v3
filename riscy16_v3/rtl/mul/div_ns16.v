// =============================================================================
// div_ns16.v -- 16-cycle unsigned non-restoring divider
//   Quotient is produced on quotient. Remainder is produced on remainder.
//   Divide by zero returns quotient=0xffff and remainder=dividend.
// =============================================================================
module div_ns16(clk,reset,start,dividend,divisor,quotient,remainder,busy,done,divide_by_zero);
	input clk, reset, start;
	input [15:0] dividend, divisor;
	output reg [15:0] quotient, remainder;
	output reg busy, done, divide_by_zero;

	reg [16:0] rem_work;
	reg [15:0] quot_work, divisor_work;
	reg [15:0] step;

	wire divisor_is_zero;
	wire rem_is_negative;
	wire [16:0] rem_shift;
	wire [31:0] divisor_ext, rem_shift_ext, divisor_operand;
	wire [31:0] step_sum, corrected_sum;
	wire [16:0] rem_next;
	wire [15:0] quot_next, rem_final;
	wire subtract_mode;
	wire last_step;

	assign divisor_is_zero = ~(|divisor);
	assign rem_is_negative = rem_work[16];
	assign rem_shift = {rem_work[15:0], quot_work[15]};
	assign divisor_ext = {16'b0, divisor_work};
	assign rem_shift_ext = {15'b0, rem_shift};
	assign subtract_mode = ~rem_is_negative;
	assign divisor_operand = subtract_mode ? ~divisor_ext : divisor_ext;
	assign last_step = step[15];

	fast_adder_32bit step_adder(.a(rem_shift_ext),.b(divisor_operand),.cin(subtract_mode),.sum(step_sum),.cout());
	assign rem_next = step_sum[16:0];
	assign quot_next = {quot_work[14:0], ~rem_next[16]};

	fast_adder_32bit correction_adder(.a({15'b0, rem_next}),.b(divisor_ext),.cin(1'b0),.sum(corrected_sum),.cout());
	assign rem_final = rem_next[16] ? corrected_sum[15:0] : rem_next[15:0];

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			quotient <= 16'b0;
			remainder <= 16'b0;
			busy <= 1'b0;
			done <= 1'b0;
			divide_by_zero <= 1'b0;
			rem_work <= 17'b0;
			quot_work <= 16'b0;
			divisor_work <= 16'b0;
			step <= 16'b0;
		end else begin
			done <= 1'b0;
			if (start & ~busy) begin
				divide_by_zero <= divisor_is_zero;
				if (divisor_is_zero) begin
					quotient <= 16'hffff;
					remainder <= dividend;
					busy <= 1'b0;
					done <= 1'b1;
					rem_work <= 17'b0;
					quot_work <= 16'b0;
					divisor_work <= 16'b0;
					step <= 16'b0;
				end else begin
					busy <= 1'b1;
					rem_work <= 17'b0;
					quot_work <= dividend;
					divisor_work <= divisor;
					step <= 16'b0000000000000001;
				end
			end else if (busy) begin
				rem_work <= rem_next;
				quot_work <= quot_next;
				if (last_step) begin
					quotient <= quot_next;
					remainder <= rem_final;
					busy <= 1'b0;
					done <= 1'b1;
					step <= 16'b0;
				end else begin
					step <= {step[14:0], 1'b0};
				end
			end
		end
	end
endmodule
