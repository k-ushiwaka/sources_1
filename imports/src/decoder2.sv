module decoder2(
    input           i_clk,
    input           i_rst,
    input   [23:0]  i_press_data,
    input           i_press_valid,
    input           i_sof,
    input   [10:0]  i_gaze_x,
    input   [10:0]  i_gaze_y,
    input   [23:0]  i_thres_1,
    input   [23:0]  i_thres_2,
    input   [23:0]  i_thres_3,
    output          o_param_ready,
    output  [23:0]  o_rgb_data,
    output  [11:0]  o_rgb_valid,
    output          o_sof
);
    enum  {INIT,WAIT,DIST_CALC,RANK1,RANK2,RANK3,RANK4,DATA_WAIT,RST}state,next;

    logic   [10:0]  w_fifo_data_count;
    logic           r_read_enable;
    logic   [1:0]   r_enable_count;
    logic   [7:0]   r_count;
    logic   [23:0]  w_buff_read;
    logic   [7:0]   r_count_thres;
    logic   [11:0]  r_rgb_valid;
    logic                                    r_rst;
    logic   [1:0]                            r_sof_edge;
    logic                                    r_sof_flag;
    logic                                    r_sof;
// Distance Calculation Logic
    logic   [10:0]      r_gaze_x;
    logic   [10:0]      r_gaze_y;
    logic   [23:0]      r_thres_1;
    logic   [23:0]      r_thres_2;
    logic   [23:0]      r_thres_3;
    logic   [11:0]      r_diff_x;
    logic   [11:0]      r_diff_y;
    logic   [11:0]      w_diff_abs_x;
    logic   [11:0]      w_diff_abs_y;
    logic   [23:0]      w_pow_x;
    logic   [23:0]      w_pow_y;
    logic   [24:0]      w_sum;
    logic   [1:0]       r_level;
    logic   [10:0]      r_count_x;
    logic   [10:0]      r_count_y;
// RST //
    always_ff@(posedge i_clk)begin
        if(i_rst)               r_rst <= 1'b0;
        else if(state == RST)   r_rst <= 1'b1;
        else                    r_rst <= 1'b0;
    end
// Start Of Flame //
    always_ff@(posedge i_clk)begin
        if(i_rst)   r_sof_edge <= 2'b00;
        else begin
                    r_sof_edge[0] <= i_sof;
                    r_sof_edge[1] <= r_sof_edge[0];
        end
    end

    always_ff@(posedge i_clk)begin
        if(i_rst)begin                       
            r_sof_flag <= 1'b0;
            r_sof      <= 1'b0;
        end
        else if(r_sof_edge == 2'b01)begin
            r_sof_flag <= 1'b1;
            r_sof      <= 1'b0;
        end    
        else if(r_sof_flag == 1'b1 && state == DIST_CALC &&  r_count_x == 11'd0 && r_count_y == 11'd0)begin
            r_sof_flag <= 1'b0;
            r_sof      <= 1'b1;
        end
        else begin
            r_sof_flag <= r_sof_flag;
            r_sof      <= 1'b0;
        end
    end

//GG Buffer GG//
    generate_memory#(
        .M_DEPTH(11),
        .M_WIDTH(32),
        .FULL_NUM(2048),
        .COUNT(1)
    )
    U_generate_memory
    (
        .i_rst          (i_rst || r_rst),
        .i_write_clk    (i_clk),
        .i_write_enable (i_press_valid),
        .i_write_data   ({8'd0,i_press_data}),
        .i_read_clk     (i_clk),
        .i_read_enable  ({state == DIST_CALC || state == DATA_WAIT}?1'b0:r_read_enable),
        .o_read_data    (w_buff_read),  
        .o_read_num     (w_fifo_data_count)
    );
//== State Machine ==//
    always_ff@(posedge i_clk)begin
        if(i_rst)   state <= INIT;
        else        state <= next;
    end
    always_comb begin
        next = state;         //default
        unique case(state)
            INIT:                                       next = WAIT;
            WAIT:       if(w_fifo_data_count > 150)     next = DIST_CALC;
            DIST_CALC:begin
                        if(r_count_y==11'd1080)         next = WAIT;
                        else if(r_level == 2'b00)       next = RANK1;
                        else if(r_level == 2'b01)       next = RANK2; 
                        else if(r_level == 2'b10)       next = RANK3;
                        else if(r_level == 2'b11)       next = RANK4;
                    end  
            RANK1:begin
                        if(r_count == 8'd143)begin
                            if(r_count_y==11'd1080)next = WAIT;          
                            else if(w_fifo_data_count-1'b1<r_count_thres) next = DATA_WAIT;          
                            else                                     next = DIST_CALC;
                        end
            end
            RANK2:begin
                        if(r_count == 8'd71)begin
                            if(r_count_y==11'd1080)next = WAIT;          
                            else if(w_fifo_data_count<r_count_thres) next = DATA_WAIT;          
                            else                                     next = DIST_CALC;
                        end
            end
            RANK3:begin
                        if(r_count == 8'd47)begin          
                            if(r_count_y==11'd1080)next = WAIT;
                            else if(w_fifo_data_count<r_count_thres) next = DATA_WAIT;          
                            else                                     next = DIST_CALC;
                        end
            end
            RANK4:begin
                        if(r_count == 8'd35)begin          
                            if(r_count_y==11'd1080)next = WAIT;
                            else if(w_fifo_data_count<r_count_thres) next = DATA_WAIT;          
                            else                                     next = DIST_CALC;
                        end
            end
            DATA_WAIT:  if(w_fifo_data_count >= r_count_thres)  next = DIST_CALC;
            RST:         next = WAIT;          
        endcase
    end
//FIFO READ ENABLE && Repeat Count//
    always_ff@(posedge i_clk)begin
        if(state == INIT || state == WAIT || state == DIST_CALC||state == RST)begin
            r_count  <= 8'd0;
        end
        else if(state == RANK1 || state == RANK2 || state == RANK3 ||state == RANK4)begin
            r_count  <= r_count + 8'd1;
        end
        else begin
            r_count  <= r_count;
        end
    end
    always_ff@(posedge i_clk)begin
        if(state == INIT || state == WAIT ||state == RST)begin
            r_read_enable <= 1'b0;
        end
        else if(state == RANK1 || state == DIST_CALC)begin
            r_read_enable <= 1'b1;
        end
        else if(state == RANK1)begin
            r_read_enable <= 1'b1;
        end
        else if(state == RANK2)begin
            if(r_count[0] == 1'b1)  r_read_enable <= 1'b1;
            else                    r_read_enable <= 1'b0;
        end
        else if(state == RANK3)begin
            if( r_count == 8'd2  || r_count == 8'd5  || r_count == 8'd8  || r_count == 8'd11 || 
                r_count == 8'd14 || r_count == 8'd17 || r_count == 8'd20 || r_count == 8'd23 || 
                r_count == 8'd26 || r_count == 8'd29 || r_count == 8'd32 || r_count == 8'd35 || 
                r_count == 8'd38 || r_count == 8'd41 || r_count == 8'd44 || r_count == 8'd47 )r_read_enable <= 1'b1;
            else                       r_read_enable <= 1'b0;
        end
        else if(state == RANK4)begin
            if(r_count[1:0] == 2'b11)  r_read_enable <= 1'b1;
            else                       r_read_enable <= 1'b0;
        end
        else begin
            r_read_enable <= 1'b0;
        end
    end
//Output Enable Control//
    always_ff@(posedge i_clk)begin
        if(state == INIT || state == DIST_CALC||state == RST)   r_enable_count <= 2'b00;
        else if(state == RANK2)begin
            if(r_enable_count == 2'b01) r_enable_count <= 2'b00;
            else                        r_enable_count <= r_enable_count + 1'b1;
        end
        else if(state == RANK3)begin
            if(r_enable_count == 2'b10) r_enable_count <= 2'b00;
            else                        r_enable_count <= r_enable_count + 1'b1;
        end
        else if(state == RANK4)begin
            if(r_enable_count == 2'b11) r_enable_count <= 2'b00;
            else                        r_enable_count <= r_enable_count + 1'b1;
        end
        else begin
            r_enable_count <= 2'b00;
        end
    end
    always_ff@(posedge i_clk)begin
        if(state == INIT || state == WAIT || state == DIST_CALC||state == RST)begin
            r_rgb_valid <= 12'd0;
        end
        else if(state == RANK1)begin
            if(r_rgb_valid == 12'b0) r_rgb_valid = 12'b0000000000000001;
            else if(r_rgb_valid[11]) r_rgb_valid = 12'b0000000000000001;
            else                     r_rgb_valid <= r_rgb_valid << 1;
        end
        else if(state == RANK2)begin
            if(r_enable_count == 2'b00)begin
                if(r_rgb_valid == 12'b0) r_rgb_valid = 12'b0000000000000011;
                else if(r_rgb_valid[11]) r_rgb_valid = 12'b0000000000000011;
                else                r_rgb_valid <= r_rgb_valid << 2;
            end
        end
        else if(state == RANK3)begin
            if(r_enable_count == 2'b00)begin
                if(r_rgb_valid == 12'b0) r_rgb_valid = 12'b0000000000000111;
                else if(r_rgb_valid[11]) r_rgb_valid = 12'b0000000000000111;
                else                r_rgb_valid <= r_rgb_valid << 3;
            end
        end
        else if(state == RANK4)begin
            if(r_enable_count == 2'b00)begin
                if(r_rgb_valid == 12'b0) r_rgb_valid = 12'b0000000000001111;
                else if(r_rgb_valid[11]) r_rgb_valid = 12'b0000000000001111;
                else                r_rgb_valid <= r_rgb_valid << 4;
            end
        end
        else begin
            r_rgb_valid <= 12'd0;
        end
    end
//復元に必要なデータの個数の閾値
    always_ff@(posedge i_clk)begin
        if(state == INIT ||state == RST)    r_count_thres <= 8'd0;
        else begin
            if(r_level == 2'b00)       r_count_thres = 8'd144;
            else if(r_level == 2'b01)       r_count_thres = 8'd36; 
            else if(r_level == 2'b10)       r_count_thres = 8'd16;
            else if(r_level == 2'b11)       r_count_thres = 8'd9;
        end
    end
//Process Point count//
    always_ff@(posedge i_clk)begin
        if(state == INIT || state == WAIT||state == RST)begin
            r_count_x <= 11'd0;
            r_count_y <= 11'd0;
        end
        else if(state == DIST_CALC)begin
            if(r_count_x == 11'd1908)begin
                r_count_x <= 11'd0;
                r_count_y <= r_count_y + 11'd12;
            end
            else begin
                r_count_x <= r_count_x + 11'd12;
                r_count_y <= r_count_y;
            end
        end
        else begin
            r_count_x <= r_count_x;
            r_count_y <= r_count_y;
        end
    end
//DSPスライス使ったユークリッド距離の計算
    // always_ff@(posedge i_clk)begin
    //     if(state == INIT)begin
    //         r_gaze_x    <= 11'd0;
    //         r_gaze_y    <= 11'd0;
    //         r_thres_1   <= 24'd0;
    //         r_thres_2   <= 24'd0;
    //         r_thres_3   <= 24'd0;
    //     end
    //     else if(state == WAIT)begin
    //         r_gaze_x    <= i_gaze_x ;
    //         r_gaze_y    <= i_gaze_y ;
    //         r_thres_1   <= i_thres_1;
    //         r_thres_2   <= i_thres_2;
    //         r_thres_3   <= i_thres_3;
    //     end
    //     else begin
    //         r_gaze_x    <= r_gaze_x ;
    //         r_gaze_y    <= r_gaze_y ;
    //         r_thres_1   <= r_thres_1;
    //         r_thres_2   <= r_thres_2;
    //         r_thres_3   <= r_thres_3;
    //     end
    // end
    always@(posedge i_clk)begin
        if(i_rst)begin
            r_diff_x <= 12'h000;
            r_diff_y <= 12'h000;
        end
        else begin
            r_diff_x <= i_gaze_x - r_count_x;
            r_diff_y <= i_gaze_y - r_count_y;
        end
    end
    assign w_diff_abs_x = (r_diff_x[11] == 1'b1) ? (~r_diff_x[11:0])+1'b1 : r_diff_x[11:0];
    assign w_diff_abs_y = (r_diff_y[11] == 1'b1) ? (~r_diff_y[11:0])+1'b1 : r_diff_y[11:0];

    generate_multiplier  U_generate_multiplier_X(
        .CLK(i_clk),          // input wire CLK
        .A(w_diff_abs_x),     // input wire [11 : 0] A
        .B(w_diff_abs_x),     // input wire [11 : 0] B
        .P(w_pow_x)           // output wire [23 : 0] P
    );

    generate_multiplier  U_generate_multiplier_Y(
        .CLK(i_clk),          // input wire CLK
        .A(w_diff_abs_y),     // input wire [11 : 0] A
        .B(w_diff_abs_y),     // input wire [11 : 0] B
        .P(w_pow_y)           // output wire [23 : 0] P
    );
    assign w_sum = w_pow_x + w_pow_y;

    //出力Control
    always@(posedge i_clk)begin
        if(i_rst)   r_level <= 2'b00;
        else begin
            if      (w_sum > i_thres_1)  r_level <= 2'b11;
            else if (w_sum > i_thres_2)  r_level <= 2'b10;
            else if (w_sum > i_thres_3)  r_level <= 2'b01;
            else                         r_level <= 2'b00;
        end
    end

// ASSIGN OUTPUT //
    assign o_rgb_data = w_buff_read;
    assign o_rgb_valid= r_rgb_valid;
    assign o_sof      = r_sof;
    assign o_param_ready = (state == WAIT);

endmodule


// decoder2 U_decoder2(
//     .i_clk          (),
//     .i_rst          (),
//     .i_press_data   (),
//     .i_press_valid  (),
//     .i_sof          (),
//     .i_gaze_x       (),
//     .i_gaze_y       (),
//     .i_tres_1       (),
//     .i_tres_2       (),
//     .i_tres_3       (),
//     .o_rgb_data     (),
//     .o_rgb_valid    (),
//     .o_sof          ()
// );