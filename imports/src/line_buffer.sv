`timescale 1ns / 1ps
module line_buffer#(
    parameter M_DEPTH = 11,
    parameter M_WIDTH = 32,
    parameter IMG_W = 1920,
    parameter FULL_NUM = 2048,
    parameter LINE_NUM = 12
)
(
    //system signal
    input   i_write_clk,
    input   i_read_clk,
    input   i_rst,

    //input
    input                           i_sync_h,
    input                           i_sync_v,
    input  [7:0]   i_r,
    input  [7:0]   i_g,
    input  [7:0]   i_b,

    //output
    output                          o_data_valid,
    output  [M_DEPTH-1 : 0]         o_h_count,
    output  [M_DEPTH-1 : 0]         o_v_count,                          
    output  [LINE_NUM-1 : 0][7:0]   o_r,
    output  [LINE_NUM-1 : 0][7:0]   o_g,
    output  [LINE_NUM-1 : 0][7:0]   o_b
);

//local signal

wire    [LINE_NUM-1 : 0][7 : 0] w_read_data_kara;
wire    [LINE_NUM-1 : 0][7 : 0] w_read_data_r;
wire    [LINE_NUM-1 : 0][7 : 0] w_read_data_g;
wire    [LINE_NUM-1 : 0][7 : 0] w_read_data_b;
wire    [LINE_NUM-1 : 0]                w_empty;
wire    [LINE_NUM-1 : 0]                w_full;

logic   [1:0]               r_sync_h_edge;
logic   [1:0]               r_sync_v_edge;

logic   [M_DEPTH-1 : 0]     r_sync_h_count_write;
logic   [M_DEPTH-1 : 0]     r_sync_v_count_write;

logic   [M_DEPTH-1 : 0]     r_sync_h_count_read;
logic   [M_DEPTH-1 : 0]     r_sync_v_count_read;

// Debug
//// 0bit : empty_flag
//// 1bit : Writing (write_enable)
//// 2bit : 1 line stocked
//// 3bit : Reading (read_enable) 
//// 4bit : full_flag
logic   [LINE_NUM-1 : 0]    r_line_status;

wire    [LINE_NUM-1 : 0]    w_write_enable;
wire    [LINE_NUM-1 : 0]    w_write_enable_delay; //2 clock delay
logic    [3 : 0]            r_write_enable_count;
logic                       r_read_enable;
wire                        w_read_enable_delay;

logic   [3:0]               r_read_start_edge;
logic   [3:0]               r_read_finish_edge;

// generate
generate
    genvar i;
    for(i = 0 ; i < LINE_NUM ; i++)begin : LINE_GENERATE
        generate_memory#(
            .M_DEPTH(M_DEPTH),
            .M_WIDTH(M_WIDTH),
            .FULL_NUM(FULL_NUM)
        )
        U_generate_memory
        (
            .i_rst          (i_rst),
            .i_write_clk    (i_write_clk),
            .i_write_enable (w_write_enable[i]),
            .i_write_data   ({8'h00,i_r,i_g,i_b}),
            .i_read_clk     (i_read_clk),
            .i_read_enable  (r_read_enable),
            .o_read_data    ({w_read_data_kara[i],w_read_data_r[i],w_read_data_g[i],w_read_data_b[i]}),  
            .o_write_num    (),
            .o_read_num     (),
            .o_empty        (w_empty[i]),
            .o_full         (w_full[i])
        );
    end
endgenerate

// FF

//- H,V Edge FF
always_ff@(posedge i_write_clk)begin
    if(i_rst)       r_sync_h_edge <= 2'b00;
    else if (i_sync_v) begin
                    r_sync_h_edge[0] <= i_sync_h;
                    r_sync_h_edge[1] <= r_sync_h_edge[0];
    end
    else            r_sync_h_edge <= 2'b00;
end
always_ff@(posedge i_write_clk)begin
    if(i_rst)     r_sync_v_edge <= 2'b00;
    else begin
                r_sync_v_edge[0] <= i_sync_v;
                r_sync_v_edge[1] <= r_sync_v_edge[0];
    end
end
//- H,V,enable counter
always_ff@(posedge i_write_clk)begin
    if(i_rst)                             r_sync_h_count_write <= {M_DEPTH{1'b0}};
    else if(r_sync_h_count_write == 11'd1919) r_sync_h_count_write <= {M_DEPTH{1'b0}};
    else if(i_sync_v)     r_sync_h_count_write <= r_sync_h_count_write + 1'b1;
    else                                r_sync_h_count_write <= r_sync_h_count_write;
end
always_ff@(posedge i_write_clk)begin
    if(i_rst)                             r_sync_v_count_write <= {M_DEPTH{1'b0}};
    else if(r_sync_v_count_write == 11'd1079) r_sync_v_count_write <= {M_DEPTH{1'b0}};
    else if(r_sync_h_edge == 2'b10)     r_sync_v_count_write <= r_sync_v_count_write + 1'b1;
    else                                r_sync_v_count_write <= r_sync_v_count_write;
end

always_ff@(posedge i_write_clk)begin
    if(i_rst)                               r_write_enable_count <= 4'b0000;
    else if(r_write_enable_count == 4'd12)  r_write_enable_count <= 4'b0000;
    else if(r_sync_h_edge == 2'b10)         r_write_enable_count <= r_write_enable_count + 1'b1;
    else                                    r_write_enable_count <= r_write_enable_count;
end

//- Line stock Flag
always_ff@(posedge i_write_clk)begin
    int j;
    if(i_rst)                               r_line_status <= {LINE_NUM{1'b0}};
    else if(r_read_start_edge == 4'b0001 || r_read_start_edge == 4'b0011 || r_read_start_edge == 4'b0111)begin
                                            r_line_status <= {LINE_NUM{1'b0}};   
    end
    else if(r_sync_h_edge == 2'b10)begin
        for (j =0;j< LINE_NUM;j= j+1)begin
            if(w_write_enable_delay[j])     r_line_status[j] <= 1'b1;
            else                            r_line_status[j] <= r_line_status[j];
        end
    end
    else                                    r_line_status <= r_line_status;
end

// - Read Method
always_ff@(posedge i_read_clk)begin
    if(i_rst)                                   r_read_enable <= 1'b0;
    else if(r_sync_h_count_read == 11'd1918)    r_read_enable <= 1'b0;
    else if(r_line_status == {LINE_NUM{1'b1}})  r_read_enable <= 1'b1;
    else                                        r_read_enable <= r_read_enable;
end
always_ff@(posedge i_read_clk)begin
    if(i_rst)                                       r_sync_h_count_read <= {M_DEPTH{1'b0}};
    else if(w_read_enable_delay)begin
        if(r_sync_h_count_read == 11'd1919)    r_sync_h_count_read <= {M_DEPTH{1'b0}};
        else                                        r_sync_h_count_read <= r_sync_h_count_read + 1'b1;
    end
    else                                            r_sync_h_count_read <= r_sync_h_count_read;
end
always_ff@(posedge i_read_clk)begin
    if(i_rst)                                       r_sync_v_count_read <= {M_DEPTH{1'b0}};
    else if(r_sync_h_count_read == 11'd1919)begin        
        if(r_sync_v_count_read == 11'd1068)         r_sync_v_count_read <= {M_DEPTH{1'b0}};
        else                                        r_sync_v_count_read <= r_sync_v_count_read + LINE_NUM;
    end
    else                                            r_sync_v_count_read <= r_sync_v_count_read;
end
always_ff@(posedge i_read_clk)begin
    if(i_rst)   r_read_start_edge <= 4'b0000;
    else begin
                r_read_start_edge[0] <= r_read_enable;
                r_read_start_edge[1] <= r_read_start_edge[0];
                r_read_start_edge[2] <= r_read_start_edge[1];
                r_read_start_edge[3] <= r_read_start_edge[2];
    end
end

//function

//- write line select (enable signal control)
function [LINE_NUM-1 : 0] write_line_select(input[3 : 0] count , input valid);
begin
    if(valid)begin
        case(count)
        4'd0:    write_line_select = 12'h001;
        4'd1:    write_line_select = 12'h002;
        4'd2:    write_line_select = 12'h004;
        4'd3:    write_line_select = 12'h008;
        4'd4:    write_line_select = 12'h010;
        4'd5:    write_line_select = 12'h020;
        4'd6:    write_line_select = 12'h040;
        4'd7:    write_line_select = 12'h080;
        4'd8:    write_line_select = 12'h100;
        4'd9:    write_line_select = 12'h200;
        4'd10:   write_line_select = 12'h400;
        4'd11:   write_line_select = 12'h800;
        default:    write_line_select = 12'h000; 
        endcase
    end
    else            write_line_select = {LINE_NUM{1'b0}};
end
endfunction

//Delay
delay #(
    .DATA_WIDTH(LINE_NUM),
    .DELAY_TIME(2)
)
U_delay_write_enable(
    .i_clk(i_write_clk),
    .i_rst(i_rst),
    .i_data(w_write_enable),
    .o_data(w_write_enable_delay)
);
//Delay
delay #(
    .DATA_WIDTH(1),
    .DELAY_TIME(1)
)
U_delay_read_enable(
    .i_clk(i_read_clk),
    .i_rst(i_rst),
    .i_data(r_read_enable),
    .o_data(w_read_enable_delay)
);
//Assign

//- inside
assign w_write_enable = write_line_select(r_write_enable_count,i_sync_h&i_sync_v);

//- outside
assign o_data_valid = w_read_enable_delay;
assign o_h_count = r_sync_h_count_read;
assign o_v_count = r_sync_v_count_read;
assign o_r = w_read_data_r;
assign o_g = w_read_data_g;
assign o_b = w_read_data_b;;

endmodule