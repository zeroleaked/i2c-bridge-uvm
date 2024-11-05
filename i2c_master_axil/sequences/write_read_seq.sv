class write_read_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(write_read_seq)
    
    function new(string name = "write_read_seq");
        super.new(name);
    endfunction

    task body();
        axil_seq_item req;
        bit [6:0] slave_addr = 7'h50;
        bit [7:0] data_to_write = 8'hA5;
		api_single_rw_seq api_rw_seq = api_single_rw_seq::type_id::create("req");
		int timeout_count = 0;

		api_rw_seq.configure(m_sequencer);
        
        `uvm_info("SEQ", "Starting I2C write/read sequence", UVM_LOW)

		// WRITE TO I2C SLAVE
		api_rw_seq.write_register_command(slave_addr, CMD_START | CMD_WR_M); // address and start
		api_rw_seq.write_register_data(8'h0, DATA_DEFAULT); // register 0
		api_rw_seq.write_register_data(data_to_write, DATA_LAST); // for write_multiple
		api_rw_seq.write_register_command(7'h0, CMD_STOP); // stop
        `uvm_info("SEQ", $sformatf("Sending I2C write command: addr=%h data=%h", slave_addr, data_to_write), UVM_LOW)
        
        do begin
			api_rw_seq.read_register_status();
            `uvm_info("SEQ", $sformatf("Status register: %h", api_rw_seq.rsp.data), UVM_LOW)
        end while (api_rw_seq.rsp.data[0]); // Wait until not busy
        
        #5000;
        

		// READ TO I2C SLAVE
		api_rw_seq.write_register_command(slave_addr, CMD_START | CMD_WRITE);
		api_rw_seq.write_register_data(8'h0, DATA_DEFAULT); // register 0
		api_rw_seq.write_register_command(slave_addr, CMD_START | CMD_READ | CMD_STOP);
        `uvm_info("SEQ", $sformatf("Sending I2C read command: addr=%h", slave_addr), UVM_LOW)
		
		api_rw_seq.read_register_data(); // register 0
        do begin
        	#100;
			timeout_count++;
			if (timeout_count > 10) begin
        		`uvm_info("SEQ", "Timeout waiting for a read", UVM_LOW)
				break;
			end
        end while (api_rw_seq.rsp.data[9:8] | DATA_VALID);
        
		`uvm_info("SEQ", $sformatf("Data register after read: %h", api_rw_seq.rsp.data), UVM_LOW)
    endtask
endclass