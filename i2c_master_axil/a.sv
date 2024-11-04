`include "uvm_macros.svh"
import uvm_pkg::*;
import dut_params_pkg::*;


class i2c_reg_map;
    typedef enum bit [3:0] {
        CTRL_REG     = 4'h0,
        STATUS_REG   = 4'h1,
        PRESCALE_REG = 4'h2,
        CMD_REG      = 4'h3
    } reg_addr_t;

    typedef struct packed {
        bit [31:1] reserved;
        bit        enable;
    } ctrl_reg_t;

    typedef struct packed {
        bit [31:4] reserved;
        bit        cmd_full;
        bit        cmd_empty;
        bit        busy;
        bit        error;
    } status_reg_t;
endclass

class axil_seq_item extends uvm_sequence_item;
    rand bit [3:0]  addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;
    rand bit        read;
    
    `uvm_object_utils_begin(axil_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(read, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axil_seq_item");
        super.new(name);
    endfunction

    constraint addr_c {
        addr inside {[0:3]};
    }
endclass

class i2c_trans extends uvm_sequence_item;
    rand bit [6:0] addr;
    rand bit       read;
    rand bit [7:0] data;
    
    `uvm_object_utils_begin(i2c_trans)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(read, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_trans");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("addr=%h read=%b data=%h", addr, read, data);
    endfunction
endclass
class i2c_config_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(i2c_config_seq)

    function new(string name = "i2c_config_seq");
        super.new(name);
    endfunction

    task body();
        axil_seq_item req;

        req = axil_seq_item::type_id::create("req");
        start_item(req);
        req.addr = i2c_reg_map::PRESCALE_REG;
        req.data = DEFAULT_PRESCALE;  // Now this will be recognized
        req.read = 0;
        req.strb = 4'hF;
        finish_item(req);

        req = axil_seq_item::type_id::create("req");
        start_item(req);
        req.addr = i2c_reg_map::CTRL_REG;
        req.data = 32'h1; // Enable bit
        req.read = 0;
        req.strb = 4'hF;
        finish_item(req);
    endtask
endclass

class axil_driver extends uvm_driver #(axil_seq_item);
    virtual axil_if vif;  // Make sure this matches your interface type
    
    `uvm_component_utils(axil_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("Virtual interface not found for %s", get_full_name()))
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transaction(axil_seq_item req);
        if(req.read) begin
            @(vif.driver_cb);
            vif.driver_cb.araddr <= req.addr;
            vif.driver_cb.arvalid <= 1;
            vif.driver_cb.arprot <= 0;
            
            @(vif.driver_cb);
            while(!vif.driver_cb.arready) @(vif.driver_cb);
            vif.driver_cb.arvalid <= 0;
            
            vif.driver_cb.rready <= 1;
            @(vif.driver_cb);
            while(!vif.driver_cb.rvalid) @(vif.driver_cb);
            req.data = vif.driver_cb.rdata;
            vif.driver_cb.rready <= 0;
        end else begin
            @(vif.driver_cb);
            vif.driver_cb.awaddr <= req.addr;
            vif.driver_cb.awvalid <= 1;
            vif.driver_cb.awprot <= 0;
            vif.driver_cb.wdata <= req.data;
            vif.driver_cb.wstrb <= req.strb;
            vif.driver_cb.wvalid <= 1;
            
            @(vif.driver_cb);
            while(!vif.driver_cb.awready || !vif.driver_cb.wready) @(vif.driver_cb);
            vif.driver_cb.awvalid <= 0;
            vif.driver_cb.wvalid <= 0;
            
            vif.driver_cb.bready <= 1;
            @(vif.driver_cb);
            while(!vif.driver_cb.bvalid) @(vif.driver_cb);
            vif.driver_cb.bready <= 0;
        end
    endtask
endclass

class axil_monitor extends uvm_monitor;
    virtual axil_if vif;
    uvm_analysis_port #(axil_seq_item) ap;
    
    `uvm_component_utils(axil_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            axil_seq_item tr = axil_seq_item::type_id::create("tr");
            collect_transaction(tr);
            ap.write(tr);
        end
    endtask

task collect_transaction(axil_seq_item tr);
    fork
        begin : write_collection
            @(vif.monitor_cb iff vif.monitor_cb.awvalid && vif.monitor_cb.awready);
            tr = axil_seq_item::type_id::create("tr"); // Create new transaction
            tr.addr = vif.monitor_cb.awaddr;
            tr.read = 0;
            
            @(vif.monitor_cb iff vif.monitor_cb.wvalid && vif.monitor_cb.wready);
            tr.data = vif.monitor_cb.wdata;
            tr.strb = vif.monitor_cb.wstrb;
            
            @(vif.monitor_cb iff vif.monitor_cb.bvalid && vif.monitor_cb.bready);
            
            `uvm_info("AXIL_MON", $sformatf("Collected write transaction: addr=%h data=%h", 
                     tr.addr, tr.data), UVM_LOW)
            ap.write(tr);
        end
        
        begin : read_collection
            @(vif.monitor_cb iff vif.monitor_cb.arvalid && vif.monitor_cb.arready);
            tr = axil_seq_item::type_id::create("tr"); // Create new transaction
            tr.addr = vif.monitor_cb.araddr;
            tr.read = 1;
            
            @(vif.monitor_cb iff vif.monitor_cb.rvalid && vif.monitor_cb.rready);
            tr.data = vif.monitor_cb.rdata;
            
            `uvm_info("AXIL_MON", $sformatf("Collected read transaction: addr=%h data=%h", 
                     tr.addr, tr.data), UVM_LOW)
            ap.write(tr);
        end
    join_any
    disable fork;
endtask
endclass

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

class i2c_master_scoreboard extends uvm_scoreboard;
    `uvm_analysis_imp_decl(_axil)  // Add this line
    `uvm_analysis_imp_decl(_i2c)   // Add this line
    
    uvm_analysis_imp_axil #(axil_seq_item, i2c_master_scoreboard) axil_export;
    uvm_analysis_imp_i2c #(i2c_trans, i2c_master_scoreboard) i2c_export;
    
    i2c_trans expected_i2c_queue[$];
    bit [31:0] expected_seq[$];
    
    `uvm_component_utils(i2c_master_scoreboard)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        axil_export = new("axil_export", this);
        i2c_export = new("i2c_export", this);
    endfunction
    
    function void write_axil(axil_seq_item item);
        `uvm_info("SCBD", $sformatf("Received AXI transaction: addr=%h data=%h read=%b", 
                  item.addr, item.data, item.read), UVM_LOW)
        
        if(!item.read && item.addr == i2c_reg_map::CMD_REG) begin
            i2c_trans expected = i2c_trans::type_id::create("expected");
            expected.addr = (item.data >> 8) & 7'h7F; // Get slave address from proper field
            expected.read = (item.data >> 15) & 1'b1; // Get R/W bit
            expected.data = item.data & 8'hFF;        // Get data byte
            expected_i2c_queue.push_back(expected);
            
            `uvm_info("SCBD", $sformatf("Queued expected I2C transaction: addr=%h read=%b data=%h", 
                      expected.addr, expected.read, expected.data), UVM_LOW)
        end
        expected_seq.push_back(item.data);
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCBD", $sformatf("Total AXI transactions: %0d", expected_seq.size()), UVM_LOW)
        `uvm_info("SCBD", $sformatf("Remaining expected I2C transactions: %0d", 
                  expected_i2c_queue.size()), UVM_LOW)
        
        if(expected_i2c_queue.size() != 0) begin
            foreach(expected_i2c_queue[i]) begin
                `uvm_error("SCBD", $sformatf("Missing I2C transaction: %s", 
                          expected_i2c_queue[i].convert2string()))
            end
        end
    endfunction

function void write_i2c(i2c_trans item);
    if(expected_i2c_queue.size() > 0) begin
        i2c_trans expected = expected_i2c_queue.pop_front();
        `uvm_info("SCBD", $sformatf("Comparing I2C transaction - Expected: %s, Got: %s",
                                   expected.convert2string(), item.convert2string()), UVM_LOW)
        if(item.addr != expected.addr || item.read != expected.read || 
           (!item.read && item.data != expected.data)) begin
            `uvm_error("SCBD", $sformatf("I2C Mismatch! Expected: %s, Got: %s", 
                                       expected.convert2string(), item.convert2string()))
        end else begin
            `uvm_info("SCBD", "I2C transaction matched!", UVM_LOW)
        end
    end else begin
        `uvm_error("SCBD", $sformatf("Unexpected I2C transaction received: %s", 
                                    item.convert2string()))
    end
endfunction
    
endclass
class i2c_master_coverage extends uvm_subscriber #(axil_seq_item);
    `uvm_component_utils(i2c_master_coverage)
    
    covergroup axil_cg;
        addr_cp: coverpoint trans.addr {
            bins control = {i2c_reg_map::CTRL_REG};
            bins status = {i2c_reg_map::STATUS_REG};
            bins prescale = {i2c_reg_map::PRESCALE_REG};
            bins command = {i2c_reg_map::CMD_REG};
        }
        
        direction_cp: coverpoint trans.read;
        
        addr_dir_cross: cross addr_cp, direction_cp;
    endgroup
    
    axil_seq_item trans;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        axil_cg = new();
    endfunction
    
    function void write(axil_seq_item t);
        trans = t;
        axil_cg.sample();
    endfunction
endclass
class i2c_master_env extends uvm_env;
    axil_driver    axil_drv;
    axil_monitor   axil_mon;
    i2c_monitor    i2c_mon;
    uvm_sequencer #(axil_seq_item) axil_seqr;
    i2c_master_scoreboard scbd;
    i2c_master_coverage cov;
    
    `uvm_component_utils(i2c_master_env)
    
    function new(string name = "i2c_master_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        axil_drv = axil_driver::type_id::create("axil_drv", this);
        axil_mon = axil_monitor::type_id::create("axil_mon", this);
        i2c_mon = i2c_monitor::type_id::create("i2c_mon", this);
        axil_seqr = uvm_sequencer#(axil_seq_item)::type_id::create("axil_seqr", this);
        scbd = i2c_master_scoreboard::type_id::create("scbd", this);
        cov = i2c_master_coverage::type_id::create("cov", this);
    endfunction
    
function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axil_drv.seq_item_port.connect(axil_seqr.seq_item_export);
    axil_mon.ap.connect(scbd.axil_export);
    i2c_mon.ap.connect(scbd.i2c_export);
    axil_mon.ap.connect(cov.analysis_export);
    `uvm_info("ENV", "All connections completed", UVM_LOW)
endfunction
endclass
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

module tb_top;
    import dut_params_pkg::*;
    
    reg clk;
    reg rst;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        #100;
        rst = 0;
    end
    
    i2c_if  i2c_vif(clk, rst);
    axil_if axil_vif(clk, rst);
    
    i2c_master_axil #(
        .DEFAULT_PRESCALE(DEFAULT_PRESCALE),
        .FIXED_PRESCALE(FIXED_PRESCALE),
        .CMD_FIFO(CMD_FIFO),
        .CMD_FIFO_DEPTH(CMD_FIFO_DEPTH),
        .WRITE_FIFO(WRITE_FIFO),
        .WRITE_FIFO_DEPTH(WRITE_FIFO_DEPTH),
        .READ_FIFO(READ_FIFO),
        .READ_FIFO_DEPTH(READ_FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .s_axil_awaddr(axil_vif.awaddr),
        .s_axil_awprot(axil_vif.awprot),
        .s_axil_awvalid(axil_vif.awvalid),
        .s_axil_awready(axil_vif.awready),
        .s_axil_wdata(axil_vif.wdata),
        .s_axil_wstrb(axil_vif.wstrb),
        .s_axil_wvalid(axil_vif.wvalid),
        .s_axil_wready(axil_vif.wready),
        .s_axil_bresp(axil_vif.bresp),
        .s_axil_bvalid(axil_vif.bvalid),
        .s_axil_bready(axil_vif.bready),
        .s_axil_araddr(axil_vif.araddr),
        .s_axil_arprot(axil_vif.arprot),
        .s_axil_arvalid(axil_vif.arvalid),
        .s_axil_arready(axil_vif.arready),
        .s_axil_rdata(axil_vif.rdata),
        .s_axil_rresp(axil_vif.rresp),
        .s_axil_rvalid(axil_vif.rvalid),
        .s_axil_rready(axil_vif.rready),
        .i2c_scl_i(i2c_vif.scl_i),
        .i2c_scl_o(i2c_vif.scl_o),
        .i2c_scl_t(i2c_vif.scl_t),
        .i2c_sda_i(i2c_vif.sda_i),
        .i2c_sda_o(i2c_vif.sda_o),
        .i2c_sda_t(i2c_vif.sda_t)
    );

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
        req.data = {16'h0, slave_addr, 1'b0, data_to_write};
        req.read = 0;
        req.strb = 4'hF;
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



initial begin
    uvm_config_db#(virtual i2c_if)::set(null, "uvm_test_top.env.i2c_mon", "vif", i2c_vif);
    uvm_config_db#(virtual axil_if)::set(null, "uvm_test_top.env.axil_drv", "vif", axil_vif);
    uvm_config_db#(virtual axil_if)::set(null, "uvm_test_top.env.axil_mon", "vif", axil_vif);

    run_test("i2c_master_test");
end


    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule