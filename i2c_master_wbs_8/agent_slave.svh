`ifndef AGENT_SLAVE
`define AGENT_SLAVE

`include "driver_slave.svh"

class read_agent_slave extends uvm_agent;
  
    // register agent as component to UVM Factory
    `uvm_component_utils(read_agent_slave);

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    // initialize handlers for agent components
    read_driver_slave read_driver_slave_handler;

    // create components
    function void build_phase(uvm_phase phase);
        read_driver_slave_handler = read_driver_slave::type_id::create("read_driver_slave_handler", this);
    endfunction

endclass

`endif