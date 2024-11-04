`include "uvm_macros.svh"
`include "packages.svh"

module read_testbench;
  import uvm_pkg::*;
  import packages::*;
  
  // Instantiate the interface
  top_interface top_interface_inst();
  
  // Instantiate the DUT and connect it to the interface
  i2c_master_wbs_8_interfaced dut(.top_if(top_interface_inst));

  // Clock and reset control
  initial begin
    top_interface_inst.clk = 0;
    forever begin
      #5;
      top_interface_inst.clk = ~top_interface_inst.clk;
    end
  end
  
  initial begin
    // Place the interface into the UVM configuration database
    uvm_config_db#(virtual top_interface)::set(null, "*", "top_vinterface", top_interface_inst);
    // Start the test
    run_test("read_test");
  end
  
  // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, read_testbench);
  end
  
endmodule