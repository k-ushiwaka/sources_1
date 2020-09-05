module definition_param_txside(
    input           i_clk,
    input           i_rst,
    input   [10:0]  i_gaze_x,
    input   [10:0]  i_gaze_y,
    input   [23:0]  i_tres_1,
    input   [23:0]  i_tres_2,
    input   [23:0]  i_tres_3,
    input           i_vsync,

    output  [10:0]  o_gaze_x,
    output  [10:0]  o_gaze_y,
    output  [23:0]  o_tres_1,
    output  [23:0]  o_tres_2,
    output  [23:0]  o_tres_3
);

    logic   [10:0]  r_gaze_x_inside;
    logic   [10:0]  r_gaze_y_inside;
    logic   [23:0]  r_tres_1_inside;
    logic   [23:0]  r_tres_2_inside;
    logic   [23:0]  r_tres_3_inside;

    logic   [10:0]  r_gaze_x_outside;
    logic   [10:0]  r_gaze_y_outside;
    logic   [23:0]  r_tres_1_outside;
    logic   [23:0]  r_tres_2_outside;
    logic   [23:0]  r_tres_3_outside;

    logic   [1:0]   r_vsync_edge;
//// Edge Vsync
    always_ff@(posedge i_clk)begin
        if  (i_rst)   r_vsync_edge <= 2'b00;
        else begin
            r_vsync_edge[0] <= i_vsync;
            r_vsync_edge[1] <= r_vsync_edge[0];
        end 
    end

//// Inside stack
    always_ff@(posedge i_clk)begin
        if(i_rst)begin
            r_gaze_x_inside <= 10'd0;
            r_gaze_y_inside <= 10'd0;
            r_tres_1_inside <= 24'd0;
            r_tres_2_inside <= 24'd0;
            r_tres_3_inside <= 24'd0;
        end
        else begin
            r_gaze_x_inside <= i_gaze_x;
            r_gaze_y_inside <= i_gaze_y;
            r_tres_1_inside <= i_tres_1;
            r_tres_2_inside <= i_tres_2;
            r_tres_3_inside <= i_tres_3;
        end
    end
//// if(i_save) => output ; else Q=Q; ////
    always_ff@(posedge i_clk)begin
        if(i_rst)begin
            r_gaze_x_outside <= 10'd0;
            r_gaze_y_outside <= 10'd0;
            r_tres_1_outside <= 24'd0;
            r_tres_2_outside <= 24'd0;
            r_tres_3_outside <= 24'd0;
        end
        else if(r_vsync_edge == 2'b01)begin
            r_gaze_x_outside <= r_gaze_x_inside;
            r_gaze_y_outside <= r_gaze_y_inside;
            r_tres_1_outside <= r_tres_1_inside;
            r_tres_2_outside <= r_tres_2_inside;
            r_tres_3_outside <= r_tres_3_inside;
        end
        else begin
            r_gaze_x_outside <= r_gaze_x_outside;
            r_gaze_y_outside <= r_gaze_y_outside;
            r_tres_1_outside <= r_tres_1_outside;
            r_tres_2_outside <= r_tres_2_outside;
            r_tres_3_outside <= r_tres_3_outside;
        end
    end

    assign o_gaze_x = r_gaze_x_outside;
    assign o_gaze_y = r_gaze_y_outside;
    assign o_tres_1 = r_tres_1_outside;
    assign o_tres_2 = r_tres_2_outside;
    assign o_tres_3 = r_tres_3_outside;

endmodule


// definition_param_txside U_definition_param_txside(
//     .i_clk              (),
//     .i_rst              (i_rst),
//     .i_gaze_x           (),
//     .i_gaze_y           (),
//     .i_tres_1           (),
//     .i_tres_2           (),
//     .i_tres_3           (),
//     .i_save             (w_save),
//     .o_gaze_x           (w_gaze_x_tx),
//     .o_gaze_y           (w_gaze_y_tx),
//     .o_tres_1           (w_tres_1_tx),
//     .o_tres_2           (w_tres_2_tx),
//     .o_tres_3           (w_tres_3_tx)
// );