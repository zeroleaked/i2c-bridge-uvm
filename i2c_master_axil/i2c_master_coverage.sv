class i2c_master_coverage extends uvm_subscriber #(axil_seq_item);
    `uvm_component_utils(i2c_master_coverage)
    
    covergroup axil_cg;
        addr_cp: coverpoint trans.addr {
            bins data = {i2c_reg_map::DATA_REG};
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