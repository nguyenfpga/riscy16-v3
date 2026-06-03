// =============================================================================
// hazard_unit.v -- load-use interlock for the in-order pipeline
// =============================================================================
// Signal guide:
//   id_ex_valid      : current EX-stage instruction is valid.
//   id_ex_mem_read   : EX-stage instruction is a load.
//   id_ex_write_addr : destination register for the load.
//   if_id_valid      : current decode-stage instruction is valid.
//   id_rx,id_ry      : source register fields in decode.
//   uses_rx,uses_ry  : decode says the instruction reads Rx/Ry.
//   load_use_stall   : holds fetch/decode and inserts a bubble.
module hazard_unit(id_ex_valid,id_ex_mem_read,id_ex_write_addr,if_id_valid,id_rx,id_ry,uses_rx,uses_ry,load_use_stall);
	input id_ex_valid, id_ex_mem_read, if_id_valid, uses_rx, uses_ry;
	input [4:0] id_ex_write_addr, id_rx, id_ry;
	output load_use_stall;

	assign load_use_stall = id_ex_valid & id_ex_mem_read & if_id_valid &
	                         ((uses_rx & (id_ex_write_addr == id_rx)) |
	                          (uses_ry & (id_ex_write_addr == id_ry)));
endmodule
