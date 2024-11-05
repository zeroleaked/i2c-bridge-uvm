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
        bit [31:0] status;
        int timeout_count = 0;
        const int TIMEOUT_MAX = 1000; 

        api_rw_seq.configure(m_sequencer);
        
        `uvm_info("SEQ", "Starting I2C write/read sequence", UVM_LOW)

        // WRITE TO I2C SLAVE
        api_rw_seq.write_register_command(slave_addr, CMD_START | CMD_WR_M);
        api_rw_seq.write_register_data(8'h0, DATA_DEFAULT);
        api_rw_seq.write_register_data(data_to_write, DATA_LAST);
        api_rw_seq.write_register_command(7'h0, CMD_STOP);
        `uvm_info("SEQ", $sformatf("Sending I2C write command: addr=%h data=%h", 
                  slave_addr, data_to_write), UVM_LOW)
        
        do begin
            #1000; 
            api_rw_seq.read_register_status();
            status = api_rw_seq.rsp.data;
            timeout_count++;
            if (timeout_count >= TIMEOUT_MAX) begin
                `uvm_error("SEQ", "Timeout waiting for write to complete")
                break;
            end
        end while (status[0]); 
        
        #5000;
        timeout_count = 0;

        // READ FROM I2C SLAVE
        api_rw_seq.write_register_command(slave_addr, CMD_START | CMD_WRITE);
        api_rw_seq.write_register_data(8'h0, DATA_DEFAULT);
        api_rw_seq.write_register_command(slave_addr, CMD_START | CMD_READ | CMD_STOP);
        `uvm_info("SEQ", $sformatf("Sending I2C read command: addr=%h", slave_addr), UVM_LOW)
        
        do begin
            #1000;
            api_rw_seq.read_register_data();
            timeout_count++;
            if (timeout_count >= TIMEOUT_MAX) begin
                `uvm_info("SEQ", "Timeout waiting for read data", UVM_LOW)
                break;
            end
        end while (!(api_rw_seq.rsp.data[9:8] & DATA_VALID));
        
        if (timeout_count < TIMEOUT_MAX) begin
            `uvm_info("SEQ", $sformatf("Read data: %h", api_rw_seq.rsp.data[7:0]), UVM_LOW)
        end

    endtask
endclass
