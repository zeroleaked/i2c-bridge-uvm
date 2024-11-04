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