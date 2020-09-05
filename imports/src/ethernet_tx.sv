module ethernet_tx (
	input       i_clk_125,
	input       i_clk_125_90,
    input       i_rst,
	(* mark_debug = "true" *)input [7:0] i_raw_data,
	(* mark_debug = "true" *)input       i_raw_data_valid,
	input       i_phy_ready,
	input [14:0]i_data_byte,
    input [7:0] i_row_number,
    input       i_sof,
    input       i_param_flag,
	// output
	output       o_eth_busy,
	output [7:0] o_fully_framed,
    output       o_fully_framed_valid
);
//// ADD_BYTE_DATA OUYPUT
    (* mark_debug = "true" *)logic [7:0] w_with_header_data;
    (* mark_debug = "true" *)logic       w_with_header_valid;
    logic       w_busy;
//// ADD CRC OUTPUT
    (* mark_debug = "true" *)logic [7:0] w_with_crc;
    (* mark_debug = "true" *)logic       w_with_crc_valid;
    logic       w_with_crc_enable;
//// ADD_PREAMBLE OUTPUT
    (* mark_debug = "true" *)logic [7:0] w_fully_framed;
    (* mark_debug = "true" *)logic       w_fully_framed_valid;
    logic       w_fully_framed_enable;
    logic       w_fully_framed_err;
//// ADD OUTPUT
    logic [3:0] w_eth_txd;
	logic       w_eth_txck;
	logic       w_eth_txctl;
	
    logic [7:0] w_raw_data_delay;
	
	delay #(
        .DATA_WIDTH(8),
        .DELAY_TIME(43)
    ) 
    U_dealy_ethdata(
        .i_clk(i_clk_125),
        .i_rst(i_rst),
        .i_data(i_raw_data),
        .o_data(w_raw_data_delay)
    );
//--- ADD Eth.IP.UDP Header---//
    byte_data U_byte_data(
        .i_clk        (i_clk_125),
        .i_rst        (i_rst),
        .i_start      (i_raw_data_valid),
        .i_data_byte  (i_data_byte),
        .i_row_number (i_row_number),
        .i_segment_num(16'd0),
        .i_index_clone({3'b000,i_param_flag,i_sof,3'b000}),
        .i_vramdata   (w_raw_data_delay),
        .o_busy       (w_busy),
        .o_data       (w_with_header_data),
        .o_data_valid (w_with_header_valid)
	);
//--- ADD CRC ---//
    add_crc32 U_add_crc32(
    	.i_clk          (i_clk_125),
    	.i_data         (w_with_header_data),
    	.i_data_valid   (w_with_header_valid),
    	.o_data         (w_with_crc),
    	.o_data_valid   (w_with_crc_valid)
	);
//--- ADD PREAMBLE ---//
    add_preamble U_add_preamble(
        .i_clk          (i_clk_125),
        .i_rst          (i_rst),
        .i_data         (w_with_crc),
        .i_data_valid   (w_with_crc_valid),
        .o_data         (w_fully_framed),
        .o_data_valid   (w_fully_framed_valid)
	);
// //--- RGMII ---//
//     rgmii_tx U_rgmii_tx(
//         .i_clk          (i_clk_125),
//         .i_clk90        (i_clk_125_90),
//         .i_phy_ready    (i_phy_ready),
//         .i_data         (w_fully_framed),
//         .i_data_valid   (w_fully_framed_valid),
//         .i_data_error   (1'b0),
//         .o_eth_txck     (w_eth_txck),
//         .o_eth_txctl    (w_eth_txctl),
//         .o_eth_txd      (w_eth_txd)
// 	);

//>> ASSIGN OUTPUT >>//
    assign o_eth_busy          = w_busy;
    assign o_fully_framed      = w_fully_framed;
    assign o_fully_framed_valid= w_fully_framed_valid;
    // assign o_eth_txd    = w_eth_txd;
    // assign o_eth_txck   = w_eth_txck;
    // assign o_eth_txctl  = w_eth_txctl;    
endmodule