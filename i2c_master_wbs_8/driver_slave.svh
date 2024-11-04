`ifndef DRIVER_SLAVE
`define DRIVER_SLAVE

class read_driver_slave extends uvm_driver#(read_sequence_item);

    /*************************
    * Component Initialization
    **************************/
    // register object to UVM Factory
    `uvm_component_utils(read_driver_slave);

    // constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // set driver-DUT interface
    virtual top_interface.driver_slave top_vinterface;
    function void build_phase (uvm_phase phase);
        if (!uvm_config_db #(virtual top_interface)::get(this, "", "top_vinterface", top_vinterface)) begin
            `uvm_error("", "uvm_config_db::driver_slave.svh get failed on BUILD_PHASE")
        end
    endfunction

    /*************************
    * Internal Properties
    **************************/
    // State Enumeration
    typedef enum {  RESP_IDLE, 
                    RESP_REGADDR_WAIT, 
                    RESP_RW_WAIT, 
                    RESP_READ, 
                    RESP_WRITE
                    } resp_state_type;  // Slave Driver FSM
    typedef enum {  PACKET_ACK,
                    PACKET_NACK
                    } packet_type;      // Received Packet ACK type
    typedef enum {  CMD_NONE,
                    CMD_START,
                    CMD_STOP
                    } command_type;     // Start/Stop Bit type

    // Variables
    resp_state_type resp_state = RESP_IDLE;
    command_type command;
    packet_type packet;
    bit start, stop, ack;
    bit [7:0] data;
    bit flip;
    integer i;

    // Methods
    function get_next_state;
        // A function to decode the next responder (slave) state based on the current state and the input
        if ((this.command == CMD_STOP)) begin
            this.resp_state = RESP_IDLE;
        end

        else begin // packet acknowledged
            // idle state
            if (this.resp_state == RESP_IDLE) begin
                if (this.command == CMD_START) begin
                    if (data == (8'h6<<1)) begin
                        this.resp_state = RESP_REGADDR_WAIT;
                         `uvm_info("DRIVER_SLAVE::STATE_FSM", "Device is being accessed: dev_addr 0x6", UVM_MEDIUM)
                    end
                end
            end

            // state after device address input, waiting for register address
            else if (this.resp_state == RESP_REGADDR_WAIT) begin
                if (this.command == CMD_NONE) begin
                    this.resp_state = RESP_RW_WAIT;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Internal address is being accessed: reg_addr 0x%2h", data), UVM_MEDIUM)
                end
            end

            // state after register address input, waiting for next cmd (R/W)
            else if (this.resp_state == RESP_RW_WAIT) begin
                if (this.command == CMD_START) begin
                    this.resp_state = RESP_READ;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", "Device is being read: dev_addr 0x6", UVM_MEDIUM)
                end
                else if (this.command == CMD_NONE) begin
                    this.resp_state = RESP_WRITE;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Writing: data 0x%2h", data), UVM_MEDIUM)
                end
            end

            // read state latch
            else if (this.resp_state == RESP_READ) begin
                `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Reading: data 0x%2h", data), UVM_MEDIUM)
            end

            // write state latch
            else if (this.resp_state == RESP_WRITE) begin
                `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Writing: data 0x%2h", data), UVM_MEDIUM)
            end
        end
    endfunction

    // pin-level processing tasks
    task read_packet;
        begin
            this.start = 0;                             // start bit variable
            this.stop = 0;                              // stop bit variable
            this.ack = 0;                               // ack/nack variable
            this.data = 0;                              // data packet (8 bits)
            this.packet = PACKET_ACK;                            // ack/nack variable (redundant, remove later)
            this.flip = (resp_state == RESP_READ);      // master/slave operation based on the state
            this.top_vinterface.resp_sda_o = 1 ^ flip;

            fork
                // THREAD 1 :: check for start bit
                begin
                    forever begin
                        @(negedge this.top_vinterface.i2c_sda_i);
                        if (this.top_vinterface.i2c_scl_i == 1'b1) begin
                            this.start = 1;
                        end
                    end
                end

                begin
                    // THREAD 2 :: check for stop bit
                    forever begin
                        @(posedge this.top_vinterface.i2c_sda_i);
                        if (this.top_vinterface.i2c_scl_i == 1'b1) begin
                            this.stop = 1;
                            break;
                        end
                    end
                end

                // THREAD 3 :: retrieve data
                begin
                    for(i=0; i<8+(this.start && resp_state!=RESP_IDLE); i=i+1) begin
                        @(posedge this.top_vinterface.i2c_scl_i);
                        this.data = (this.data << 1) | this.top_vinterface.i2c_sda_i;
                    end
                    // set ack bit
                    @(negedge this.top_vinterface.i2c_scl_i);
                    #5;
                    top_vinterface.resp_sda_o = 0 ^ flip;
                    // read ack bit
                    @(posedge this.top_vinterface.i2c_scl_i);
                    #5;
                    this.ack = ~this.top_vinterface.i2c_sda_i;
                    // wait until transfer finish
                    @(negedge this.top_vinterface.i2c_scl_i);
                    // making sure no race condition is happening
                    #5;
                end
            join_any
            disable fork;
        end
    endtask


    // define driver behavior
    task run_phase (uvm_phase phase);

        // do reset
        top_vinterface.rst = 1;
        @top_vinterface.clk;
        top_vinterface.rst = 0; 
        @top_vinterface.clk;

        forever begin
            // read packet
            read_packet;

            // encode command
            if (stop) command = CMD_STOP;
            else if (start) command = CMD_START;
            else command = CMD_NONE;
            // encode packet
            if (ack) packet = PACKET_ACK;
            else packet = PACKET_NACK;

            // compute next state
            get_next_state;
             `uvm_info("DRIVER_SLAVE", $sformatf("Input have been processed: state:0x%1h, cmd:0x%2h, data:0x%1h, ack:0x%1h", resp_state, command, data, packet), UVM_MEDIUM)

        end

    endtask

endclass

`endif