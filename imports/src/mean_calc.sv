`timescale 1ns / 1ps
module mean_calc#(
    parameter M_DEPTH = 11,
    parameter M_WIDTH = 32,
    parameter IMG_W = 1920,
    parameter FULL_NUM = 2048,
    parameter LINE_NUM = 12
)
(
    //system signal
    input   i_clk,
    input   i_rst,

    //input
    input                           i_data_valid,
    input  [M_DEPTH-1 : 0]          i_h_count,
    input  [M_DEPTH-1 : 0]          i_v_count,
    input  [LINE_NUM-1 : 0][7:0]    i_data,
    input  [1:0]                    i_rank,
    //output
    output                          o_data_valid,
    output  [1:0]                   o_rank,
    output                          o_sync_h,
    output  [(LINE_NUM*8)-1 : 0]   o_data
);

//local signal
logic                                   r_data_valid;
logic                                   r_data_valid_delay;
logic                                   r_data_valid_delay_delay;
logic   [4 : 0][LINE_NUM-1 : 0][7:0]    r_data;
logic   [1:0]                           r_rank;
logic   [1:0]                           r_rank_delay;
logic   [95:0]                          r_select_data;

logic   [5:0][7:0]                      r_data_1_4;
logic   [3:0][7:0]                      r_data_1_9;
logic   [2:0][7:0]                      r_data_1_16;
logic                                   r_valid_1_4;
logic                                   r_valid_1_9;
logic                                   r_valid_1_16;
logic                                   r_out_valid;
//logic                                   r_valid_1_4_delay;
//logic                                   r_valid_1_9_delay;


logic   [3:0]       r_count_12;
wire                w_flag_1_9;

//delay
delay #(
    .DATA_WIDTH(1),
    .DELAY_TIME(3)
) 
U_dealy_valid(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(i_data_valid),
    .o_data(r_data_valid)
);
delay #(
    .DATA_WIDTH(1),
    .DELAY_TIME(5)
) 
U_dealy_valid_out(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(i_data_valid),
    .o_data(r_data_valid_delay)
);
delay #(
    .DATA_WIDTH(1),
    .DELAY_TIME(1)
) 
U_dealy_valid_out_delay(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(r_data_valid_delay),
    .o_data(r_data_valid_delay_delay)
);

delay #(
    .DATA_WIDTH(2),
    .DELAY_TIME(1)
) 
U_dealy_rank(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(r_rank),
    .o_data(r_rank_delay)
);

//FF
always_ff@(posedge i_clk)begin
    if(i_rst)   r_count_12 <= 4'b0000;
    else if(r_data_valid)begin
        if(r_count_12 == 4'd11)   r_count_12 <= 4'b0000;
        else                    r_count_12 <= r_count_12 + 1'b1;
    end
    else        r_count_12 <= r_count_12;
end

always_ff@(posedge i_clk)begin
    if(i_rst)   r_rank <= 2'bzz;
    else if(r_count_12 == 4'd01)    r_rank <= i_rank;
    else                            r_rank <= r_rank;
end

always_ff@(posedge i_clk)begin
    if(i_rst)   r_data <={3*LINE_NUM*8{1'b0}};
    else begin
                int i;
                r_data[0] <= i_data;
                for(i = 1;i<5;i++)begin
                    r_data[i] <= r_data[i-1];
                end
    end 
end
// calc 1/4 
always_ff@(posedge i_clk)begin
    if(i_rst)begin
        r_data_1_4 <= {6*8{1'b0}};
        r_valid_1_4 <= 1'b0;    
    end
    else if(r_count_12[0] == 1'b1 )begin
        for(int i = 0 ; i< 6 ; i++)begin
            r_valid_1_4 <= 1'b1;
            r_data_1_4[i] <= (   r_data[1][(i*2)+0] + r_data[2][(i*2)+0]+
                                r_data[1][(i*2)+1] + r_data[2][(i*2)+1]+ 2'b10 ) / 4 ;
        end 
    end
    else begin        
        r_valid_1_4 <= 1'b0;
        r_data_1_4 <= r_data_1_4;
    end
end

// calc 1/9 
always_ff@(posedge i_clk)begin
    if(i_rst)begin
       r_data_1_9 <= {4*8{1'b0}};
       r_valid_1_9 <= 1'b0;
    end
    else if(w_flag_1_9)begin
        for(int i = 0 ; i< 4 ; i++)begin
            r_valid_1_9 <= 1'b1;
            r_data_1_9[i] <= (   r_data[0][(i*3)+0] + r_data[1][(i*3)+0] + r_data[2][(i*3)+0] + 
                                r_data[0][(i*3)+1] + r_data[1][(i*3)+1] + r_data[2][(i*3)+1] +
                                r_data[0][(i*3)+2] + r_data[1][(i*3)+2] + r_data[2][(i*3)+2] + 3'b100)/9;
        end 
    end
    else begin
        r_data_1_9 <= r_data_1_9;
        r_valid_1_9 <= 1'b0;
    end
end

// calc 1/16 
always_ff@(posedge i_clk)begin
    if(i_rst)begin
       r_data_1_16 <= {3*8{1'b0}};
       r_valid_1_16 <= 1'b0;
    end
    else if(r_count_12[1:0] == 2'b01 )begin
        for(int i = 0 ; i< 3 ; i++)begin
            r_valid_1_16 <= 1'b1;
            r_data_1_16[i] <= (  r_data[0][(i*4)+0] + r_data[1][(i*4)+0] + r_data[2][(i*4)+0] + r_data[3][(i*4)+0] +
                                r_data[0][(i*4)+1] + r_data[1][(i*4)+1] + r_data[2][(i*4)+1] + r_data[3][(i*4)+1] +
                                r_data[0][(i*4)+2] + r_data[1][(i*4)+2] + r_data[2][(i*4)+2] + r_data[3][(i*4)+2] +
                                r_data[0][(i*4)+3] + r_data[1][(i*4)+3] + r_data[2][(i*4)+3] + r_data[3][(i*4)+3] + 4'b1000)/ 16;
        end 
    end
    else begin
        r_data_1_16 <= r_data_1_16;
        r_valid_1_16 <= 1'b0;
    end
end

assign w_flag_1_9 = (r_count_12 == 4'b0001 || r_count_12 == 4'b0100 ||r_count_12 == 4'b0111 ||r_count_12 == 4'b1010);

//function
function [95 : 0]   select_data(input [1:0]                 rank,
                                input [LINE_NUM-1 : 0][7:0] data_1_1,
                                input [5:0][7:0]            data_1_4,
                                input [3:0][7:0]            data_1_9,
                                input [2:0][7:0]            data_1_16);
    case(rank)
        2'b00:      select_data = data_1_1;
        2'b01:      select_data = {48'd0,data_1_4};
        2'b10:      select_data = {64'd0,data_1_9};
        2'b11:      select_data = {72'd0,data_1_16};
        default:    select_data = 96'd0;
    endcase
endfunction
    always_ff@(posedge i_clk)begin
        if(i_rst)   r_select_data <= 96'd0;
        else begin
            case(r_rank)
                2'b00:      r_select_data = r_data[4];
                2'b01:      r_select_data = {48'd0,r_data_1_4};
                2'b10:      r_select_data = {64'd0,r_data_1_9};
                2'b11:      r_select_data = {72'd0,r_data_1_16};
                default:    r_select_data = 96'd0;
            endcase
        end
    end
    always_ff@(posedge i_clk)begin
        if(i_rst)   r_out_valid <= 1'd0;
        else begin
            case(r_rank)
                2'b00:      r_out_valid = r_data_valid_delay;
                2'b01:      r_out_valid = r_valid_1_4;
                2'b10:      r_out_valid = r_valid_1_9;
                2'b11:      r_out_valid = r_valid_1_16;
                default:    r_out_valid = 1'd0;
            endcase
        end
    end
//Outside Assign
// assign o_data = (i_rank == 2'b00)? {r_data[3]}:
//                 (i_rank == 2'b01)? {48'd0,r_data_1_4}:
//                 (i_rank == 2'b10)? {32'd0,r_data_1_9}:
//                                    {24'd0,r_data_1_16};
// assign o_data = select_data(r_rank,r_data[4],r_data_1_4,r_data_1_9,r_data_1_16);
assign o_data = r_select_data;
assign o_rank = r_rank_delay;
// assign o_data_valid =   (r_rank == 2'b00)? r_data_valid_delay:
//                         (r_rank == 2'b01)? r_valid_1_4:
//                         (r_rank == 2'b10)? r_valid_1_9:
//                                            r_valid_1_16;
assign o_data_valid = r_out_valid;
assign o_sync_h = r_data_valid_delay_delay;
endmodule