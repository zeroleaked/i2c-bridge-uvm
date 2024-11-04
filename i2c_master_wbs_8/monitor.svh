`ifndef MONITOR
`define MONITOR

class monitor_sequence_item extends uvm_sequence_item;

    logic   [2:0]  addr;
    logic   [7:0]  data;

    // register object to UVM Factory
    `uvm_object_utils(monitor_sequence_item);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

endclass

class read_monitor extends uvm_monitor;
  
    // register agent as component to UVM Factory
    `uvm_component_utils(read_monitor)

    // default constructor
    uvm_analysis_port #(monitor_sequence_item) ap;
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // set driver-DUT interface
    virtual top_interface top_vinterface;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual top_interface)::get(this, "", "top_vinterface", top_vinterface)) begin
            `uvm_error("", "uvm_config_db::driver.svh get failed on BUILD_PHASE")
        end
        ap = new("ap", this);
    endfunction

    // monitor behavior
    task run_phase(uvm_phase phase);
        monitor_sequence_item monitor_item;
        monitor_item = monitor_sequence_item::type_id::create("monitor_item");
        forever begin
            @(top_vinterface.wbs_dat_o);
//            `uvm_info("MONITOR", $sformatf("New read data:  0x%08h from address 0x%08h", top_vinterface.SDAT_O, top_vinterface.ADR_I), UVM_MEDIUM)
            monitor_item.addr = top_vinterface.wbs_adr_i;
            monitor_item.data = top_vinterface.wbs_dat_o;
            ap.write(monitor_item);
        end
    endtask

endclass

`endif