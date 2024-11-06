class axil_monitor extends uvm_monitor;
    virtual axil_if vif;
    uvm_analysis_port #(axil_seq_item) ap;
    
    `uvm_component_utils(axil_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            axil_seq_item tr = axil_seq_item::type_id::create("tr");
            collect_transaction(tr);
            ap.write(tr);
        end
    endtask

task collect_transaction(axil_seq_item tr);
    fork
        begin : write_collection
            @(vif.monitor_cb iff vif.monitor_cb.awvalid && vif.monitor_cb.awready);
            tr = axil_seq_item::type_id::create("tr"); // Create new transaction
            tr.addr = vif.monitor_cb.awaddr;
            tr.read = 0;
            
            @(vif.monitor_cb iff vif.monitor_cb.wvalid && vif.monitor_cb.wready);
            tr.data = vif.monitor_cb.wdata;
            tr.strb = vif.monitor_cb.wstrb;
            
            @(vif.monitor_cb iff vif.monitor_cb.bvalid && vif.monitor_cb.bready);
            
            // `uvm_info("AXIL_MON", $sformatf("Collected write transaction: addr=%h data=%h", 
            //          tr.addr, tr.data), UVM_LOW)
            ap.write(tr);
        end
        
        begin : read_collection
            @(vif.monitor_cb iff vif.monitor_cb.arvalid && vif.monitor_cb.arready);
            tr = axil_seq_item::type_id::create("tr"); // Create new transaction
            tr.addr = vif.monitor_cb.araddr;
            tr.read = 1;
            
            @(vif.monitor_cb iff vif.monitor_cb.rvalid && vif.monitor_cb.rready);
            tr.data = vif.monitor_cb.rdata;
            
            // `uvm_info("AXIL_MON", $sformatf("Collected read transaction: addr=%h data=%h", 
                     // tr.addr, tr.data), UVM_LOW)
            ap.write(tr);
        end
    join_any
    disable fork;
endtask
endclass
