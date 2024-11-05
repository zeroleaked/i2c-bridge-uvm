`ifndef AXIL_SEQ_DEFINES
`define AXIL_SEQ_DEFINES

typedef enum bit [4:0] {
	CMD_STOP	= 5'h10,
	CMD_WR_M	= 5'h8,
	CMD_WRITE	= 5'h4,
	CMD_READ	= 5'h2,
	CMD_START	= 5'h1
} reg_cmd_flag_t;

typedef enum bit [1:0] {
	DATA_LAST		= 2'h2,
	DATA_VALID		= 2'h1,
	DATA_DEFAULT	= 2'h0
} reg_data_flag_t;

`endif


