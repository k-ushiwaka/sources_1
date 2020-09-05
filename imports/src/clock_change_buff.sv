module clock_change_buff(
    input   i_write_clk,    // 200MHz
    input   i_read_clk,     // 125MHz
    input   i_rst,
    
    input           i_write_valid,
    input   [14:0]  i_data_byte,
    input   [7:0]   i_row_number,
    input   [7:0]   i_rgb_data,

    input           i_eth_busy,           

    output           o_write_valid,
    output   [14:0]  o_data_byte,
    output   [7:0]   o_row_number,
    output   [7:0]   o_rgb_data,
    output           o_sof,
    output           o_full,
    output           o_packet_last   
);
    logic   [14:0]      r_data_byte;
    logic   [14:0]      r_data_byte_remain;
    logic   [7:0]       r_row_number;
    logic   [7:0]       r_rgb_data;  

    logic               r_read_enable;
    logic               w_read_enable_delay;
    logic   [1:0]       r_valid_edge;
    logic   [1:0]       r_packet_edge;
    logic               w_full;
    logic               w_empty;

    logic               r_packet_make_flag;
    logic   [14:0]      r_udp_data_byte;
    logic               r_byte_def_flag;
    logic   [14:0]      r_read_count;
    logic               r_packet_last;
    logic   [1:0]       r_read_enable_edge;

//GG  generate FIFO GG//
    generate_clock_change_fifo U_generate_clock_change_fifo(
        .rst        (i_rst),                 
        .wr_clk     (i_write_clk),           
        .rd_clk     (i_read_clk),           
        .din        (i_rgb_data),                 
        .wr_en      (i_write_valid),             
        .rd_en      (r_read_enable),             
        .dout       (r_rgb_data),               
        .full       (),               
        .empty      (),
        .almost_empty(w_empty),             
        .prog_full  (w_full),     
        .prog_empty (),   
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

//  Read Flag Control //
    always_ff@(posedge i_read_clk)begin
        if(i_rst)                       r_read_enable <= 1'b0;
        else if(r_packet_make_flag)     r_read_enable <= 1'b1;
        else                            r_read_enable <= 1'b0;    
    end

// Valid Edge //
    always_ff@(posedge i_write_clk)begin
        if(i_rst)           r_valid_edge <= 2'b00;
        else begin
                            r_valid_edge[0] <= i_write_valid;
                            r_valid_edge[1] <= r_valid_edge[0];
        end
    end

// data_byte & row_number Catch
    always_ff@(posedge i_write_clk)begin
        if(i_rst)                       r_row_number <=  8'hff;
        else if(r_valid_edge == 2'b01)  r_row_number <= i_row_number;
        else                            r_row_number <= r_row_number;
    end

    always_ff@(posedge i_write_clk)begin
        if(i_rst)                       r_data_byte  <= 15'd0;
        else if(r_valid_edge == 2'b01)  r_data_byte  <= i_data_byte ;
        else                            r_data_byte  <= r_data_byte ;
    end

    always_ff@(posedge i_read_clk)begin
        if(i_rst)begin
            r_data_byte_remain  <= 15'd0;
            r_udp_data_byte     <= 15'd0;
        end
        else if(r_packet_edge == 2'b01)begin
            if( r_data_byte_remain != 15'd0)begin
                if(r_data_byte_remain  <  15'd1470)begin
                    r_data_byte_remain <= 15'd0;
                    r_udp_data_byte    <= r_data_byte_remain;
                end
                else begin
                    r_data_byte_remain <= r_data_byte_remain - 15'd1410;
                    r_udp_data_byte <= 15'd1410;
                end
            end
            else begin
                if(r_data_byte  <  15'd1470)begin
                    r_data_byte_remain <= 15'd0;
                    r_udp_data_byte    <= r_data_byte;
                end
                else begin
                    r_data_byte_remain <= r_data_byte - 15'd1410;
                    r_udp_data_byte <= 15'd1410;
                end
            end
        end
        else if(~w_full && ~i_eth_busy)begin
            r_data_byte_remain  <= 15'd0;
            r_udp_data_byte     <= 15'd0;
        end
        else begin
            r_data_byte_remain     <= r_data_byte_remain ;
            r_udp_data_byte <= r_udp_data_byte;
        end
    end

// r_packet_make_flag Control
    always_ff@(posedge i_read_clk)begin
        if(i_rst)   r_packet_make_flag <= 1'b0;
        else if(w_full && ~i_eth_busy)                  r_packet_make_flag <= 1'b1;
        else if(r_read_count < r_udp_data_byte - 1'b1)  r_packet_make_flag <= r_packet_make_flag;
        else        r_packet_make_flag <= 1'b0;
    end
    always_ff@(posedge i_read_clk)begin
        if(i_rst)           r_packet_edge <= 2'b00;
        else begin
                            r_packet_edge[0] <= r_packet_make_flag;
                            r_packet_edge[1] <= r_packet_edge[0];
        end
    end
    always_ff@(posedge i_read_clk)begin
        if(i_rst)                   r_read_count <= 15'd0;
        else if(r_packet_make_flag) r_read_count <= r_read_count + 1'b1;
        else                        r_read_count <= 15'd0;
    end
// Packet Last Flag
    always_ff@(posedge i_read_clk)begin
        if(i_rst)   r_read_enable_edge <= 2'b00;
        else begin
                    r_read_enable_edge[0] <= r_packet_make_flag;
                    r_read_enable_edge[1] <= r_read_enable_edge[0];
        end
    end
    always_ff@(posedge i_read_clk)begin
        if(i_rst)                   r_packet_last <= 1'd0;
        else if(r_data_byte_remain == 15'd0 && r_read_enable_edge == 2'b10 &&r_row_number == 8'd89) r_packet_last <= 1'b1;
        else                        r_packet_last <= 1'd0;
    end

//>>  Output Assign >>//
    assign o_data_byte  = r_udp_data_byte;
    assign o_row_number = r_row_number;
    assign o_rgb_data   = r_rgb_data;
    assign o_write_valid= w_read_enable_delay;
    assign o_sof        = (r_row_number==8'h00);
    assign o_full       = w_full;
    assign o_packet_last= r_packet_last;

endmodule