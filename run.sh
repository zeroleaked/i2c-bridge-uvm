#!/bin/sh

BUILD_DIR="./build"
mkdir -p $BUILD_DIR

rm -rf $BUILD_DIR/xsim.dir
rm -f $BUILD_DIR/*.log $BUILD_DIR/*.jou $BUILD_DIR/*.pb $BUILD_DIR/*.wdb

echo "\`timescale 1ns/1ps" > $BUILD_DIR/uvm_precompile.sv

cd $BUILD_DIR

xvlog -sv -L uvm ../i2c_master_axil/uvm_precompile.sv
xvlog -sv -L uvm ../i2c_master_axil/dut_params_pkg.sv
xvlog -sv -L uvm ../i2c_master_axil/timescale.sv

xvlog -sv -L uvm ../i2c_master_axil/axil_env_pkg.sv
xvlog -sv -L uvm ../i2c_master_axil/i2c_master_axil_pkg.sv
xvlog -sv -L uvm ../i2c_master_axil/sequences/axil_seq_list.sv
xvlog -sv -L uvm ../i2c_master_axil/axil_test_pkg.sv
xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_axil.v ../rtl/axis_fifo.v

xvlog -sv -L uvm ../i2c_master_axil/tb_top.sv

xelab -L uvm -timescale 1ns/1ps -debug typical tb_top -s tb_top

xsim -R tb_top -testplusarg "UVM_VERBOSITY=UVM_LOW"

cd ..
