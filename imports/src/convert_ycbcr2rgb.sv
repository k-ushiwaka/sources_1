module convert_ycbcr2rgb(
    input           i_clk,
    input           i_rst,
    input   [9:0]   i_data_y,
    input   [9:0]   i_data_cb,
    input   [9:0]   i_data_cr,
    input           i_sync_h,
    input           i_sync_v,
    output  [7:0]   o_data_r,
    output  [7:0]   o_data_g,
    output  [7:0]   o_data_b,
    output          o_sync_h,
    output          o_sync_v    
);
//// SYNCDELAY & CONVERT YCbCr420 => RGB888
    logic   [7:0]   w_r;
    logic   [7:0]   w_g;
    logic   [7:0]   w_b;
    logic           w_sync_h;
    logic           w_sync_v;
//--- CONVERT YCbCr420 => RGB888 ---//
    convert_10to8 U_convert_10to8(
        .ap_clk         (i_clk),
        .ap_rst         (i_rst),
        .i_data_y_V     (i_data_y),
        .i_data_cb_V    (i_data_cb),
        .i_data_cr_V    (i_data_cr),
        .o_data_r_V     (w_r),
        .o_data_g_V     (w_g),
        .o_data_b_V     (w_b)
    );
//--- Sync Delay ---///
    delay #(
        .DATA_WIDTH(1),
        .DELAY_TIME(34)
    ) 
    U_dealy_h(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_sync_h),
        .o_data(w_sync_h)
    );
    delay #(
        .DATA_WIDTH(1),
        .DELAY_TIME(34)
    ) 
    U_dealy_v(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_sync_v),
        .o_data(w_sync_v)
    );

//--- ASSIGN ----//
    assign o_data_r = w_r;
    assign o_data_g = w_g;
    assign o_data_b = w_b;
    assign o_sync_h = w_sync_h;
    assign o_sync_v = w_sync_v;
endmodule


// convert_ycbcr2rgb U_convert_ycbcr2rgb(
//     .i_clk          (),
//     .i_rst          (),
//     .i_data_y       (),
//     .i_data_cb      (),
//     .i_data_cr      (),
//     .i_sync_h       (),
//     .i_sync_v       (),
//     .o_data_r       (),
//     .o_data_g       (),
//     .o_data_b       (),
//     .o_sync_h       (),
//     .o_sync_v       ()    
// );