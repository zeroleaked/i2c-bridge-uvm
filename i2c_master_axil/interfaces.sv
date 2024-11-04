`ifndef TIMESCALE_SV
`define TIMESCALE_SV
`timescale 1ns/1ps
`endif
interface i2c_if(input logic clk, rst);
    logic scl_i, scl_o, scl_t;
    logic sda_i, sda_o, sda_t;

    // Clocking block for driver
    clocking driver_cb @(posedge clk);
        output scl_i, sda_i;
        input  scl_o, scl_t, sda_o, sda_t;
    endclocking

    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        input scl_i, scl_o, scl_t, sda_i, sda_o, sda_t;
    endclocking

    modport driver(clocking driver_cb);
    modport monitor(clocking monitor_cb);
endinterface

interface axil_if(input logic clk, rst);
    logic [3:0]  awaddr;
    logic [2:0]  awprot;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    logic [3:0]  araddr;
    logic [2:0]  arprot;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    // Clocking block for driver
    clocking driver_cb @(posedge clk);
        output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready;
        output araddr, arprot, arvalid, rready;
        input  awready, wready, bresp, bvalid;
        input  arready, rdata, rresp, rvalid;
    endclocking

    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        input awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready;
        input araddr, arprot, arvalid, rready;
        input awready, wready, bresp, bvalid;
        input arready, rdata, rresp, rvalid;
    endclocking

    modport driver(clocking driver_cb);
    modport monitor(clocking monitor_cb);
endinterface
