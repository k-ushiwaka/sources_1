module packet2rgb(
    input           i_clk,
    input           i_rst,
    input   [7:0]   i_data_packet,
    input           i_data_valid,
    output  [23:0]  o_rgb_data,
    output          o_rgb_valid
);
    enum  {INIT,WAIT,GET1,GET2,GET3}state,next;

    logic  [23:0]  r_rgb_data;
    logic  [7:0]   r_data_packet_delay;
    logic          r_rgb_valid;
//DD Delay DD//
    delay #(
        .DATA_WIDTH(8),
        .DELAY_TIME(1)
    )
    U_delay_valid(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_data_packet),
        .o_data(r_data_packet_delay)
    );
//== State Mchine ==//
    always_ff @(posedge i_clk)begin
        if(i_rst)   state <= INIT;
        else        state <= next;
    end
    always_comb begin
        next = state;         //default
        unique case(state)
            INIT:                    next = WAIT;
            WAIT:   if(i_data_valid) next = GET1;
            GET1:   if(i_data_valid) next = GET2;
            GET2:   if(i_data_valid) next = GET3;
            GET3:begin
                    if(i_data_valid) next = GET1;
                    else             next = WAIT;    
            end
        endcase
    end

    always_ff@(posedge i_clk)begin
        if(state == INIT)begin
            r_rgb_data  <= 24'd0;
            r_rgb_valid <= 1'd0;
        end
        else if(state == GET1)begin
            r_rgb_data[7:0]  <= r_data_packet_delay;
            r_rgb_valid      <= 1'd0;
        end
        else if(state == GET2)begin
            r_rgb_data[15:8] <= r_data_packet_delay;
            r_rgb_valid      <= 1'd0;
        end
        else if(state == GET3)begin
            r_rgb_data[23:16]<= r_data_packet_delay;
            r_rgb_valid      <= 1'd1;
        end
        else begin
            r_rgb_data  <= 24'd0;
            r_rgb_valid <= 1'd0;
        end
    end

    assign o_rgb_data  = r_rgb_data;
    assign o_rgb_valid = r_rgb_valid;


endmodule

// packet2rgb U_packet2rgb(
//     .i_clk          (),
//     .i_rst          (),
//     .i_data_packet  (),
//     .i_data_valid   (),
//     .o_rgb_data     (),
//     .o_rgb_valid    ()
// );