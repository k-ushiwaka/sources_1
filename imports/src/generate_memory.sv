module generate_memory#(
    parameter M_DEPTH = 11,
    parameter M_WIDTH = 32,
    parameter FULL_NUM = 2048,
    parameter SELECT = 1,
    parameter COUNT = 0
)
(
    input                   i_rst,
    // Write Signal
    input                   i_write_clk,
    input                   i_write_enable,
    input   [M_WIDTH-1 : 0] i_write_data,

    // Read Signal
    input                   i_read_clk,
    input                   i_read_enable,
    output  [M_WIDTH-1 : 0] o_read_data,
    output                  o_read_data_valid,  

    //Others This is (write or read) sync signal of a number of data 
    output  [M_DEPTH-1 : 0] o_write_num,
    output  [M_DEPTH-1 : 0] o_read_num,

    // Flag
    output                  o_empty,
    output                  o_full
);

//local signal
logic                   r_write_enable;
logic                   r_read_enable;
logic[M_WIDTH-1 : 0]    r_write_data;
logic[M_DEPTH-1 : 0]    r_write_addres;
logic[M_DEPTH-1 : 0]    r_read_addres;
logic                   w_write_taboo;      // out data boder 
logic                   w_read_taboo;       // out data boder 
logic[M_WIDTH-1 : 0]    w_read_data;
logic                   r_empty;
logic                   r_full;
logic  [M_DEPTH-1 : 0]  r_write_num;
logic  [M_DEPTH-1 : 0]  r_read_num;

//Memory
generate
    if(SELECT == 1)
        generate_ram U_generate_ram_32_11(
        .clka(i_write_clk),                 // input wire clka
        .ena(i_write_enable && !r_full),    // input wire ena
        .wea(1'b1),                         // input wire [0 : 0] wea
        .addra(r_write_addres),             // input wire [10 : 0] addra
        .dina(i_write_data),                // input wire [31 : 0] dina
        .clkb(i_read_clk),                  // input wire clkb
        .enb(i_read_enable),                // input wire enb
        .addrb(r_read_addres),              // input wire [10 : 0] addrb
        .doutb(w_read_data)                 // output wire [31 : 0] doutb
        );
    else if(SELECT == 2)
        generate_ram_288_8 U_generate_ram_288_8 (
        .clka(i_write_clk),                  // input wire clka
        .ena(i_write_enable && !r_full),     // input wire ena
        .wea(1'b1),                          // input wire [0 : 0] wea
        .addra(r_write_addres),              // input wire [7 : 0] addra
        .dina(i_write_data),                 // input wire [287 : 0] dina
        .clkb(i_read_clk),                   // input wire clkb
        .enb(i_read_enable),                 // input wire enb
        .addrb(r_read_addres),               // input wire [7 : 0] addrb
        .doutb(w_read_data)                  // output wire [287 : 0] doutb
        );
    else if(SELECT == 3)
        generate_ram_2_8 U_generate_ram_2_8 (
        .clka(i_write_clk),                    // input wire clka
        .ena(i_write_enable && !r_full),       // input wire ena
        .wea(1'b1),                            // input wire [0 : 0] wea
        .addra(r_write_addres),                // input wire [7 : 0] addra
        .dina(i_write_data),                   // input wire [1 : 0] dina
        .clkb(i_read_clk),                     // input wire clkb
        .enb(i_read_enable),                   // input wire enb
        .addrb(r_read_addres),                 // input wire [7 : 0] addrb
        .doutb(w_read_data)                   // output wire [1 : 0] doutb
        );
endgenerate
//Wire Signal
assign w_write_taboo = (r_write_addres + 1'b1 == r_read_addres);
assign w_read_taboo  = (r_read_addres == r_write_addres);

//Enable&Data register
always_ff@(posedge i_write_clk)begin
    r_write_enable <= i_write_enable;
end
always_ff@(posedge i_write_clk)begin
    r_write_data <= i_write_data;
end
always_ff@(posedge i_read_clk)begin
    r_read_enable <= i_read_enable;
end

// Addres FF
always_ff@(posedge i_write_clk)begin
    if(i_rst)                                   r_write_addres <= {M_DEPTH{1'b0}};
    else if(w_write_taboo)                      r_write_addres <= r_write_addres;
    else if(i_write_enable) begin
        if(r_write_addres  == {M_DEPTH{1'b1}})  r_write_addres <= {M_DEPTH{1'b0}}; 
        else                                    r_write_addres <= r_write_addres + 1'b1;
    end
    else                                        r_write_addres <= r_write_addres;
end

always_ff@(posedge i_read_clk)begin
    if(i_rst)                                   r_read_addres <= {M_DEPTH{1'b0}};
    else if(w_read_taboo)                       r_read_addres <= r_read_addres;
    else if(i_read_enable) begin
        if(r_read_addres  == {M_DEPTH{1'b1}})   r_read_addres <= {M_DEPTH{1'b0}}; 
        else                                    r_read_addres <= r_read_addres + 1'b1;
    end
    else                                        r_read_addres <= r_read_addres;
end

//Flag FF
always_ff@(posedge i_read_clk)begin
    if(i_rst)               r_empty <= 1'b1;
    else                    r_empty <= w_read_taboo;
end
always_ff@(posedge i_write_clk)begin
    if(i_rst)               r_full <= 1'b1;
    else                    r_full <= w_write_taboo;
end

// Data FF
//always_ff@(posedge i_write_clk)begin
//    if(i_write_enable && !r_full)  r_memory[r_write_addres] <= i_write_data;
//end
//always_ff@(posedge i_read_clk)begin
//    if(i_read_enable)   r_read_data <= r_memory[r_read_addres];
//end

//Counter Generate
generate
    if(COUNT)begin
        always_comb begin
            if(i_rst)   r_read_num <= {M_DEPTH{1'b0}};
            else if(r_write_addres > r_read_addres) r_read_num <= r_write_addres - r_read_addres;
            else if(r_write_addres < r_read_addres) r_read_num <= (12'd2048 - r_read_addres) + r_write_addres;
            else        r_read_num <= {M_DEPTH{1'b0}};
        end
    end
endgenerate

function [M_DEPTH-1 : 0]   read_num;
    input [M_DEPTH-1:0] write_addres;
    input [M_DEPTH-1:0] read_addres;
    if(write_addres > read_addres) read_num <= write_addres - read_addres;
    else if(write_addres < read_addres) read_num <= (12'd2048 - read_addres) + write_addres;
    else        read_num <= {M_DEPTH{1'b0}};
endfunction

//Outside Assign
assign o_empty      = r_empty;
assign o_full       = r_full;
assign o_read_data  = w_read_data;
assign o_read_data_valid = r_read_enable && (!r_empty);
assign o_write_num  = 11'd0;
assign o_read_num   = r_read_num;//read_num(r_write_addres,r_read_addres);

endmodule