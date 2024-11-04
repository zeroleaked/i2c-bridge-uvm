class i2c_write_read_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(i2c_write_read_seq)
    
    function new(string name = "i2c_write_read_seq");
        super.new(name);
    endfunction

    task body();
        axil_seq_item req;
        bit [6:0] slave_addr = 7'h50;
        bit [7:0] data_to_write = 8'hA5;
		api_single_rw_seq api_rw_seq = api_single_rw_seq::type_id::create("req");

		api_rw_seq.configure(m_sequencer);
        
        `uvm_info("SEQ", "Starting I2C write/read sequence", UVM_LOW)

		api_rw_seq.write_register_command(slave_addr, 1);
		api_rw_seq.write_register_data(data_to_write);
        `uvm_info("SEQ", $sformatf("Sending I2C write command: addr=%h data=%h", slave_addr, data_to_write), UVM_LOW)
        
        do begin
			api_rw_seq.read_register_status();
            `uvm_info("SEQ", $sformatf("Status register: %h", api_rw_seq.rsp.data), UVM_LOW)
        end while (api_rw_seq.rsp.data[0]); // Wait until not busy
        
        #5000;
        
		api_rw_seq.write_register_command(slave_addr, 0);
        `uvm_info("SEQ", $sformatf("Sending I2C read command: addr=%h", slave_addr), UVM_LOW)
        
        do begin
			api_rw_seq.read_register_status();
            `uvm_info("SEQ", $sformatf("Status after read: %h", api_rw_seq.rsp.data), UVM_LOW)
        end while (api_rw_seq.rsp.data[2]);
    endtask
endclass