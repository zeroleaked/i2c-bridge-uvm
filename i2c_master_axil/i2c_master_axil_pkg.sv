`ifndef I2C_MASTER_AXIL_PKG
`define I2C_MASTER_AXIL_PKG

package i2c_master_axil_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	import dut_params_pkg::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "i2c_reg_map.sv"

  `include "axil_seq_item.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"
  
  `include "i2c_trans.sv"
  `include "i2c_monitor.sv"
  
  `include "i2c_master_scoreboard.sv"
  `include "i2c_master_coverage.sv"
  `include "i2c_master_env.sv"

  `include "i2c_write_read_seq.sv"
  `include "i2c_config_seq.sv"

  `include "i2c_master_base_test.sv"
  `include "i2c_master_test.sv"

endpackage

`endif


