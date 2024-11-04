#!/bin/sh

rm -rf xsim.dir
rm -f *.log *.jou *.pb *.wdb

echo "\`timescale 1ns/1ps" > uvm_precompile.sv

xvlog -sv -L uvm uvm_precompile.sv
xvlog -sv -L uvm dut_params_pkg.sv
xvlog -sv -L uvm timescale.sv
xvlog -sv -L uvm i2c_master_axil_pkg.sv
xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_axil.v ../rtl/axis_fifo.v

xvlog -sv -L uvm tb_top.sv

xelab -L uvm -timescale 1ns/1ps -debug typical tb_top -s tb_top

xsim -R tb_top -testplusarg "UVM_VERBOSITY=UVM_LOW"
