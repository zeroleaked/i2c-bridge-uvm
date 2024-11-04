`include "uvm_macros.svh"
`include "packages.svh"

module read_testbench;
  import uvm_pkg::*;
  import packages::*;
  
  // Instantiate the interface
  top_interface top_if();
  
  // Instantiate the DUT and connect it to the interface
  i2c_master_wbs_8 DUT(
    // Generic signals
    .clk(top_if.clk),
    .rst(top_if.rst),

    // Host interface
    .wbs_adr_i(top_if.wbs_adr_i),
    .wbs_dat_i(top_if.wbs_dat_i),
    .wbs_dat_o(top_if.wbs_dat_o),
    .wbs_we_i(top_if.wbs_we_i), 
    .wbs_stb_i(top_if.wbs_stb_i),
    .wbs_ack_o(top_if.wbs_ack_o),
    .wbs_cyc_i(top_if.wbs_cyc_i),

    // I2C interface
    .i2c_scl_i(scl_i),
    .i2c_scl_o(dut_scl_o),
    .i2c_scl_t(top_if.i2c_scl_t),
    .i2c_sda_i(sda_i),
    .i2c_sda_o(dut_sda_o),
    .i2c_sda_t(top_if.i2c_sda_t)
  );

  // Clock and reset control
  initial begin
    top_if.clk = 0;
    forever begin
      #5;
      top_if.clk = ~top_if.clk;
    end
  end
  
  initial begin
    // Place the interface into the UVM configuration database
    uvm_config_db#(virtual top_interface)::set(null, "*", "top_vinterface", top_if);
    // Start the test
    run_test("read_test");
  end
  
  // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, read_testbench);
  end
  
endmodule