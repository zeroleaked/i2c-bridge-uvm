class i2c_reg_map;
    typedef enum bit [3:0] {
        STATUS_REG   = 4'h0,
        CMD_REG      = 4'h4,
        DATA_REG     = 4'h8,
        PRESCALE_REG = 4'hc
    } reg_addr_t;

    typedef struct packed {
        bit [31:1] reserved;
        bit        enable;
    } ctrl_reg_t;

    typedef struct packed {
        bit [31:4] reserved;
        bit        cmd_full;
        bit        cmd_empty;
        bit        busy;
        bit        error;
    } status_reg_t;
endclass