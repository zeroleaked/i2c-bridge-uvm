`ifndef SEQUENCER
`define SEQUENCER

class read_sequence_item extends uvm_sequence_item;

    // driving signals
    logic   [2:0]  addr;
    logic   [7:0]  data;

    // register object to UVM Factory
    `uvm_object_utils(read_sequence_item);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

endclass

integer i;
class read_sequence extends uvm_sequence #(read_sequence_item);

    // register object to UVM Factory
    `uvm_object_utils(read_sequence);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // create sequence using the sequence_item
    task body;
        begin
            // Write to prescaler
            // for(i = 6; i < 8'h8; i=i+1) begin
            //     req = read_sequence_item::type_id::create("req");
            //     start_item(req);
            //     req.addr = i;
            //     req.data = i<<2;

            //     `uvm_info("SEQUENCE", $sformatf("Driving request signal: addr:0x%1h, data:0x%2h", req.addr,  req.data), UVM_MEDIUM)
                
            //     finish_item(req);
            // end

            // ****** Write device address *********
            `uvm_info("SEQUENCE", $sformatf("Attempting to write: device_addr:0x%2h, reg_addr:0x%2h", 7'h6,  8'ha), UVM_MEDIUM)
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h2;
            req.data = 7'h6;
            finish_item(req);
            // Write register address
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h4;
            req.data = 8'ha;
            finish_item(req);
            // Write command
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h3;
            req.data = 8'h14; // cmd_write | cmd_stop
            finish_item(req);
            
            // coba coba
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h3;
            req.data = 8'h02; // cmd_read
            finish_item(req);

            // Write data 1  -- addr: 0xa
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h4;
            req.data = 8'h33;
            finish_item(req);
            // Write data command 1
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h3;
            req.data = 8'h04; // cmd_write
            finish_item(req);

            // Write data 2 -- addr: 0xb
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h4;
            req.data = 8'haa;
            finish_item(req);
            // Write data command 2
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h3;
            req.data = 8'h14; // cmd_stop | cmd_write
            finish_item(req);
            // Wait
            // #10000;

            // ****** Read device address *******
            `uvm_info("SEQUENCE", $sformatf("Attempting to read: device_addr:0x%2h, reg_addr:0x%2h", 7'h6,  8'ha), UVM_MEDIUM)
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h2;
            req.data = 7'h6;
            finish_item(req);
            // Write register address
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h4;
            req.data = 8'hb;
            finish_item(req);
            // Write command
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h3;
            req.data = 8'h04; // cmd_write
            finish_item(req);
            // Read command
            req = read_sequence_item::type_id::create("req");
            start_item(req);
            req.addr = 3'h3;
            req.data = 8'h13; // cmd_stop | cmd_read | cmd_start
            finish_item(req);
            // // Finish read command
            // req = read_sequence_item::type_id::create("req");
            // start_item(req);
            // req.addr = 3'h3;
            // req.data = 8'h12; // cmd_stop | cmd_read
            // finish_item(req);
            `uvm_info("SEQUENCE", "Waiting for the process to finish", UVM_MEDIUM)
            #10000;

            
        end
    endtask

endclass

class read_sequencer extends uvm_sequencer #(read_sequence_item);

    // register sequence to UVM factory
    `uvm_component_utils(read_sequencer)

    // create the sequence constructor default
    function new (string name, uvm_component parent); // default name my_seq
        // call the base class virtual function
        super.new(name, parent);
    endfunction

endclass

`endif