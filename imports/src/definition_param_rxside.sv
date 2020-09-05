module definition_param_rxside(
    input           i_clk,
    input           i_rst,
    input   [7:0]   i_data_from_eth,
    input           i_data_valid,
    input           i_param_ready,

    output  [10:0]  o_gaze_x,
    output  [10:0]  o_gaze_y,
    output  [23:0]  o_tres_1,
    output  [23:0]  o_tres_2,
    output  [23:0]  o_tres_3
);

    (* mark_debug = "true" *)enum  {INIT,WAIT,GET1,GET2,GET3,WAIT_DEASSERT}state,next;
    (* mark_debug = "true" *)logic  [7:0]   r_data_packet_delay; 
    (* mark_debug = "true" *)logic  [2:0]   r_counter;
    (* mark_debug = "true" *)logic  [15:0]  r_temp;
    (* mark_debug = "true" *)logic  [23:0]  r_gaze_inside;
    (* mark_debug = "true" *)logic  [23:0]  r_tres_1_inside;
    (* mark_debug = "true" *)logic  [23:0]  r_tres_2_inside;
    (* mark_debug = "true" *)logic  [23:0]  r_tres_3_inside;

    logic  [23:0]  r_gaze_outside;
    logic  [23:0]  r_tres_1_outside;
    logic  [23:0]  r_tres_2_outside;
    logic  [23:0]  r_tres_3_outside;
//DD Delay DD//
    delay #(
        .DATA_WIDTH(8),
        .DELAY_TIME(1)
    )
    U_delay_valid(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_data_from_eth),
        .o_data(r_data_packet_delay)
    );
//== State Mchine ==//
    always_ff @(posedge i_clk,posedge i_rst )begin
        if(i_rst)   state <= INIT;
        else        state <= next;
    end
    always_comb begin: read_state
        next = state;         //default
        unique case(state)
            INIT:                    next = WAIT;
            WAIT:   if(i_data_valid) next = GET1;
            GET1:                    next = GET2;
            GET2:                    next = GET3;
            GET3:begin
                    if(r_counter < 4)  next = GET1;
                    else               next = WAIT_DEASSERT;    
            end
            WAIT_DEASSERT:  if(~i_data_valid) next = WAIT;
        endcase
    end

//== Update inxide reg==//
    always_ff@(posedge i_clk,posedge i_rst)begin
        if(i_rst )begin
            r_counter           <=3'd0; 
            r_gaze_inside       <=24'd0;
            r_tres_1_inside     <=24'd0;
            r_tres_2_inside     <=24'd0;
            r_tres_3_inside     <=24'd0;
            r_temp              <=24'd0;
        end
        else if(state == WAIT)begin
            r_counter <= 3'd0;
        end
        else if(state == GET1)begin
            r_counter       <= r_counter + 1'b1;
            r_temp[15:8]   <= r_data_packet_delay;
        end
        else if(state == GET2)begin
            r_temp[7:0]    <= r_data_packet_delay;
        end
        else if(state == GET3)begin
            case(r_counter)
                3'd1 : r_gaze_inside   <= {r_temp,r_data_packet_delay};
                3'd2 : r_tres_1_inside <= {r_temp,r_data_packet_delay};
                3'd3 : r_tres_2_inside <= {r_temp,r_data_packet_delay};
                3'd4 : r_tres_3_inside <= {r_temp,r_data_packet_delay};
                default:  begin
                    r_counter           <=r_counter; 
                    r_gaze_inside       <=r_gaze_inside;
                    r_tres_1_inside     <=r_tres_1_inside;
                    r_tres_2_inside     <=r_tres_2_inside;
                    r_tres_3_inside     <=r_tres_3_inside;
                    r_temp              <=r_temp;
                end 
            endcase
        end
        else begin
            r_counter           <=r_counter;
            r_gaze_inside       <=r_gaze_inside;
            r_tres_1_inside     <=r_tres_1_inside;
            r_tres_2_inside     <=r_tres_2_inside;
            r_tres_3_inside     <=r_tres_3_inside;
            r_temp              <=r_temp; 
        end
    end
//== Output reg definition ==//
    always_ff@(posedge i_clk,posedge i_rst)begin
        if(i_rst)begin
            r_gaze_outside       <=24'd0;
            r_tres_1_outside     <=24'd0;
            r_tres_2_outside     <=24'd0;
            r_tres_3_outside     <=24'd0;
        end
        else if(i_param_ready)begin
            r_gaze_outside       <= r_gaze_inside;
            r_tres_1_outside     <= r_tres_1_inside;
            r_tres_2_outside     <= r_tres_2_inside;
            r_tres_3_outside     <= r_tres_3_inside;
        end
        else begin
            r_gaze_outside       <= r_gaze_outside;
            r_tres_1_outside     <= r_tres_1_outside;
            r_tres_2_outside     <= r_tres_2_outside;
            r_tres_3_outside     <= r_tres_3_outside;
        end
    end
// Assign output //
    assign o_gaze_x =r_gaze_outside[22:12];
    assign o_gaze_y =r_gaze_outside[10:0] ;
    assign o_tres_1 =r_tres_1_outside;
    assign o_tres_2 =r_tres_2_outside;
    assign o_tres_3 =r_tres_3_outside;

endmodule

// definition_param_rxside U_definition_param_rxside(
//     .i_clk          (i_clk),
//     .i_rst          (i_rst),
//     .i_data_from_eth(i_data_from_eth),
//     .i_data_valid   (i_data_valid),
//     .o_gaze_x       (o_gaze_x),
//     .o_gaze_y       (o_gaze_y),
//     .o_tres_1       (o_tres_1),
//     .o_tres_2       (o_tres_2),
//     .o_tres_3       (o_tres_3)
// );