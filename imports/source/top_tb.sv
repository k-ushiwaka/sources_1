module top_tb
  #(
    parameter   EXAMPLE_SIM_GTRESET_SPEEDUP    = "TRUE",     // Simulation setting for GT SecureIP model
    parameter   USE_BUFG                       =   0   ,      // set to 1 if you want to use BUFG for cpll railing logic
    parameter   THRESHOLDa                     = 3600,//42601,
    parameter   THRESHOLDb                     = 22500,//18889,
    parameter   THRESHOLDc                     = 57600,
    parameter   THRESHOLDd                     = 80000
  )
  (
    input               i_sys_clk_p,
    input               i_sys_clk_n,
    input               i_clk_148,
    input               i_rst,
    input [9:0]         i_y_data,    
    input [9:0]         i_cbcr_data,
    input               i_rx_sav,
    input               i_rx_eav,
    input               i_rx_trs,   
    output  [11:0]      o_sync_v_count,
    output              o_valid,
    output  [23:0]      o_data,
    output              o_hor,
    output              o_var
  );
/// Debug Logic///
    logic   [3:0][10:0] r_rank_counter;
//// Clocking & Reset ////
    wire w_clk_100;         //100MHz
    wire gt0_rxusrclk_out;  //148.5MHz
    wire w_clk_200;         //200MHz
    wire w_clk_125;         //125MHz
    wire w_clk_125_90;      //125MHz delta90
    wire w_clk_138;
    wire w_clk_locked;
    wire w_clk_locked_pclk;


//// ANALYSY SDI OUTPUT
    logic           w_sync_h;
    logic           w_sync_v;
    logic   [9:0]   w_y ;
    logic   [9:0]   w_cb;
    logic   [9:0]   w_cr;
    logic   [11:0]  w_sync_h_count;
    logic   [11:0]  w_sync_v_count;
//// SYNCDELAY & CONVERT YCbCr420 => RGB888
    logic   [7:0]   w_r;
    logic   [7:0]   w_g;
    logic   [7:0]   w_b;
    logic           w_sync_h_delay;
    logic           w_sync_v_delay;
//// TPG 
    logic           w_tpg_hsync;
    logic           w_tpg_vsync;
    logic   [7:0]   w_tpg_r;
    logic   [7:0]   w_tpg_g;
    logic   [7:0]   w_tpg_b;
//// Onscreen
    logic           w_onscreen_hs;
    logic           w_onscreen_vs;
    logic           w_onscreen_valid;
    logic   [7:0]  w_onscreen_data_r;
    logic   [7:0]  w_onscreen_data_g;
    logic   [7:0]  w_onscreen_data_b;
//// Definition Paramater Logic
    logic   [11:0]  w_gaze_x_tx;
    logic   [11:0]  w_gaze_y_tx;
    logic   [23:0]  w_tres_1_tx;
    logic   [23:0]  w_tres_2_tx;
    logic   [23:0]  w_tres_3_tx;
//// LINE BUFFER OUTPUT
    logic                   w_buff_data_valid;
    logic [11-1 : 0]        w_buff_h_count;
    logic [11-1 : 0]        w_buff_v_count;                          
    logic [12-1 : 0][7:0]   w_buff_r;
    logic [12-1 : 0][7:0]   w_buff_g;
    logic [12-1 : 0][7:0]   w_buff_b;
//// Mean & Distance Calclation OUTPUT
    logic [288-1 : 0]       w_rgb;
    logic                   w_mean_data_valid;
    logic                   w_mean_out_valid;
    logic [1:0]             w_mean_rank;
    logic [1:0]             w_rank;
//// Packet wait OUTPUT
    logic [7:0]             w_packet_data;
    logic                   w_packet_valid;
    logic [14:0]            w_packet_byte;
    logic [7:0]             w_row_number;
//// Clk change 200 -> 125 OUTPUT
    logic                   w_125_data_valid;
    logic [14:0]            w_125_data_byte; 
    logic [7:0]             w_125_row_number;
    logic [7:0]             w_125_eth_data; 
    logic                   w_sof; 
    logic                   w_parama_sent_flag;
    logic                   w_packet_last;
//// Eth TX Control OUTPUT
    logic                   w_eth_cont_busy;
    logic                   w_cont_data_valid;
    logic   [14:0]          w_cont_data_byte;
    logic   [7:0]           w_cont_row_number;
    logic   [7:0]           w_cont_eth_data;
    logic                   w_cont_sof;
//// ETH TX OUTPUT
    logic [7:0]             w_fully_framed;
    logic                   w_fully_framed_valid;
    
//// ETH RX OUTPUT
    logic [7:0]             w_rx_data;
    logic                   w_rx_data_enable;
    logic                   w_rx_data_error;
    logic [7:0]             w_rx_packet_data;
    logic                   w_rx_packet_enable;
    logic [7:0]             w_packet_param;
    logic                   w_param_enable;
    logic [15:0]            w_rx_packet_length;
    logic                   w_rx_sof;
    logic                   w_rx_packet_data_enable;
    logic [7:0]             w_rx_param;
    logic                   w_rx_param_enable;
    logic                   w_param_flag;
    logic                   w_eth_busy;
//// Definition Patameter RXside OUTPUT
    logic   [11:0]          w_gaze_x_rx;
    logic   [11:0]          w_gaze_y_rx;
    logic   [23:0]          w_tres_1_rx;
    logic   [23:0]          w_tres_2_rx;
    logic   [23:0]          w_tres_3_rx;
    logic                   w_param_ready;
//// Clk change 125 -> 200 OUTPUT
    logic                   w_200_data_valid;
    logic [7:0]             w_200_data_data;
    logic                   w_200_sof;
//// Decoder New OUTPUT
    logic [23:0]            w_packet2rgb_data;
    logic                   w_packet2rgb_valid;
    logic [11:0]            w_decode2_enable;
    logic [23:0]            w_decode2_rgb;
    logic                   w_decode2_sof;
//// Nextline Calculation IN/OUTPUT
    logic [1:0]             w_nextline_rank;
    logic                   w_nextline_valid;
    logic                   w_nextline_last;
    logic [10:0]            w_nextline_number;
    logic                   w_rank_request;
//// Decoder OUTPUT
    logic [11:0]            w_decode_enable;
    logic [23:0]            w_decode_rgb;
    logic                   w_decode_sof;
//// LINE BUFFER RXSIDE IN/OUTPUT
    logic [23:0]            w_rxbuff_rgb;
    logic                   w_sync_start_enable;
    logic                   w_sync_ok;
    logic                   w_rxbuff_read_enable;
//// SYNC GENERATE OUTPUT
    logic                   w_hsync;
    logic                   w_vsync;
    (* mark_debug = "true" *)logic [11:0]            w_hsync_count;
    (* mark_debug = "true" *)logic [11:0]            w_vsync_count;
    logic                   w_sync_valid;
    logic                   w_sync_valid_delay;
    logic                   w_data_catch_valid;
//// Video In -> AXI4-Stream OUTPUT
    (* mark_debug = "true" *)logic [23:0]            w_m_axis_video_tdata;                   
    (* mark_debug = "true" *)logic                   w_m_axis_video_tvalid;
    (* mark_debug = "true" *)logic                   w_m_axis_video_tready;
    (* mark_debug = "true" *)logic                   w_m_axis_video_tuser;
    (* mark_debug = "true" *)logic                   w_m_axis_video_tlast;
        //--- IP Clocking ---//
    bd_top_clk_wiz_0_0 U_generate_clk_wiz_0
    (
        .clk_100    (w_clk_100),    // output clk_out1
        .clk_200    (w_clk_200),    // output clk_out2
        .clk_125    (w_clk_125),
        .clk_125_90 (w_clk_125_90),  
        .locked     (w_clk_locked), // output locked
        .clk_in1_p  (i_sys_clk_p),  // input clk_in1_p
        .clk_in1_n  (i_sys_clk_n)
    );
    clk_wiz_0 U_generate_clk_wiz_1
    (
        .clk_138    (w_clk_138),
        .locked     (w_clk_locked_pclk), 
        .clk_in1    (w_clk_200)
    );
    wire w_phy_ready;
    logic [24:0]                                    r_reset_counter;
    always_ff@(posedge w_clk_125)begin
        if(i_rst)                                 r_reset_counter <= 25'd0;
        else if(r_reset_counter[24]==1'b0)        r_reset_counter <= r_reset_counter + 1'b1;
        else                                      r_reset_counter <= r_reset_counter;  
    end
    assign w_phy_ready = r_reset_counter[24];
    
    

//--- IP GTX ---//

//--- ANALYSYS SDI ---//
    analysys_sdi#(
        .COUNT_ENABLE("TRUE"),
        .COUNT_WIDE(12) 
    )
    U_analysys_sdi
    (
        .i_clk          (i_clk_148),
        .i_rst          (i_rst),
        .i_y            (i_y_data),
        .i_cbcr         (i_cbcr_data),
        .i_sav          (i_rx_sav),
        .i_eav          (i_rx_eav),
        .i_trs          (i_rx_trs),
        .o_sync_h       (w_sync_h),
        .o_sync_v       (w_sync_v),
        .o_y            (w_y),
        .o_cb           (w_cb),
        .o_cr           (w_cr),
        .o_sync_h_count (w_sync_h_count),
        .o_sync_v_count (w_sync_v_count)
    );
//--- CONVERT YCbCr420 => RGB888 ---//
    convert_ycbcr2rgb U_convert_ycbcr2rgb(
        .i_clk          (i_clk_148),
        .i_rst          (i_rst),
        .i_data_y       (w_y),
        .i_data_cb      (w_cb),
        .i_data_cr      (w_cr),
        .i_sync_h       (w_sync_h),
        .i_sync_v       (w_sync_v),
        .o_data_r       (w_r),
        .o_data_g       (w_g),
        .o_data_b       (w_b),
        .o_sync_h       (w_sync_h_delay),
        .o_sync_v       (w_sync_v_delay)    
    );

//--- TPG (Debug) ---//
    top_colorbar#(
        .through("TRUE")
    )
    U_top_colorbar
    (
        .i_pclk     (i_clk_148),
        .i_rst      (i_rst),
        .i_sync_h   (w_sync_h_delay),
        .i_sync_v   (w_sync_v_delay),
        .i_r        (w_r),
        .i_g        (w_g),
        .i_b        (w_b),
        .i_sw       (1'b0),
        .o_sync_h   (w_tpg_hsync),
        .o_sync_v   (w_tpg_vsync),
        .o_r        (w_tpg_r),
        .o_g        (w_tpg_g),
        .o_b        (w_tpg_b)
    );

     onscreen U_onscreen(
         .i_pclk             (i_clk_148),
         .i_rst              (i_rst),
         .i_on_sw            (1'b1),
         .i_treshuld1        (24'd57600),
         .i_treshuld2        (24'd22500),
         .i_treshuld3        (24'd3600),
         .i_gaze_position_x  (11'd960),
         .i_gaze_position_y  (11'd0),
         .i_hs               (w_sync_h_delay),
         .i_vs               (w_sync_v_delay),
         .i_valid            (w_sync_h_delay && w_sync_v_delay),
         .i_data             ({w_tpg_r,w_tpg_g,w_tpg_b}),
         .o_hs               (w_onscreen_hs),
         .o_vs               (w_onscreen_vs),
         .o_valid            (w_onscreen_valid),
         .o_data_r           (w_onscreen_data_r),
         .o_data_g           (w_onscreen_data_g),
         .o_data_b           (w_onscreen_data_b)
        
     );
//--- Definition Paramater ---//
    definition_param_txside U_definition_param_txside(
        .i_clk              (i_clk_148),
        .i_rst              (i_rst),
        .i_gaze_x           (11'd960),
        .i_gaze_y           (11'd0),
        .i_tres_1           (24'd57600),
        .i_tres_2           (24'd22500),
        .i_tres_3           (24'd3600),
        .i_vsync            (w_onscreen_vs),
        .o_gaze_x           (w_gaze_x_tx),
        .o_gaze_y           (w_gaze_y_tx),
        .o_tres_1           (w_tres_1_tx),
        .o_tres_2           (w_tres_2_tx),
        .o_tres_3           (w_tres_3_tx)
    );

//--- Line Buffer 148.5 -> 200 ---//
    line_buffer#(
        .M_DEPTH  (11),
        .M_WIDTH  (32),
        .IMG_W    (1920),
        .FULL_NUM (2048),
        .LINE_NUM (12)
    )
    U_line_buffer
    (
        //system signal
        .i_write_clk    (i_clk_148),
        .i_read_clk     (w_clk_200),
        .i_rst          (i_rst),
        //input
        .i_sync_h       (w_onscreen_hs),
        .i_sync_v       (w_onscreen_vs),
        .i_r            (w_onscreen_data_r),
        .i_g            (w_onscreen_data_g),
        .i_b            (w_onscreen_data_b),
        //output
        .o_data_valid   (w_buff_data_valid),
        .o_h_count      (w_buff_h_count),
        .o_v_count      (w_buff_v_count),                          
        .o_r            (w_buff_r),
        .o_g            (w_buff_g),
        .o_b            (w_buff_b)
    );
//--- Mean Calclation ---//
    mean_calc#(
        .M_DEPTH (11),
        .M_WIDTH (32),
        .IMG_W   (1920),
        .FULL_NUM(2048),
        .LINE_NUM(12)
    )
    U_mean_calc_r
    (
        //system signal
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        //input
        .i_data_valid   (w_buff_data_valid),
        // .i_h_count      (w_buff_h_count   ),
        // .i_v_count      (w_buff_v_count   ),
        .i_data         (w_buff_r         ),
        .i_rank         (w_rank),           //0000:default  0001:1/1  0010:1/4  0100:1/9  1000:1/16 

        //output
        .o_data_valid   (w_mean_data_valid),
        .o_rank         (w_mean_rank),
        .o_sync_h       (w_mean_out_valid),
        .o_data         (w_rgb[95:0])
    );
    mean_calc#(
        .M_DEPTH (11),
        .M_WIDTH (32),
        .IMG_W   (1920),
        .FULL_NUM(2048),
        .LINE_NUM(12)
    )
    U_mean_calc_g
    (
        //system signal
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        //input
        .i_data_valid   (w_buff_data_valid),
        // .i_h_count      (w_buff_h_count   ),
        // .i_v_count      (w_buff_v_count   ),
        .i_data         (w_buff_g         ),
        .i_rank         (w_rank),           //0000:default  0001:1/1  0010:1/4  0100:1/9  1000:1/16 

        //output
        .o_data_valid   (),
        .o_sync_h       (),
        .o_data         (w_rgb[191:96])
    );
    mean_calc#(
        .M_DEPTH (11),
        .M_WIDTH (32),
        .IMG_W   (1920),
        .FULL_NUM(2048),
        .LINE_NUM(12)
    )
    U_mean_calc_b
    (
        //system signal
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        //input
        .i_data_valid   (w_buff_data_valid),
        // .i_h_count      (w_buff_h_count   ),
        // .i_v_count      (w_buff_v_count   ),
        .i_data         (w_buff_b         ),
        .i_rank         (w_rank),           //0000:default  0001:1/1  0010:1/4  0100:1/9  1000:1/16 

        //output
        .o_data_valid   (),
        .o_sync_h       (),
        .o_data         (w_rgb[287:192])
    );
//--- Calculation distance ftrom eye direction ---//

    position_calc U_position_calc
    (
        //system signal
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        // input
        .i_data_valid   (w_buff_data_valid),
        .i_gaze_x       (w_gaze_x_tx),               //視野の中心x座標
        .i_gaze_y       (w_gaze_y_tx),               //視野の中心y座標
        .i_observe_x    (w_buff_h_count ),           //処理中のx座標
        .i_observe_y    (w_buff_v_count ),           //処理中のy座標
        .i_thres_1      (w_tres_1_tx),   
        .i_thres_2      (w_tres_2_tx),
        .i_thres_3      (w_tres_3_tx),

        // output
        .o_level(w_rank)
    );
    // always_ff@(posedge w_clk_200)begin
    //     if(i_rst)   r_rank_counter <= 44'd0;
    //     else if(w_mean_out_valid)begin
    //         if(w_mean_data_valid)begin
    //             case(w_mean_rank)
    //                 2'b00:r_rank_counter[0] <= r_rank_counter[0] + 1'b1 ;
    //                 2'b01:r_rank_counter[1] <= r_rank_counter[1] + 1'b1 ;
    //                 2'b10:r_rank_counter[2] <= r_rank_counter[2] + 1'b1 ;
    //                 2'b11:r_rank_counter[3] <= r_rank_counter[3] + 1'b1 ;
    //                 default:r_rank_counter <= r_rank_counter;
    //             endcase
    //         end
    //     end
    //     else    r_rank_counter <= 44'd0;
    // end
//--- Packet wait ---//
    packet_wait_rx #(
        .DATA_BIT   (288),
        .RANK_BIT   (2),
        .ADDRES_BIT (11),
        .LINE_NUM   (12)
    )
    U_packet_wait_rx
    (
        //system signal
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        .i_rank         (w_mean_rank),
        .i_data_valid   (w_mean_data_valid),
        .i_sync_h       (w_mean_out_valid),
        .i_data         (w_rgb),
        .o_valid        (w_packet_valid),
        .o_data         (w_packet_data),
        .o_data_byte    (w_packet_byte),
        .o_row_number   (w_row_number)
    );
// //--- CLOCK CHANGE BUFF 200 -> 125---//
    clock_change_buff U_clock_change_buff(
        .i_write_clk    (w_clk_200),    // 200MHz
        .i_read_clk     (w_clk_125),    // 125MHz
        .i_rst          (i_rst),
        .i_write_valid  (w_packet_valid),
        .i_data_byte    (w_packet_byte),
        .i_row_number   (w_row_number),
        .i_rgb_data     (w_packet_data),
        .i_eth_busy     (w_eth_cont_busy),
        .o_write_valid  (w_125_data_valid),
        .o_data_byte    (w_125_data_byte ),
        .o_row_number   (w_125_row_number),
        .o_rgb_data     (w_125_eth_data  ),
        .o_sof          (w_sof),
        .o_full         (w_parama_sent_flag),
        .o_packet_last  (w_packet_last)  
    );
//--- ETH Control ---//
    eth_control U_eth_control(
        .i_clk              (w_clk_125),
        .i_rst              (i_rst),
        .i_write_valid      (w_125_data_valid),
        .i_data_byte        (w_125_data_byte),
        .i_row_number       (w_125_row_number),
        .i_rgb_data         (w_125_eth_data),
        .i_sof              (w_sof),
        .i_full             (w_parama_sent_flag),
        .i_packet_last      (w_packet_last),
        .i_eth_busy         (w_eth_busy),
        .i_gaze_x           (w_gaze_x_tx),
        .i_gaze_y           (w_gaze_y_tx),
        .i_tres_1           (w_tres_1_tx),
        .i_tres_2           (w_tres_2_tx),
        .i_tres_3           (w_tres_3_tx),
        .o_eth_busy         (w_eth_cont_busy),
        .o_raw_data         (w_cont_eth_data),
        .o_raw_data_valid   (w_cont_data_valid),
        .o_data_byte        (w_cont_data_byte),
        .o_row_number       (w_cont_row_number),
        .o_sof              (w_cont_sof),
        .o_param_flag       (w_param_flag)
    );

//--- ETH TX ---//
    ethernet_tx U_ethernet_tx(
        .i_clk_125          (w_clk_125           ),
        .i_clk_125_90       (w_clk_125_90        ),
        .i_rst              (i_rst               ),
        .i_raw_data         (w_cont_eth_data     ),
        .i_raw_data_valid   (w_cont_data_valid   ),
        .i_phy_ready        (w_phy_ready         ),
        .i_data_byte        (w_cont_data_byte    ),
        .i_row_number       (w_cont_row_number   ),
        .i_sof              (w_cont_sof          ),
        .i_param_flag       (w_param_flag       ),
        // output
        .o_eth_busy          (w_eth_busy),
        .o_fully_framed      (w_fully_framed),
        .o_fully_framed_valid(w_fully_framed_valid)
    );
//--- ETH RX ---//
    remove_header_rx U_remove_header_rx(
        .i_rx_clk       (w_clk_125),
        .i_rst          (i_rst),
        .i_rx_data      (w_fully_framed),
        .i_data_enable  (w_fully_framed_valid),
        .i_data_error   (1'b0),
        .o_packet_data  (w_rx_packet_data),
        .o_data_enable  (w_rx_packet_enable),
        .o_packet_param (w_rx_param),
        .o_param_enable (w_rx_param_enable),
        .o_data_length  (w_rx_packet_length),
        .o_sof          (w_rx_sof)
//        .o_param_flag   (w_param_flag)
    );
//--- Definition PArameter---//
    definition_param_rxside U_definition_param_rxside(
        .i_clk          (w_clk_125),
        .i_rst          (i_rst),
        .i_data_from_eth(w_rx_param),
        .i_data_valid   (w_rx_param_enable),
        .i_param_ready  (w_param_ready),
        .o_gaze_x       (w_gaze_x_rx),
        .o_gaze_y       (w_gaze_y_rx),
        .o_tres_1       (w_tres_1_rx),
        .o_tres_2       (w_tres_2_rx),
        .o_tres_3       (w_tres_3_rx)
    );
//--- CLOCK CHANGE BUFF 125 -> 200 ---//
    clock_change_buff_rx U_clock_change_buff_rx(
        .i_rx_clk       (w_clk_125),      // 125MHz
        .i_read_clk     (w_clk_200),     // 200MHz
        .i_rst          (i_rst),
        .i_write_valid  (w_rx_packet_enable),
        .i_rgb_data     (w_rx_packet_data),
        .i_data_length  (w_rx_packet_length),
        .i_sof          (w_rx_sof),
        .o_write_valid  (w_200_data_valid),
        .o_rgb_data     (w_200_data_data),
        .o_sof          (w_200_sof)   
    );
//--- Decoder(New Part 1)---//
    packet2rgb U_packet2rgb(
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        .i_data_packet  (w_200_data_data),
        .i_data_valid   (w_200_data_valid),
        .o_rgb_data     (w_packet2rgb_data),
        .o_rgb_valid    (w_packet2rgb_valid)
    );
//--- Decoder(New Part 2)---//
    decoder2 U_decoder2(
        .i_clk          (w_clk_200),
        .i_rst          (i_rst),
        .i_press_data   (w_packet2rgb_data),
        .i_press_valid  (w_packet2rgb_valid),
        .i_sof          (w_200_sof),
        .i_gaze_x       (w_gaze_x_rx),
        .i_gaze_y       (w_gaze_y_rx),
        .i_thres_1       (w_tres_1_rx),
        .i_thres_2       (w_tres_2_rx),
        .i_thres_3       (w_tres_3_rx),
        .o_param_ready  (w_param_ready),
        .o_rgb_data     (w_decode2_rgb),
        .o_rgb_valid    (w_decode2_enable),
        .o_sof          (w_decode2_sof)
    );
//--- LINE BUFFER RX ---//
    line_buffer_rxside#(
        .M_DEPTH(11),
        .M_WIDTH(32),
        .LINE_NUM(24) 
    )
    U_line_buffer_rxside
    (
        .i_write_clk        (w_clk_200),    //200Mhz
        .i_pclk             (w_clk_200),   
        .i_rst              (i_rst),
        .i_line_enable      (w_decode2_enable),//(w_decode_enable),
        .i_rgb_data         (w_decode2_rgb),//(w_decode_rgb),
        .i_m_axis_ready     (1'b1),
        .i_sof              (w_decode2_sof),
        .o_m_axis_valid     (w_sync_valid_delay),
        .o_m_axis_data      (w_rxbuff_rgb),
        .o_m_axis_last      (),
        .o_m_axis_sof       ()
    );
//>>>OUTPUT>>>//
    // assign LED[0] = w_clk_locked;
    // assign LED[1] = w_rx_t_locked;
    // assign LED[2] = gt0_rx_fsm_reset_done_out;
    // assign LED[3] = gt0_cplllock_out;
    // assign LED[4] = gt0_rxratedone_out;
    // assign LED[5] = gt0_rxoutclkfabric_out;
    // assign LED[6] = gt0_rxresetdone_out;
    // assign LED[0] = w_packet_data[0];
    // assign LED[1] = w_packet_data[1];
    // assign LED[2] = w_packet_data[2];
    // assign LED[3] = w_packet_data[3];
    // assign LED[4] = w_packet_data[4];
    // assign LED[5] = w_packet_data[5];
    // assign LED[6] = w_packet_data[6];
    // assign LED[7] = w_packet_valid;

    assign o_data = w_rxbuff_rgb;
    assign o_valid = w_sync_valid_delay;
    assign o_sync_v_count = w_sync_v_count;



endmodule