class i2c_master_test extends i2c_master_base_test;
    `uvm_component_utils(i2c_master_test)
    
    function new(string name = "i2c_master_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        config_seq config_seq_i;
        write_read_seq wr_seq_i;
        
        phase.raise_objection(this);
        
        config_seq_i = config_seq::type_id::create("config_seq");
        `uvm_info("TEST", "Starting config sequence", UVM_LOW)
        config_seq_i.start(env.axil_seqr);
        
        #1000;
        if (env.axil_seqr == null)
        `uvm_fatal("test", "seqr null");
        
        wr_seq_i = write_read_seq::type_id::create("wr_seq");
        `uvm_info("TEST", "Starting write/read sequence", UVM_LOW)
        wr_seq_i.start(env.axil_seqr);
        
        #10000;
        
        phase.drop_objection(this);
    endtask
endclass