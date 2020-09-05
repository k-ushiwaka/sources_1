module eth_control(
    input           i_clk,
    input           i_rst,
    input           i_write_valid,
    input   [14:0]  i_data_byte,
    input   [7:0]   i_row_number,
    input   [7:0]   i_rgb_data,
    input           i_sof,
    //Control Signal
    input           i_full,
    input           i_packet_last,
    input           i_eth_busy,
    //Parameter 
    input  [10:0]   i_gaze_x,
    input  [10:0]   i_gaze_y,
    input  [23:0]   i_tres_1,
    input  [23:0]   i_tres_2,
    input  [23:0]   i_tres_3,

    output          o_eth_busy,
    output  [7:0]   o_raw_data,
	output          o_raw_data_valid,
	output  [14:0]  o_data_byte,
    output  [7:0]   o_row_number,
    output          o_sof,
    output          o_param_flag
);

    enum  {INIT,WAIT,PARAM_SENT,DATA_SENT}state,next;
    logic           r_eth_busy  ;
    logic  [7:0]    r_raw_data  ;
    logic           r_raw_data_valid;
    logic  [14:0]   r_data_byte ;
    logic  [7:0]    r_row_number;
    logic           r_sof       ;
    logic           r_param_flag;

    logic   [95:0]  r_param_reg ;
    logic   [7:0]   r_data_count;

//== State Mchine ==//
    always_ff @(posedge i_clk)begin
        if(i_rst)   state <= INIT;
        else        state <= next;
    end
    always_comb begin: read_state
        next = state;         //default
        unique case(state)
            INIT:       if(~i_eth_busy && ~i_full)              next = WAIT;
            WAIT:       if(~i_eth_busy && i_full)               next = PARAM_SENT;
            PARAM_SENT: if(~i_eth_busy && r_data_count == 12)    next = DATA_SENT;
            DATA_SENT:  if(i_packet_last)                       next = WAIT;  
        endcase
    end
//-- Register Transfer --//
    always_ff@(posedge i_clk)begin
        if(state == INIT)begin
            r_eth_busy          <= i_eth_busy;
            r_raw_data          <= 8'd0 ;
            r_raw_data_valid    <= 1'd0 ;
            r_data_byte         <= 15'd0;
            r_row_number        <= 8'd0 ;
            r_sof               <= 1'b0 ;
            r_param_flag        <= 1'b0 ;
            r_param_reg         <= 96'd0;
            r_data_count        <= 8'd0;
        end
        else if(state == WAIT)begin
            r_eth_busy          <= 1'b1 ;
            r_raw_data          <= 8'd0 ;
            r_raw_data_valid    <= 1'd0 ;
            r_data_byte         <= r_data_byte;
            r_row_number        <= 8'd0 ;
            r_sof               <= 1'b0 ;
            r_param_flag        <= 1'b0 ;
            r_param_reg[94:84]  <= i_gaze_x;
            r_param_reg[82:72]  <= i_gaze_y;
            r_param_reg[71:48]  <= i_tres_1;
            r_param_reg[47:24]  <= i_tres_2;
            r_param_reg[23:0 ]  <= i_tres_3;
            r_data_count        <= 8'd0;
        end
        else if(state == PARAM_SENT)begin
            r_eth_busy          <= 1'b1  ;
            r_raw_data          <= r_param_reg[95:88];
            r_data_byte         <= 15'd96;
            r_row_number        <= 8'd0  ;
            r_sof               <= 1'b0  ;
            r_param_flag        <= 1'b1  ;
            r_param_reg         <= (r_param_reg << 8);
            if(r_data_count == 8'd12)begin
                r_raw_data_valid    <= 1'b0  ;
            end
            else begin
                r_raw_data_valid    <= 1'b1  ;
                r_data_count        <= r_data_count + 1'b1;
            end
        end
        else if(state == DATA_SENT)begin
            r_eth_busy          <= i_eth_busy      ;
            r_raw_data          <= i_rgb_data      ;
            r_raw_data_valid    <= i_write_valid   ;
            r_data_byte         <= i_data_byte     ;
            r_row_number        <= i_row_number    ;
            r_sof               <= i_sof           ;
            r_param_flag        <= 1'b0            ;
        end
    end
// //-- Output Assign --//
    assign o_eth_busy          = r_eth_busy      ;
    assign o_raw_data          = r_raw_data      ;
    assign o_raw_data_valid    = r_raw_data_valid;
    assign o_data_byte         = r_data_byte     ;
    assign o_row_number        = r_row_number    ;
    assign o_sof               = r_sof           ;
    assign o_param_flag        = r_param_flag    ;


endmodule

// eth_control U_eth_control(
//     .i_clk              (i_clk),
//     .i_rst              (i_rst),
//     .i_write_valid      (i_write_valid),
//     .i_data_byte        (i_data_byte),
//     .i_row_number       (i_row_number),
//     .i_rgb_data         (i_rgb_data),
//     .i_sof              (i_sof),
//     .i_full             (i_full),
//     .i_packet_last      (i_packet_last),
//     .i_eth_busy         (i_eth_busy),
//     .i_gaze_x           (i_gaze_x),
//     .i_gaze_y           (i_gaze_y),
//     .i_tres_1           (i_tres_1),
//     .i_tres_2           (i_tres_2),
//     .i_tres_3           (i_tres_3),
//     .o_eth_busy         (o_eth_busy),
//     .o_raw_data         (o_raw_data),
// 	.o_raw_data_valid   (o_raw_data_valid),
// 	.o_data_byte        (o_data_byte),
//     .o_row_number       (o_row_number),
//     .o_sof              (o_sof),
//     .o_param_flag       (o_param_flag)
// );