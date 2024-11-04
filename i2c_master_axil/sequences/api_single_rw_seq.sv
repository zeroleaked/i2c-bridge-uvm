`ifndef API_SINGLE_RW_SEQ
`define API_SINGLE_RW_SEQ

class api_single_rw_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(api_single_rw_seq)

	axil_seq_item trans;
	uvm_sequencer_base sequencer;

    function new(string name = "api_single_rw_seq");
        super.new(name);
    endfunction

    task body();
        req = axil_seq_item::type_id::create("req");
        start_item(req);
		req.randomize();
		if (!trans.read)
	        req.data = trans.data;
        req.read = trans.read;
        req.addr = trans.addr;
        req.strb = trans.strb;
        finish_item(req);
		get_response(rsp);
    endtask

	task configure(input uvm_sequencer_base seqr_in);
        trans = axil_seq_item::type_id::create("req");
		this.sequencer = seqr_in;
	endtask

	task start_write(input bit [3:0] reg_addr, input bit [31:0] data);
		trans.read = 0;
		trans.addr = reg_addr;
		trans.data = data;
		trans.strb = 4'b0011;
		start(sequencer);
	endtask

	task write_register_command(input bit [6:0] addr);
		bit cmd_stop = 1;
		bit cmd_wr_m = 0;
		bit cmd_write = 1;
		bit cmd_start = 1;
		bit [12:0] data = {cmd_stop, cmd_wr_m, cmd_write, !cmd_write,
			cmd_start, 1'b0, addr};
		start_write(i2c_reg_map::CMD_REG, {19'h0, data});
	endtask

	task write_register_data(input bit [7:0] data);
		bit data_valid = 1;
		bit data_last = 1;
		bit [9:0] to_write = {data_last, data_valid, data};
		start_write(i2c_reg_map::DATA_REG, {22'h0, to_write});
	endtask

	task start_read(input bit [3:0] reg_addr);
		trans.read = 1;
		trans.addr = reg_addr;
		trans.strb = 4'b0011;
		start(sequencer);
	endtask

	task read_register_status();
		start_read(i2c_reg_map::STATUS_REG);
	endtask

endclass

`endif