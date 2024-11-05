`ifndef AXIL_SEQ_LIST
`define AXIL_SEQ_LIST

package axil_seq_list;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	import dut_params_pkg::*;
	import axil_env_pkg::*;
	import i2c_master_axil_pkg::i2c_reg_map;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
	`include "axil_seq_defines.svh"

	`include "api_single_rw_seq.sv"

	`include "memory_slave_seq.sv"

	`include "config_seq.sv"
	`include "write_read_seq.sv"

endpackage

`endif


