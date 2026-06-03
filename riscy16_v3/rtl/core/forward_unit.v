// =============================================================================
// forward_unit.v -- operand bypass mux for decode and execute consumers
// =============================================================================
module forward_unit(src_addr,reg_value,ex_mem_valid,ex_mem_reg_write,ex_mem_mem_read,ex_mem_write_addr,ex_mem_result,ex_mem_dual_write,ex_mem_write_addr2,ex_mem_write_data2,mem_wb_valid,mem_wb_reg_write,mem_wb_write_addr,mem_wb_data,mem_wb_dual_write,mem_wb_write_addr2,mem_wb_data2,forwarded_value);
	input [4:0] src_addr;
	input [15:0] reg_value;
	input ex_mem_valid, ex_mem_reg_write, ex_mem_mem_read, ex_mem_dual_write;
	input [4:0] ex_mem_write_addr, ex_mem_write_addr2;
	input [15:0] ex_mem_result, ex_mem_write_data2;
	input mem_wb_valid, mem_wb_reg_write, mem_wb_dual_write;
	input [4:0] mem_wb_write_addr, mem_wb_write_addr2;
	input [15:0] mem_wb_data, mem_wb_data2;
	output [15:0] forwarded_value;

	assign forwarded_value = (ex_mem_valid & ex_mem_reg_write & ~ex_mem_mem_read & (ex_mem_write_addr == src_addr)) ? ex_mem_result :
	                         (ex_mem_valid & ex_mem_dual_write & (ex_mem_write_addr2 == src_addr)) ? ex_mem_write_data2 :
	                         (mem_wb_valid & mem_wb_reg_write & (mem_wb_write_addr == src_addr)) ? mem_wb_data :
	                         (mem_wb_valid & mem_wb_dual_write & (mem_wb_write_addr2 == src_addr)) ? mem_wb_data2 : reg_value;
endmodule
