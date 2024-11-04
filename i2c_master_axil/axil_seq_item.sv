class axil_seq_item extends uvm_sequence_item;
    rand bit [3:0]  addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;
    rand bit        read;
    
    `uvm_object_utils_begin(axil_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(read, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axil_seq_item");
        super.new(name);
    endfunction

    constraint addr_c {
        addr inside {[0:3]};
    }
endclass