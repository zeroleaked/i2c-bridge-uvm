class i2c_master_env extends uvm_env;
    axil_driver    axil_drv;
    axil_monitor   axil_mon;
    i2c_monitor    i2c_mon;
    uvm_sequencer #(axil_seq_item) axil_seqr;
    i2c_master_scoreboard scbd;
    i2c_master_coverage cov;

    i2c_responder i2c_resp;
    
    `uvm_component_utils(i2c_master_env)
    
    function new(string name = "i2c_master_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        axil_drv = axil_driver::type_id::create("axil_drv", this);
        axil_mon = axil_monitor::type_id::create("axil_mon", this);
        i2c_mon = i2c_monitor::type_id::create("i2c_mon", this);
        axil_seqr = uvm_sequencer#(axil_seq_item)::type_id::create("axil_seqr", this);
        scbd = i2c_master_scoreboard::type_id::create("scbd", this);
        cov = i2c_master_coverage::type_id::create("cov", this);

        i2c_resp = i2c_responder::type_id::create("i2c_resp", this);  
    endfunction
    
function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axil_drv.seq_item_port.connect(axil_seqr.seq_item_export);
    axil_mon.ap.connect(scbd.axil_export);
    i2c_mon.ap.connect(scbd.i2c_export);
    axil_mon.ap.connect(cov.analysis_export);
    `uvm_info("ENV", "All connections completed", UVM_LOW)
endfunction
endclass
