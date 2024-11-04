`ifndef DRIVER
`define DRIVER

`include "sequence.svh"

class read_driver extends uvm_driver#(read_sequence_item);

    // register object to UVM Factory
    `uvm_component_utils(read_driver);

    // constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // set driver-DUT interface
    virtual top_interface.driver top_vinterface;
    function void build_phase (uvm_phase phase);
        if (!uvm_config_db #(virtual top_interface)::get(this, "", "top_vinterface", top_vinterface)) begin
            `uvm_error("", "uvm_config_db::driver.svh get failed on BUILD_PHASE")
        end
    endfunction

    /** the read sequence is constructed of 3 procedures:
            - start cycle
            - read operation
            - end cycle
        
        several parameters that will be used:
        - Tp: WB_PERIOD=10
        - Tsetup: 3
        - Thold: 1
    **/

    /**
        -- wait init clock (1 clock)
        START CYCLE:
            CYC_I <- #(Tp - Tsetup) 1'b1
            CAB_I <- #(Tp - Tsetup) 1'b0 (deactivate burst transfer)
            WE_I  <- #(Tp - Tsetup) 1'b0
        -- wait init clock (arbitrary)
        READ OPERATION:
            ADR_I <- #(Tp - Tsetup) address
            SEL_I <- #(Tp - Tsetup) 0
            TAG_I <- #(Tp - Tsetup) 0, cti and bte are not used due to inactive burst
            STB_I <- #(Tp - Tsetup) 1'b1
        -- wait until ACK_O, RTY_O, or ERR_O give response(s)
        -- at this stage, the data response data is valid OR error has been asserted
            ADR_I <- #(Thold) 32{1'bx}
            SEL_I <- #(Thold) x
            TAG_I <- #(Thold) x
            STB_I <- #(Thold) 0
        END CYCLE:
            CYC_I <- #(Thold) 1'b0
            CAB_I <- #(Thold) 1'b0
    **/

    integer wait_retry;
    // define driver behavior
    task run_phase (uvm_phase phase);
        
        // reset routine
        top_vinterface.rst = 1;
        @top_vinterface.clk;
        top_vinterface.rst = 0; 
        @top_vinterface.clk;

        // fetch test sequences, pass it to the DUT as signals
        forever begin
            @(posedge top_vinterface.clk);
            seq_item_port.get_next_item(req);
            //****************** DRIVE THE INTERFACE ********************/
            //----------- WRITE ROUTINE -----------//
            @top_vinterface.clk;

                // start cycle
                top_vinterface.wbs_cyc_i = #(7) 1'b1;
                top_vinterface.wbs_we_i = #(7) 1'b1;

            @top_vinterface.clk;

                // write cycle
                wait_retry = 20;
                top_vinterface.wbs_adr_i = #(7) req.addr;
                top_vinterface.wbs_dat_i = #(7) req.data;
                top_vinterface.wbs_stb_i = #(7) 1'b1;
                @top_vinterface.clk;
                while ( (wait_retry > 0) && ~(top_vinterface.wbs_ack_o) )
                begin
                    @(posedge top_vinterface.clk) ;
                    wait_retry = wait_retry - 1 ;
                end
                top_vinterface.wbs_adr_i = #(1) 3'hx;
                top_vinterface.wbs_dat_i = #(1) 8'hxx;
                top_vinterface.wbs_stb_i = #(1) 1'b0;

                // check response validity
                if (wait_retry == 0) begin
                    `uvm_info("DRIVER", "Handshake no response.", UVM_MEDIUM) 
                end
                else begin
                    `uvm_info("DRIVER", "Handshake responded!", UVM_MEDIUM) 
                end

                // end cycle
                top_vinterface.wbs_cyc_i = #(1) 1'b0;
                top_vinterface.wbs_we_i = #(1) 1'b0;

            @top_vinterface.clk;
            // ****************************************************************
            seq_item_port.item_done();
        end
    endtask

endclass

`endif