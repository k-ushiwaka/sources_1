module position_calc
(
    //system signal
    input   i_clk,
    input   i_rst,

    // input
    input               i_data_valid,
    input   [10:0]      i_gaze_x,               //視野の中心x座標
    input   [10:0]      i_gaze_y,               //視野の中心y座標
    input   [10:0]      i_observe_x,              //処理中のx座標
    input   [10:0]      i_observe_y,               //処理中のy座標
    input   [23:0]      i_thres_1,   
    input   [23:0]      i_thres_2,
    input   [23:0]      i_thres_3,
    // output
    output  [1:0]       o_level
);

logic   [3:0]       r_count_12;
logic   [11:0]      r_diff_x;
logic   [11:0]      r_diff_y;
logic   [11:0]      w_diff_abs_x;
logic   [11:0]      w_diff_abs_y;
logic   [23:0]      w_pow_x;
logic   [23:0]      w_pow_y;
logic   [24:0]      w_sum;

logic   [1:0]       r_level;

always_ff@(posedge i_clk)begin
    if(i_rst)   r_count_12 <= 4'b0000;
    else if(i_data_valid)begin
        if(r_count_12 == 4'd11)   r_count_12 <= 4'b0000;
        else                    r_count_12 <= r_count_12 + 1'b1;
    end
    else        r_count_12 <= r_count_12;
end

////////////////////////////////////////////////////////////////////////////////////////////

//DSPスライス使ったユークリッド距離の計算
always@(posedge i_clk)begin
    if(i_rst)begin
        r_diff_x <= 12'h000;
        r_diff_y <= 12'h000;
    end
    else begin
        r_diff_x <= i_gaze_x - i_observe_x;
        r_diff_y <= i_gaze_y - i_observe_y;
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
    else if(r_count_12 == 4'd2)begin
        if      (w_sum > i_thres_1)  r_level <= 2'b11;
        else if (w_sum > i_thres_2)  r_level <= 2'b10;
        else if (w_sum > i_thres_3)  r_level <= 2'b01;
        else                         r_level <= 2'b00;
    end
    else r_level <= r_level; 
end

//Outside Assign
assign o_level = r_level;

endmodule
