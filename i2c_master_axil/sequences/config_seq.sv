class config_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(config_seq)

    function new(string name = "config_seq");
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
    endtask
endclass