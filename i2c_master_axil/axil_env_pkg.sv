`ifndef AXIL_ENV_PKG
`define AXIL_ENV_PKG

package axil_env_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	// import dut_params_pkg::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "i2c_reg_map.sv"

  `include "axil_seq_item.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"
  
  `include "i2c_trans.sv"
  `include "i2c_monitor.sv"
  `include "i2c_responder.sv"
  
  `include "i2c_master_scoreboard.sv"
  `include "i2c_master_coverage.sv"
  `include "i2c_master_env.sv"

endpackage

`endif


