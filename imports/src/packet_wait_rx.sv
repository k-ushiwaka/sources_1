module packet_wait_rx#(
    DATA_BIT = 288,
    RANK_BIT = 2,
    ADDRES_BIT = 11,
    OUTPUT_DATA_BIT = 8,
    LINE_NUM = 12
)
(
    //system signal
    input   i_clk,
    input   i_rst,

    //input
    input  [1:0]                   i_rank,
    input                          i_data_valid,
    input                          i_sync_h,
    input  [(LINE_NUM*8*3)-1 : 0]  i_data,

    //output
    output              o_valid,
    output  [7:0]       o_data,
    output  [14:0]      o_data_byte,
    output  [7:0]       o_row_number
);
// enam
enum  {INIT,STACK,HEAD,READ,SHIFT,LAST1,LAST2}state,next;

//logic
logic   [36-1 : 0][7:0]         w_read_data;
logic   [36-1 : 0][7:0]         r_read_data;
logic   [OUTPUT_DATA_BIT-1 : 0] r_output_data;
logic   [RANK_BIT-1 : 0]        w_read_rank;
logic   [1:0]                   r_rgb_switch_counter;
logic   [5:0]                   r_data_shift_counter;
logic   [5:0]                   r_count_max;
logic   [5:0]                   w_addres;
logic                           r_valid;
logic   [14:0]                  r_data_byte;
logic   [7:0]                   r_row_number;
logic   [7:0]                   r_trans_count;
logic   [7:0]                   r_trans_threshuld;
//flag
wire    w_fifo_empty;
wire    w_read_enable;
wire    w_next_read_flag;
wire    w_fifo_empty_delay;

logic r_read_enable;

 delay #(
        .DATA_WIDTH(1),
        .DELAY_TIME(9)
    )
    U_delay_valid(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(w_fifo_empty),
        .o_data(w_fifo_empty_delay)
    );
generate_memory#(
        .M_DEPTH(ADDRES_BIT),
        .M_WIDTH(DATA_BIT),
        .FULL_NUM(2048),
        .SELECT(2)
    )
    U_generate_memory_data
    (
        .i_rst          (i_rst),
        .i_write_clk    (i_clk),
        .i_write_enable (i_data_valid&i_sync_h),
        .i_write_data   (i_data),
        .i_read_clk     (i_clk),
        .i_read_enable  (w_read_enable),
        .o_read_data    (w_read_data),  
        .o_write_num    (),
        .o_read_num     (),
        .o_empty        (w_fifo_empty),
        .o_full         ()
    );

generate_memory#(
        .M_DEPTH(ADDRES_BIT),
        .M_WIDTH(RANK_BIT),
        .FULL_NUM(2048),
        .SELECT(3)
    )
    U_generate_memory_rank
    (
        .i_rst          (i_rst),
        .i_write_clk    (i_clk),
        .i_write_enable (i_data_valid&i_sync_h),
        .i_write_data   (i_rank),
        .i_read_clk     (i_clk),
        .i_read_enable  (w_read_enable),
        .o_read_data    (w_read_rank),  
        .o_write_num    (),
        .o_read_num     (),
        .o_empty        (),
        .o_full         ()
    );


///////////////////READ
// State Machine
always_ff @(posedge i_clk)begin
    if(i_rst)   state <= INIT;
    else        state <= next;
end
always_comb begin: read_state
    next = state;         //default
    unique case(state)
        INIT     :  if(i_sync_h)   next = STACK;
        STACK    :  if(!i_sync_h)  next = READ;
        READ     :  next = SHIFT;
        SHIFT    :  begin
                        if(w_next_read_flag)begin
                            if      (w_fifo_empty)     next = LAST1;
                            else                       next = READ;
                        end
                    end
        LAST1    :  next = INIT;
        LAST2    :  next = INIT;
    endcase
end
//// Trans Count
    always_ff@(posedge i_clk)begin
        if      (state == INIT || state == READ)   r_trans_count <= 8'd0;
        else if (state == SHIFT)                   r_trans_count <= r_trans_count + 8'd1; 
    end
    // always_ff@(posedge i_clk)begin
    //     if      (state == INIT || state == READ)   r_trans_threshuld <= 8'hff;
    //     else if (state == READ)begin
    //         case(w_read_rank)
    //                 2'b00:  r_trans_threshuld <= 8'd36;
    //                 2'b01:  r_trans_threshuld <= 8'd18;
    //                 2'b10:  r_trans_threshuld <= 8'd12;
    //                 2'b11:  r_trans_threshuld <= 8'd9;
    //                 default:r_trans_threshuld <= 8'd35;
    //     endcase
    //     end                    
    // end

////r_data_shift_counter MAX
always_ff@(posedge i_clk)begin
    if(i_rst)      r_count_max <= 6'b111111;
    else if(state == READ)begin
        case(w_read_rank)
            2'b00: r_count_max <= 6'd35;
            2'b01: r_count_max <= 6'd17;
            2'b10: r_count_max <= 6'd11;
            2'b11: r_count_max <= 6'd8;
            default:r_count_max <= 6'd35;
        endcase
    end
    else           r_count_max <= r_count_max;
end

always_ff@(posedge i_clk)begin
    if(i_rst)               r_data_shift_counter <= 4'b0000;
    else if(state == READ)  r_data_shift_counter <= 4'b0000;
    else if(state == SHIFT) r_data_shift_counter <= r_data_shift_counter + 1'b1;
    else                    r_data_shift_counter <= r_data_shift_counter;
end

//Read data buff
always_ff @(posedge i_clk)begin
    if(i_rst)   r_read_data <= {DATA_BIT{1'b0}};
    else if(state == READ)begin
        for(int i = 0;i < 12 ; i= i+1)begin
           r_read_data[i*3]   <= w_read_data[i];
           r_read_data[i*3+1] <= w_read_data[i+12];
           r_read_data[i*3+2] <= w_read_data[i+24];  
        end
    end
    else if(state == SHIFT)begin
        for(int i = 0; i< 35; i = i+1)begin
            r_read_data[i] <= r_read_data[i+1];
        end
        r_read_data[35] <= 8'd0;
    end
    else r_read_data <= {DATA_BIT{1'b0}};
end

always_ff @(posedge i_clk)begin
    if(i_rst)   r_output_data <= {OUTPUT_DATA_BIT{1'b0}};
    else if(state == READ||state == SHIFT)begin
       r_output_data <= r_read_data[0] ;
    end
    else        r_output_data <= {OUTPUT_DATA_BIT{1'b0}};
end

always_ff @(posedge i_clk)begin
    if(i_rst)               r_valid <= 1'b0;
    else if(state == INIT)  r_valid <= 1'b0;
    else if(state == SHIFT || state == LAST1 || state == LAST2) r_valid <= 1'b1;
    else                    r_valid <= r_valid;
end

//@@r_data_byte@@//
always_ff@(posedge i_clk)begin
    if(i_rst)               r_data_byte <= 15'd0;
    else if(i_data_valid&& next != READ)begin
        case(i_rank)
            2'b00:          r_data_byte <= r_data_byte + 6'd36;
            2'b01:          r_data_byte <= r_data_byte + 6'd18;
            2'b10:          r_data_byte <= r_data_byte + 6'd12;
            2'b11:          r_data_byte <= r_data_byte + 6'd9 ;
            default:;
        endcase
    end
    else if(next == INIT)  r_data_byte <= 15'd0;
    else                    r_data_byte <= r_data_byte;
end
//@@r_row_number@@//
always_ff@(posedge i_clk)begin
    if(i_rst)   r_row_number <= 8'hff;
    else if(state == INIT && next == STACK)begin
        if(r_row_number==8'd89)   r_row_number <= 8'd0;
        else                        r_row_number <= r_row_number + 1'd1;
    end
    else        r_row_number <= r_row_number;
end

// always_ff@(posedge i_clk)begin
//     if(i_rst)           r_read_enable <= 1'b0;
//     else if(r_data_shift_counter == r_count_max-1) r_read_enable <= 1'b1;
//     else if(next == READ)                          r_read_enable <= 1'b0;
//     else if(!i_sync_h && state == STACK)           r_read_enable <= 1'b1;
//     else                                           r_read_enable <= 1'b0;
// end


assign  w_read_enable = (next == READ);
assign  w_next_read_flag = (r_data_shift_counter == r_count_max-1);

assign  o_data  = r_output_data;
assign  o_valid = r_valid;
assign  o_data_byte = r_data_byte;
assign  o_row_number = r_row_number;

endmodule