`ifndef SCOREBOARD
`define SCOREBOARD

class read_scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(read_scoreboard)
  
  uvm_analysis_imp #(monitor_sequence_item, read_scoreboard) ae;
  function new (string name = "read_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    ae = new("ae", this);
  endfunction
  
  function void write(monitor_sequence_item monitor_item);
    `uvm_info("SCOREBOARD", $sformatf("New data obtained=0x%2h from address 0x%1h", monitor_item.data, monitor_item.addr), UVM_MEDIUM)
  endfunction
  
endclass

`endif