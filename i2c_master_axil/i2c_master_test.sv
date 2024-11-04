class i2c_master_test extends i2c_master_base_test;
    `uvm_component_utils(i2c_master_test)
    
    function new(string name = "i2c_master_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        i2c_config_seq config_seq;
        i2c_write_read_seq wr_seq;
        
        phase.raise_objection(this);
        
        config_seq = i2c_config_seq::type_id::create("config_seq");
        `uvm_info("TEST", "Starting config sequence", UVM_LOW)
        config_seq.start(env.axil_seqr);
        
        #1000;
        
        wr_seq = i2c_write_read_seq::type_id::create("wr_seq");
        `uvm_info("TEST", "Starting write/read sequence", UVM_LOW)
        wr_seq.start(env.axil_seqr);
        
        #10000;
        
        phase.drop_objection(this);
    endtask
endclass