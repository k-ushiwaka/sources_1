module line_buffer_rxside#(
    parameter M_DEPTH = 11,
    parameter M_WIDTH = 32,
    parameter FULL_NUM = 2048,
    parameter LINE_NUM = 24 
)
(
    input   i_write_clk,    //200Mhz
    input   i_pclk,     //PixelCLK(About 138.5MHZ)
    input   i_rst,

    input   [(LINE_NUM/2)-1 :0] i_line_enable,
    input   [23:0]          i_rgb_data,
    input                   i_sof,

    // input                   i_sync_ok,
    // input                   i_read_enable,
    // output  [23:0]          o_rgb,
    // output                  o_sync_start_enable,
    // output                  o_hsync,
    // output                  o_vsync,
    // output                  o_data_valid
    input                   i_m_axis_ready,
    output                  o_m_axis_valid,
    output  [23:0]          o_m_axis_data,
    output                  o_m_axis_last,
    output                  o_m_axis_sof,
    output                  o_time_end
);
//II include timing param file FHD(1920*1080) II//
    `include "xga_param.vh"
//// BUFFER LOGIC////
    logic    [LINE_NUM-1 :0]                r_write_enable;
    logic    [LINE_NUM-1 :0]                r_read_enable;
    logic    [LINE_NUM-1 :0]                r_read_enable_past;
    logic    [LINE_NUM-1 :0]                                         w_read_enable;
    logic    [1:0]                                                   w_full_flag;
    logic    [1:0]                          r_full_flag_reg;
    wire    [LINE_NUM-1 :0]                 w_empty;
    wire    [LINE_NUM-1 :0]                 w_full;
    wire    [LINE_NUM-1 :0][M_DEPTH-1  :0]  w_buff_count;
    wire    [LINE_NUM-1 :0][31:0]                 w_data;
    logic    [1:0]r_write_flag;
    wire    [23:0]                          w_in_rgb_data_delay;
    logic                                    r_sync_start_enable;
    logic                                   r_outdata_valid;

    logic                  r_m_axis_valid;
    logic                  r_m_axis_valid_delay;
    logic                  r_m_axis_last;
    // (* mark_debug = "true" *)logic  [6:0]           r_frame_count;
    logic                  r_m_axis_sof;
    logic                  r_sof;
    logic  [1:0]           r_sof_edge;
    logic  [11:0]    r_h_count;
    logic  [11:0]    r_v_count;
//    (* mark_debug = "true" *)logic  [11:0]    r_f_count;


    //assign  w_read_enable[0] = i_read_enable;
//DD Delay DD//
    delay #(
        .DATA_WIDTH(24),
        .DELAY_TIME(1)
    )
    U_delay_data(
        .i_clk(i_write_clk),
        .i_rst(i_rst),
        .i_data(i_rgb_data),
        .o_data(w_in_rgb_data_delay)
    );
    delay #(
        .DATA_WIDTH(24),
        .DELAY_TIME(1)
    )
    U_delay_enable(
        .i_clk(i_write_clk),
        .i_rst(i_rst),
        .i_data(r_read_enable),
        .o_data(w_read_enable)
    );

    delay #(
        .DATA_WIDTH(1),
        .DELAY_TIME(1)
    ) 
    U_dealy_valid(
        .i_clk(i_pclk),
        .i_rst(i_rst),
        .i_data(r_m_axis_valid),
        .o_data(r_m_axis_valid_delay)
    );


//GG 24LineBuffer  GG//
    generate
        genvar i;
        for(i = 0 ; i < LINE_NUM ; i++)begin : LINE_GENERATE
            generate_memory#(
                .M_DEPTH(M_DEPTH),
                .M_WIDTH(M_WIDTH),
                .FULL_NUM(FULL_NUM),
                .COUNT(1)
            )
            U_generate_memory
            (
                .i_rst          (i_rst),
                .i_write_clk    (i_write_clk),
                .i_write_enable (r_write_enable[i]),
                .i_write_data   ({8'd0,w_in_rgb_data_delay}),
                .i_read_clk     (i_pclk),
                .i_read_enable  ((i_m_axis_ready&r_m_axis_valid)?r_read_enable[i]:1'b0),
                .o_read_data    (w_data[i]),  
                .o_write_num    (),
                .o_read_num     (w_buff_count[i]),
                .o_empty        (w_empty[i]),
                .o_full         (w_full[i])
            );
        end
    endgenerate
//## Write Enable Control ##//
    // always_ff@(posedge i_pclk) begin
    //     if(w_buff_count[11] > 11'd1918) w_full_flag[0] = 1'b1;
    //     else if(w_buff_count[11] == 11'd0) w_full_flag[0] = 1'b0;
    //     else  w_full_flag[0] =  w_full_flag[0];
    // end
    // always_ff@(posedge i_pclk) begin
    //     if(w_buff_count[23] > 11'd1918) w_full_flag[1] = 1'b1;
    //     else if(w_buff_count[23] == 11'd0) w_full_flag[1] = 1'b0;
    //     else  w_full_flag[1] =  w_full_flag[1];
    // end
    always_ff@(posedge i_pclk)begin
        if(i_rst)           r_full_flag_reg <= 2'b00;
        else                r_full_flag_reg <= w_full_flag;
    end
    // always_comb begin
    //     if(w_buff_count[11] > 11'd1919)     w_full_flag[0] = 1'b1;
    //     else if(w_buff_count[11] == 11'd0)  w_full_flag[0] = 1'b0;
    //     else                                w_full_flag[0] = w_full_flag[0];
    // end
    // always_comb begin
    //     if(w_buff_count[23] > 11'd1919)     w_full_flag[1] = 1'b1;
    //     else if(w_buff_count[23] == 11'd0)  w_full_flag[1] = 1'b0;
    //     else                                w_full_flag[1] = w_full_flag[1];
    // end
   assign w_full_flag[0] = (w_buff_count[11] > 11'd1919)? 1'b1:
                           (w_buff_count[11] == 11'd0  )? 1'b0:
                                                          r_full_flag_reg[0];
   assign w_full_flag[1] = (w_buff_count[23] > 11'd1919)? 1'b1:
                           (w_buff_count[23] == 11'd0  )? 1'b0:
                                                          r_full_flag_reg[1];
    always_ff@(posedge i_write_clk)begin
        if(i_rst)begin
           r_write_enable <= 24'd0;
           r_write_flag  <= 2'b00;
        end
        else if(r_write_flag==2'b11)begin
            case(w_full_flag)
                2'b00:r_write_enable <= {12'd0,i_line_enable};
                2'b01:r_write_enable <= {i_line_enable,12'd0};
                2'b10:r_write_enable <= {12'd0,i_line_enable};
                2'b11:r_write_enable <= 24'd0;
                default: r_write_enable <= 24'd0;
            endcase
            r_write_flag <= w_full_flag;
        end
        else if(r_write_flag==2'b00 &&(w_full_flag==2'b01||w_full_flag==2'b10))begin
            case(w_full_flag)
                2'b00:r_write_enable <= {12'd0,i_line_enable};
                2'b01:r_write_enable <= {i_line_enable,12'd0};
                2'b10:r_write_enable <= {12'd0,i_line_enable};
                2'b11:r_write_enable <= 24'd0;
                default: r_write_enable <= 24'd0;
            endcase
            r_write_flag <= w_full_flag;
        end
        else if(r_write_flag==2'b01 &&(w_full_flag==2'b10||w_full_flag==2'b11))begin
            case(w_full_flag)
                2'b00:r_write_enable <= {12'd0,i_line_enable};
                2'b01:r_write_enable <= {i_line_enable,12'd0};
                2'b10:r_write_enable <= {12'd0,i_line_enable};
                2'b11:r_write_enable <= 24'd0;
                default: r_write_enable <= 24'd0;
            endcase
            r_write_flag <= w_full_flag;
        end
        else if(r_write_flag==2'b10 &&(w_full_flag==2'b01||w_full_flag==2'b11))begin
            case(w_full_flag)
                2'b00:r_write_enable <= {12'd0,i_line_enable};
                2'b01:r_write_enable <= {i_line_enable,12'd0};
                2'b10:r_write_enable <= {12'd0,i_line_enable};
                2'b11:r_write_enable <= 24'd0;
                default: r_write_enable <= 24'd0;
            endcase
            r_write_flag <= w_full_flag;
        end
        else begin
            case(r_write_flag)
                2'b00:r_write_enable <= {12'd0,i_line_enable};
                2'b01:r_write_enable <= {i_line_enable,12'd0};
                2'b10:r_write_enable <= {12'd0,i_line_enable};
                2'b11:r_write_enable <= 24'd0;
                default: r_write_enable <= 24'd0;
            endcase
            r_write_flag <= r_write_flag;
        end 
    end
//## Read Enable Control ##//
    wire    w_shift_flag;
    assign  w_shift_flag = ((w_empty&r_read_enable) != 24'd0)?1'b1:1'b0;

    always_ff@(posedge i_pclk)begin
        if(i_rst)   r_read_enable <= 24'd0;
        else if(r_read_enable != 24'd0)begin
            if(w_shift_flag)begin
                if(r_read_enable == 24'h000800 || r_read_enable == 24'h800000)  r_read_enable <= 24'd0;
                else                                                            r_read_enable <= r_read_enable << 1'b1;
            end
            else                         r_read_enable <= r_read_enable;
        end
        else if(w_full_flag != 2'b00)begin
            if(w_full_flag == 2'b01)     r_read_enable <= 24'h000001;
            else if(w_full_flag == 2'b10)r_read_enable <= 24'h001000;
            else                         r_read_enable <= 24'h000001;   
        end
        else r_read_enable <= 24'd0;
    end
//## AXI4-STREAM Control ##//
    always_ff@(posedge i_pclk)begin
        if(i_rst)                                   r_h_count <= 12'd0;
        else if (r_h_count == 12'd1920)             r_h_count <= 12'd0; 
        else if (r_m_axis_valid && i_m_axis_ready)  r_h_count <= r_h_count + 12'd1;
        else                                        r_h_count <= r_h_count ;
    end
    always_ff@(posedge i_pclk)begin
        if(i_rst)                                   r_v_count <= 12'd0;
        else if (r_v_count == 12'd1080)             r_v_count <= 12'd0; 
        else if (r_m_axis_last)                     r_v_count <= r_v_count + 12'd1;
        else                                        r_v_count <= r_v_count ;
    end
    always_ff@(posedge i_pclk)begin
        if(i_rst)begin
            r_m_axis_valid <= 1'b0;
            r_read_enable_past <= 24'd0;
        end
        else if(r_h_count == 12'd1919)begin
            r_m_axis_valid <= 1'b0;
            r_read_enable_past <=  r_read_enable;
        end  
        else if(r_read_enable != 24'd0 && (r_read_enable_past !=r_read_enable))begin
            r_m_axis_valid <= 1'b1;
            r_read_enable_past <=  r_read_enable;
        end
        else begin
            r_m_axis_valid <= r_m_axis_valid;
            r_read_enable_past <=  r_read_enable;
        end                            
    end

    always_ff@(posedge i_write_clk)begin
        if(i_rst)   r_sof_edge <= 2'b00;
        else begin
                    r_sof_edge[0] <= i_sof;
                    r_sof_edge[1] <= r_sof_edge[0];
        end        
    end
    always_ff@(posedge i_write_clk)begin
        if(i_rst)                                       r_sof <= 1'b0;
        else if(r_sof == 1'b0)                          r_sof <= r_sof_edge[0] && (~r_sof_edge[1]);
        else if(r_sof == 1'b1 && r_m_axis_sof == 1'b1)  r_sof <= 1'b0;
        else                                            r_sof <= r_sof;
    end

    always_ff@(posedge i_pclk)begin
        if(i_rst)                                                                               r_m_axis_sof <= 1'b0;
        else if(r_read_enable != 24'd0 && (r_read_enable_past !=r_read_enable) && i_m_axis_ready && r_h_count == 12'd0 && r_v_count == 12'd0 && r_sof)   r_m_axis_sof <= 1'b1;
        else                                                                                    r_m_axis_sof <= 1'b0;
    end
        always_ff@(posedge i_pclk)begin
        if(i_rst)                                                                               r_m_axis_last <= 1'b0;
        else if(r_m_axis_valid && i_m_axis_ready && r_h_count == 12'd1918 )                     r_m_axis_last <= 1'b1;
        else                                                                                    r_m_axis_last <= 1'b0;
    end
    // always_ff@(posedge i_pclk)begin
    //     if(i_rst)begin
    //         r_frame_count <= 7'd0;
    //         r_m_axis_last <= 1'b0;
    //     end
    //     else if( )                     r_m_axis_last <= 1'b1;
    //     else                                                                                    r_m_axis_last <= 1'b0;
    // end
//## Outdata Valid ##//
//    always_ff@(posedge i_pclk)begin
//        if(i_rst)                   r_outdata_valid <= 1'b0;
//        else if(i_read_enable)begin
//           if(r_read_enable != 24'd0)   r_outdata_valid <= 1'b1;
//           else                         r_outdata_valid <= 1'b0;
//        end
//        else                        r_outdata_valid <= r_outdata_valid;
//    end
// Function Data Select //
    function [23: 0] data_select(input[LINE_NUM-1 :0][31:0]  data , input[LINE_NUM-1:0] ena);
    begin
            case(ena)
            24'h000001:    data_select = data[0][23:0];
            24'h000002:    data_select = data[1][23:0];
            24'h000004:    data_select = data[2][23:0];
            24'h000008:    data_select = data[3][23:0];
            24'h000010:    data_select = data[4][23:0];
            24'h000020:    data_select = data[5][23:0];
            24'h000040:    data_select = data[6][23:0];
            24'h000080:    data_select = data[7][23:0];
            24'h000100:    data_select = data[8][23:0];
            24'h000200:    data_select = data[9][23:0];
            24'h000400:    data_select = data[10][23:0];
            24'h000800:    data_select = data[11][23:0];
            24'h001000:    data_select = data[12][23:0];
            24'h002000:    data_select = data[13][23:0];
            24'h004000:    data_select = data[14][23:0];
            24'h008000:    data_select = data[15][23:0];
            24'h010000:    data_select = data[16][23:0];
            24'h020000:    data_select = data[17][23:0];
            24'h040000:    data_select = data[18][23:0];
            24'h080000:    data_select = data[19][23:0];
            24'h100000:    data_select = data[20][23:0];
            24'h200000:    data_select = data[21][23:0];
            24'h400000:    data_select = data[22][23:0];
            24'h800000:    data_select = data[23][23:0];
            default:        data_select = 23'd0;
            endcase
    end
    endfunction
//>> ASSIGN >>//
    assign  o_m_axis_data = data_select(w_data,r_read_enable);
    assign  o_m_axis_last = r_m_axis_last;
    assign  o_m_axis_sof  = r_m_axis_sof;
    assign  o_m_axis_valid= r_m_axis_valid;
    
    assign  o_time_end    = r_m_axis_last && (r_v_count == 12'd1079);

endmodule