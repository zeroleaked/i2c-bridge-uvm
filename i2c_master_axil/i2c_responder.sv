class i2c_responder extends uvm_component;
    virtual i2c_if vif;
    bit [7:0] memory[bit [7:0]]; // Simple memory model
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
    
    task receive_byte(output bit [7:0] data, output bit is_repeat_start);
		is_repeat_start = 0;
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_o);  
            data[i] = vif.sda_o;
            `uvm_info("HAHAHAHAHA PER-NAME", $sformatf("[%t] bit %d = %d", $time, i, data[i]), UVM_NONE)

			// look for repeat start
			if ((i == 7) & vif.sda_o) begin
				wait (!vif.scl_o | !vif.sda_o);
				if (!vif.sda_o) begin
            		`uvm_info(get_type_name(), "repeat start detected!", UVM_NONE);
					is_repeat_start = 1;
					break;
				end
			end
			wait (!vif.scl_o);
        end

		// same, but has been delayed one scl
		if (is_repeat_start) begin
			wait (!vif.scl_o);
			for (int i = 7; i >= 0; i--) begin
				wait (vif.scl_o);
				data[i] = vif.sda_o;
            	`uvm_info(get_type_name(), $sformatf("[%t] bit %d = %d", $time, i, data[i]), UVM_NONE)
				wait (!vif.scl_o);
			end
		end
    endtask
    
    task send_ack();
		repeat (6) @(vif.clk);
        vif.sda_i <= 0;  // ACK
        wait (vif.scl_o);
        wait (!vif.scl_o);
		repeat (3) @(vif.clk);
        vif.sda_i <= 1;  // Return to high
    endtask

    task send_byte(bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(negedge vif.scl_o);
            vif.sda_i <= data[i];
            `uvm_info("KENTUT", $sformatf("[%t] bit %d = %d", $time, i, data[i]), UVM_NONE)
            @(posedge vif.scl_o);
        end
        @(negedge vif.scl_o);
        vif.sda_i <= 1;  // Return to high
    endtask

    task run_phase(uvm_phase phase);
        bit [7:0] addr_byte;
        bit [7:0] reg_byte;
        bit [7:0] data_byte;
		bit is_repeat_start;
        
        vif.sda_i <= 1;  
        vif.scl_i <= 1;  
        
        forever begin
            monitor_start_condition();
            
            receive_byte(addr_byte, is_repeat_start);
            
            if((addr_byte[7:1] == my_address)) begin
                send_ack();

				receive_byte(reg_byte, is_repeat_start);
				send_ack();
				
				receive_byte(data_byte, is_repeat_start);

				if (!is_repeat_start) begin // write operation
					memory[reg_byte] = data_byte;
					send_ack();
					`uvm_info("I2C_RESP", $sformatf("Received data: %h", data_byte), UVM_LOW)
				end
				else if ((data_byte[7:1] == my_address) & data_byte[0] == 1) begin // read operation
					send_ack();
					send_byte(memory[reg_byte]);
					`uvm_info("I2C_RESP", $sformatf("Send data: %h", memory[reg_byte]), UVM_LOW)
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
