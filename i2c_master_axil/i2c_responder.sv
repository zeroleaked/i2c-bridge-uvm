class i2c_responder extends uvm_component;
    virtual i2c_if vif;
    bit [7:0] memory[bit [6:0]]; // Simple memory model
    bit [6:0] my_address;
    
    `uvm_component_utils(i2c_responder)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        my_address = 7'h50; // Default address
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Failed to get I2C virtual interface")
    endfunction
    
    task monitor_start_condition();
        @(negedge vif.sda_o iff vif.scl_o === 1);  
        `uvm_info("I2C_RESP", "START condition detected", UVM_LOW)
    endtask
    
    task receive_byte(output bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_o);  
            data[i] = vif.sda_o;
            @(negedge vif.scl_o);  
        end
    endtask
    
    task send_ack();
        @(posedge vif.scl_o);
        vif.sda_i <= 0;  // ACK
        @(negedge vif.scl_o);
        vif.sda_i <= 1;  // Return to high
    endtask

    task send_byte(bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(negedge vif.scl_o);
            vif.sda_i <= data[i];
            @(posedge vif.scl_o);
        end
        @(negedge vif.scl_o);
        vif.sda_i <= 1;  // Return to high
    endtask

    task run_phase(uvm_phase phase);
        bit [7:0] addr_byte;
        bit [7:0] data_byte;
        bit is_read;
        
        vif.sda_i <= 1;  
        vif.scl_i <= 1;  
        
        forever begin
            monitor_start_condition();
            
            receive_byte(addr_byte);
            
            if((addr_byte[7:1] == my_address)) begin
                is_read = addr_byte[0];
                send_ack();
                
                if(is_read) begin
                    data_byte = memory[addr_byte[7:1]];
                    send_byte(data_byte);
                    `uvm_info("I2C_RESP", $sformatf("Sending data: %h", data_byte), UVM_LOW)
                end else begin
                    receive_byte(data_byte);
                    memory[addr_byte[7:1]] = data_byte;
                    send_ack();
                    `uvm_info("I2C_RESP", $sformatf("Received data: %h", data_byte), UVM_LOW)
                end
            end
        end
    endtask

    // Utility functions to set/get memory values
    function void set_memory(bit [6:0] addr, bit [7:0] data);
        memory[addr] = data;
    endfunction
    
    function bit [7:0] get_memory(bit [6:0] addr);
        return memory[addr];
    endfunction
endclass
