`ifndef I2C_INTERFACE
`define I2C_INTERFACE

interface i2c_interface(input logic clk);
logic        i2c_scl_i;
logic        i2c_scl_o;
logic        i2c_scl_t;
logic        i2c_sda_i;
logic        i2c_sda_o;
logic        i2c_sda_t;

// Responder interface
logic        resp_sda_o;


/**
 * Modports
 */
// master agent driver
modport driver(
	input			clk,
    input           i2c_scl_i,
    input           i2c_scl_o,
    input           i2c_scl_t,
    input           i2c_sda_i,
    input           i2c_sda_o,
    input           i2c_sda_t
);
// slave agent driver
modport driver_slave(
	input			clk,
    output          i2c_scl_i,
    input           i2c_scl_o,
    input           i2c_scl_t,
    output          i2c_sda_i,
    input           i2c_sda_o,
    input           i2c_sda_t,

    output          resp_sda_o
);
// monitor
modport monitor(
	input			clk,
    input           i2c_scl_i,
    input           i2c_scl_o,
    input           i2c_scl_t,
    input           i2c_sda_i,
    input           i2c_sda_o,
    input           i2c_sda_t
);
endinterface

`endif