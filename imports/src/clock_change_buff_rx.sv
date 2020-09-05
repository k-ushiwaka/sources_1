module clock_change_buff_rx(
    input   i_rx_clk,       // 125MHz
    input   i_read_clk,     // 200MHz
    input   i_rst,
    
    input           i_write_valid,
    input   [7:0]   i_rgb_data,
    input           i_sof,
    input   [15:0]  i_data_length,

    output           o_write_valid,
    output           o_sof,
    output   [7:0]   o_rgb_data   
);
    logic   [15:0]      r_data_length;
    logic   [15:0]      w_data_thoreshould;
    logic   [8:0]       r_rgb_data;  
    logic   [9:0]       w_wr_data_count;
    logic               r_read_enable;
    logic               w_read_enable_delay;
    logic   [1:0]       r_valid_edge;
    logic               w_empty;

//GG  generate FIFO GG//
    generate_fifo_rx_clk_change U_generate_fifo_rx_clk_change(
        .rst        (i_rst),                 
        .wr_clk     (i_rx_clk),           
        .rd_clk     (i_read_clk),           
        .din        ({i_sof,i_rgb_data}),                 
        .wr_en      (i_write_valid),             
        .rd_en      (r_read_enable),             
        .dout       (r_rgb_data),               
        .full       (),               
        .empty      (w_empty),
        .wr_data_count(w_wr_data_count),
        .wr_rst_busy(), 
        .rd_rst_busy()  
    );
//DD Delay DD//
    delay #(
        .DATA_WIDTH(1),
        .DELAY_TIME(1)
    )
    U_delay_valid(
        .i_clk(i_read_clk),
        .i_rst(i_rst),
        .i_data(r_read_enable),
        .o_data(w_read_enable_delay)
    );

// Valid Edge //
    always_ff@(posedge i_rx_clk)begin
        if(i_rst)           r_valid_edge <= 2'b00;
        else begin
                            r_valid_edge[0] <= i_write_valid;
                            r_valid_edge[1] <= r_valid_edge[0];
        end
    end
// Data Size & read Thoreshould//
    always_ff@(posedge i_rx_clk)begin
        if(i_rst)                       r_data_length <= 16'd0;
        else if(r_valid_edge ==2'b01)   r_data_length <= i_data_length;
        else                            r_data_length <= r_data_length;
    end
    assign w_data_thoreshould = ((r_data_length * 3) >> 3) +16'd10;

// Read Valid //
    always_ff@(posedge i_read_clk)begin
        if(i_rst)                                           r_read_enable <= 1'b0;
        else if(w_data_thoreshould == w_wr_data_count)      r_read_enable <= 1'b1;
        else if(w_empty)                                    r_read_enable <= 1'b0;
        else                                                r_read_enable <= r_read_enable;
    end

//>>  Output Assign >>//
    assign o_rgb_data   = r_rgb_data[7:0];
    assign o_sof        = r_rgb_data[8];
    assign o_write_valid= w_read_enable_delay & r_read_enable;
endmodule