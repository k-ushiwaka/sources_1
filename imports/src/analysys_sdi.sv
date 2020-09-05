module analysys_sdi#(
    parameter COUNT_ENABLE = "TRUE",
    parameter COUNT_WIDE   = 12, 
    parameter IMG_W = 1920
)
(
    //system signal
    input   i_clk,
    input   i_rst,

    //sdi signal
    input   [9:0]   i_y,
    input   [9:0]   i_cbcr,
    input           i_sav,
    input           i_eav,
    input           i_trs,

    //output
    output          o_sync_h,
    output          o_sync_v,
    output  [9:0]   o_y,
    output  [9:0]   o_cb,
    output  [9:0]   o_cr,

    //Debug
    output  [COUNT_WIDE -1 : 0] o_sync_h_count,
    output  [COUNT_WIDE -1 : 0] o_sync_v_count
);

//local signal
logic   r_sync_h;
logic   r_sync_v;
logic   [9:0]   r_y;
logic   [9:0]   r_cb;
logic   [9:0]   r_cr;
logic           r_cbcr_switch;
// - Debug
(* dont_touch = COUNT_ENABLE *)logic   [COUNT_WIDE -1 : 0] r_sync_h_count;
(* dont_touch = COUNT_ENABLE *)logic   [COUNT_WIDE -1 : 0] r_sync_v_count;
//- delay signal
logic   w_sync_h_delay;
logic   w_sync_h_delay2;
logic   w_sync_v_delay;
logic   [9:0]   w_y_delay;
logic   [9:0]   w_cb_delay;
(* dont_touch = COUNT_ENABLE *)logic   [COUNT_WIDE -1 : 0] w_sync_h_count_delay;
(* dont_touch = COUNT_ENABLE *)logic   [COUNT_WIDE -1 : 0] w_sync_v_count_delay;


//FF

//- Horizon signal

always_ff@(posedge i_clk)begin
    if(i_rst)                                                   r_sync_h <= 1'b0;
    else if (r_sync_h_count == IMG_W-1 )                        r_sync_h <= 1'b0;
    else if (i_sav  && i_y != 10'h3ff && i_y != 10'h000)        r_sync_h <= 1'b1;
    else                                                        r_sync_h <= r_sync_h;
end

//- Vertical signal
always_ff@(posedge i_clk)begin
    if(i_rst)                                   r_sync_v <= 1'b0;
    else if (i_y == 10'h3ff || i_y == 10'h000 ) r_sync_v <= r_sync_v;
    else if (i_trs)                             r_sync_v <= (~i_y[7]);
    else                                        r_sync_v <= r_sync_v;
end

//- Debug generate
generate
    if(COUNT_ENABLE == "TRUE")begin
        always_ff@(posedge i_clk)begin
            if(i_rst)                   r_sync_h_count <= {COUNT_WIDE{1'b0}};
            else if(!r_sync_h)    r_sync_h_count <= {COUNT_WIDE{1'b0}};
            else                        r_sync_h_count <= r_sync_h_count + 1'b1;
        end
        delay #(
            .DATA_WIDTH(COUNT_WIDE),
            .DELAY_TIME(1)
        ) 
        U_dealy_h_count(
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_data(r_sync_h_count),
            .o_data(w_sync_h_count_delay)
        );

        always_ff@(posedge i_clk)begin
            if(i_rst)                   r_sync_v_count <= {COUNT_WIDE{1'b0}};
            else if(!w_sync_v_delay)    r_sync_v_count <= {COUNT_WIDE{1'b0}};
            else if(i_eav && i_y != 10'h3ff && i_y != 10'h000)                       r_sync_v_count <= r_sync_v_count + 1'b1;
            else                        r_sync_v_count <= r_sync_v_count;
        end
        delay #(
            .DATA_WIDTH(COUNT_WIDE),
            .DELAY_TIME(1)
        ) 
        U_dealy_v_count(
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_data(r_sync_v_count),
            .o_data(w_sync_v_count_delay)
        );
    end
endgenerate 

//- analysys Y signal
always_ff@(posedge i_clk)begin
    if(i_rst)           r_y <= 10'h000;
    else if(r_sync_h)   r_y <= i_y;
    else                r_y <= 10'h000;
end

//- switch Cb Cr 
always_ff@(posedge i_clk)begin
    if(i_rst)           r_cbcr_switch <= 1'b0;
    else if(r_sync_h)   r_cbcr_switch <= ~r_cbcr_switch;
    else                r_cbcr_switch <= 1'b0;
end

//- analysys Cb signal
always_ff@(posedge i_clk)begin
    if(i_rst)                       r_cb <= 10'h000;
    else if(r_sync_h)begin
        if(r_cbcr_switch == 1'b0)   r_cb <= i_cbcr;
        else                        r_cb <= r_cb;
    end
    else                            r_cb <= 10'h000;
end

//- analysys Cr signal
always_ff@(posedge i_clk)begin
    if(i_rst)                       r_cr <= 10'h000;
    else if(r_sync_h)begin
        if(r_cbcr_switch == 1'b1)   r_cr <= i_cbcr;
        else                        r_cr <= r_cr;
    end
    else                            r_cr <= r_cr;
end

// Delay signal
delay #(
    .DATA_WIDTH(1),
    .DELAY_TIME(2)
) 
U_dealy_h(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(r_sync_h),
    .o_data(w_sync_h_delay)
);

//delay #(
//    .DATA_WIDTH(1),
//    .DELAY_TIME(4)
//) 
//U_dealy2_h(
//    .i_clk(i_clk),
//    .i_rst(i_rst),
//    .i_data(r_sync_h),
//    .o_data(w_sync_h_delay2)
//);

delay #(
    .DATA_WIDTH(1),
    .DELAY_TIME(2)
) 
U_dealy_v(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(r_sync_v),
    .o_data(w_sync_v_delay)
);

delay #(
    .DATA_WIDTH(10),
    .DELAY_TIME(1)
) 
U_dealy_y(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(r_y),
    .o_data(w_y_delay)
);

delay #(
    .DATA_WIDTH(10),
    .DELAY_TIME(1)
) 
U_dealy_cb(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(r_cb),
    .o_data(w_cb_delay)
);

//Outside Assign
assign o_sync_h = w_sync_h_delay;
assign o_sync_v = w_sync_v_delay;
assign o_y  = w_y_delay;
assign o_cb = w_cb_delay;
assign o_cr = r_cr;

assign o_sync_h_count = w_sync_h_count_delay;
assign o_sync_v_count = w_sync_v_count_delay;

endmodule