`ifndef AGENT
`define AGENT

`include "driver.svh"
`include "monitor.svh"
`include "sequence.svh"

class read_agent extends uvm_agent;
  
    // register agent as component to UVM Factory
    uvm_analysis_port #(monitor_sequence_item) bypass_port;
    `uvm_component_utils(read_agent);

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    // initialize handlers for agent components
    read_sequencer read_sequencer_handler;
    read_driver read_driver_handler;
    read_monitor read_monitor_handler;

    // create components
    function void build_phase(uvm_phase phase);
        read_sequencer_handler = read_sequencer::type_id::create("read_sequencer_handler", this);
        read_driver_handler = read_driver::type_id::create("read_driver_handler", this);
        read_monitor_handler = read_monitor::type_id::create("read_monitor_handler", this);
        bypass_port = new("bypass_port", this);
    endfunction

     // connect phase function
    function void connect_phase(uvm_phase phase);
        read_driver_handler.seq_item_port.connect(read_sequencer_handler.seq_item_export);
        read_monitor_handler.ap.connect(bypass_port);
    endfunction
  
    // run phase task
    task run_phase (uvm_phase phase);
    phase.raise_objection(this);
    begin
        read_sequence seq;
        seq = read_sequence::type_id::create("seq");
        seq.start(read_sequencer_handler);
    end
    phase.drop_objection(this);

    endtask

endclass

`endif