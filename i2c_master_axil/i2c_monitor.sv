class i2c_monitor extends uvm_monitor;
    virtual i2c_if vif;
    uvm_analysis_port #(i2c_trans) ap;
    
    `uvm_component_utils(i2c_monitor)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task monitor_i2c_signals();
        forever begin
            @(vif.monitor_cb);
            if ($time % 1000 == 0) begin  // Print every 1000 time units
                `uvm_info("I2C_MON", $sformatf("I2C signals at time %0t: scl_o=%b scl_t=%b sda_o=%b sda_t=%b", 
                    $time, vif.monitor_cb.scl_o, vif.monitor_cb.scl_t, 
                    vif.monitor_cb.sda_o, vif.monitor_cb.sda_t), UVM_LOW)
            end
        end
    endtask

    task wait_for_start();
        bit prev_sda, prev_scl;
        prev_sda = vif.monitor_cb.sda_o;
        prev_scl = vif.monitor_cb.scl_o;
        
        do begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.scl_o && prev_scl && prev_sda && !vif.monitor_cb.sda_o) begin
                `uvm_info("I2C_MON", $sformatf("START condition detected at time %0t", $time), UVM_LOW)
                return;
            end
            prev_sda = vif.monitor_cb.sda_o;
            prev_scl = vif.monitor_cb.scl_o;
        end while (1);
    endtask

    task sample_bit(output bit b);
        int scl_high_time = 0;
        
        do begin
            @(vif.monitor_cb);
        end while (!vif.monitor_cb.scl_o);
        
        while (vif.monitor_cb.scl_o) begin
            scl_high_time++;
            @(vif.monitor_cb);
        end
        
        b = vif.monitor_cb.sda_o;
        `uvm_info("I2C_MON", $sformatf("Sampled bit=%b at time %0t (SCL high for %0d cycles)", 
            b, $time, scl_high_time), UVM_HIGH)
    endtask

    task run_phase(uvm_phase phase);
        logic [7:0] addr_byte;
        logic [7:0] data_byte;
        bit ack;
        
        fork
            monitor_i2c_signals();
        join_none
        
        forever begin
            i2c_trans trans;
            
            `uvm_info("I2C_MON", "Waiting for I2C transaction...", UVM_LOW)
            
            wait_for_start();
            
            trans = i2c_trans::type_id::create("trans");
            
            for(int i = 7; i >= 0; i--) begin
                bit b;
                sample_bit(b);
                addr_byte[i] = b;
                `uvm_info("I2C_MON", $sformatf("Address bit[%0d]=%b at time %0t", 
                    i, b, $time), UVM_HIGH)
            end
            
            sample_bit(ack);
            `uvm_info("I2C_MON", $sformatf("Address byte=0x%02h, ACK=%b at time %0t", 
                addr_byte, ack, $time), UVM_LOW)
            
            trans.addr = addr_byte[7:1];
            trans.read = addr_byte[0];
            
            if (!ack) begin
                if (trans.read) begin
                    do begin
                        for(int i = 7; i >= 0; i--) begin
                            bit b;
                            sample_bit(b);
                            data_byte[i] = b;
                        end
                        sample_bit(ack);
                        trans.data = data_byte;
                        
                        `uvm_info("I2C_MON", $sformatf("Read data=0x%02h, ACK=%b at time %0t", 
                            data_byte, ack, $time), UVM_LOW)
                        
                        ap.write(trans);
                    end while (!ack);
                end else begin
                    for(int i = 7; i >= 0; i--) begin
                        bit b;
                        sample_bit(b);
                        data_byte[i] = b;
                    end
                    sample_bit(ack);
                    trans.data = data_byte;
                    
                    `uvm_info("I2C_MON", $sformatf("Write data=0x%02h, ACK=%b at time %0t", 
                        data_byte, ack, $time), UVM_LOW)
                    
                    ap.write(trans);
                end
            end
        end
    endtask
endclass