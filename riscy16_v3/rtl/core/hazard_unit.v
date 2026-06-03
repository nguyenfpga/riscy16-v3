// =============================================================================
// hazard_unit.v -- load-use interlock for the in-order pipeline
// =============================================================================
module hazard_unit(id_ex_valid,id_ex_mem_read,id_ex_write_addr,if_id_valid,id_rx,id_ry,uses_rx,uses_ry,load_use_stall);
	input id_ex_valid, id_ex_mem_read, if_id_valid, uses_rx, uses_ry;
	input [4:0] id_ex_write_addr, id_rx, id_ry;
	output load_use_stall;

	assign load_use_stall = id_ex_valid & id_ex_mem_read & if_id_valid &
	                         ((uses_rx & (id_ex_write_addr == id_rx)) |
	                          (uses_ry & (id_ex_write_addr == id_ry)));
endmodule
