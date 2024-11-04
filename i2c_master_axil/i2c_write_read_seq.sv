class i2c_write_read_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(i2c_write_read_seq)
    
    function new(string name = "i2c_write_read_seq");
        super.new(name);
    endfunction

    task body();
        axil_seq_item req;
        bit [6:0] slave_addr = 7'h50;
        bit [7:0] data_to_write = 8'hA5;
        
        `uvm_info("SEQ", "Starting I2C write/read sequence", UVM_LOW)
        
        req = axil_seq_item::type_id::create("req");
        start_item(req);
        req.addr = i2c_reg_map::CMD_REG;
        req.data = {21'h0, 1'b1, 1'b0, 1'b1, 1'b0, slave_addr};  // START + WRITE + STOP
        req.read = 0;
        req.strb = 4'b0011;
        `uvm_info("SEQ", $sformatf("Sending I2C write command: addr=%h data=%h", slave_addr, data_to_write), UVM_LOW)
        finish_item(req);

        start_item(req);
        req.addr = i2c_reg_map::DATA_REG;
        req.data = {22'h0, 1'b1, 1'b1, data_to_write};
        req.read = 0;
        req.strb = 4'b0011;
        `uvm_info("SEQ", $sformatf("Sending I2C write command: addr=%h data=%h", slave_addr, data_to_write), UVM_LOW)
        finish_item(req);
        
        do begin
            req = axil_seq_item::type_id::create("req");
            start_item(req);
            req.addr = i2c_reg_map::STATUS_REG;
            req.read = 1;
            finish_item(req);
            `uvm_info("SEQ", $sformatf("Status register: %h", req.data), UVM_LOW)
        end while (req.data[2]); // Wait until not busy
        
        #5000;
        
        req = axil_seq_item::type_id::create("req");
        start_item(req);
        req.addr = i2c_reg_map::CMD_REG;
        req.data = {16'h0, slave_addr, 1'b1, 8'h0}; // Read command
        req.read = 0;
        req.strb = 4'hF;
        `uvm_info("SEQ", $sformatf("Sending I2C read command: addr=%h", slave_addr), UVM_LOW)
        finish_item(req);
        
        do begin
            req = axil_seq_item::type_id::create("req");
            start_item(req);
            req.addr = i2c_reg_map::STATUS_REG;
            req.read = 1;
            finish_item(req);
            `uvm_info("SEQ", $sformatf("Status after read: %h", req.data), UVM_LOW)
        end while (req.data[2]);
    endtask
endclass