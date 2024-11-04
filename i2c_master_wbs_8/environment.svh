`ifndef ENVIRONMENT
`define ENVIRONMENT

`include "agent.svh"
`include "agent_slave.svh"
`include "scoreboard.svh"

class read_environment extends uvm_env;

    // register agent as component to UVM Factory
    `uvm_component_utils(read_environment);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    read_agent read_agent_handler;
    read_agent_slave read_agent_slave_handler;
    read_scoreboard read_scoreboard_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        read_agent_handler = read_agent::type_id::create("read_agent_handler", this);
        read_agent_slave_handler = read_agent_slave::type_id::create("read_agent_slave_handler", this);
        read_scoreboard_handler = read_scoreboard::type_id::create("read_scoreboard_handler", this);
    endfunction
    
    // connect phase
    function void connect_phase(uvm_phase phase);
        // read_agent_handler.read_monitor_handler.ap.connect(read_scoreboard_handler.ae);
        read_agent_handler.bypass_port.connect(read_scoreboard_handler.ae);
    endfunction
  
endclass

`endif