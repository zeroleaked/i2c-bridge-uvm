class i2c_master_base_test extends uvm_test;
    i2c_master_env env;
    
    `uvm_component_utils(i2c_master_base_test)
    
    function new(string name = "i2c_master_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_master_env::type_id::create("env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        i2c_config_seq config_seq;
        
        phase.raise_objection(this);
        
        config_seq = i2c_config_seq::type_id::create("config_seq");
        config_seq.start(env.axil_seqr);
        
        #1000;
        phase.drop_objection(this);
    endtask
endclass