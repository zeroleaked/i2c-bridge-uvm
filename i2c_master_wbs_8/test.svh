`ifndef test
`define TEST

`include "environment.svh"

class read_test extends uvm_test;

    // register agent as component to UVM Factory
    `uvm_component_utils(read_test);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    read_environment read_environment_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        read_environment_handler = read_environment::type_id::create("read_environment_handler", this);
    endfunction
  
endclass

`endif