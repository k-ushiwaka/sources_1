module byte_data(
	input           i_clk,
    input           i_rst,
	input           i_start,
    input [14:0]    i_data_byte,
	input [7 :0]    i_row_number,           // auxiliary number
	input [15:0]    i_segment_num,
	input [7 :0]    i_index_clone,
	input [7 :0]    i_vramdata,

	output        o_busy,
	output [7:0]  o_data,
	output        o_data_valid
); 
//// LOGIC ////
    `include "packet_param.vh"
    parameter HEADER_TOTAL_BYTE = ETH_HEADER_BYTE + IP_HEADER_BYTE  + UDP_HEADER_BYTE; //42

    logic       r_busy;
    logic [7:0] r_data;
    logic       r_data_valid;
    logic [14:0]r_counter;

    logic [14:0] w_eth_length;

    logic [15:0] w_ip_length;
    logic [31:0] w_ip_checksum0;
    logic [15:0] w_ip_checksum1;
    logic [15:0] w_ip_checksum2;

    logic [15:0] w_udp_length  ; 
    logic [15:0] w_udp_checksum; 
//-- CONSTANT ASSIGN --//
    assign w_eth_length = HEADER_TOTAL_BYTE + i_data_byte;
    assign w_ip_length  = IP_HEADER_BYTE  + UDP_HEADER_BYTE + i_data_byte;
    assign w_udp_length = UDP_HEADER_BYTE + i_data_byte;
    assign w_udp_checksum = 16'h0000;
    //calculate tcp checksum  , this should all collapse down to a constant at build-time
        //              = 4500 + 0030 + 4422 + 4000 + 8006 + 0000 + (0410 + 8A0C + FFFF + FFFF) = 0002BBCF (32-bit sum)
    assign w_ip_checksum0 = 32'd0 + {IP_VERSION_LENGTH, IP_DSCP_ECN} + {IP_IDENTIFICATION_1,IP_IDENTIFICATION_0}
                                + w_ip_length + {IP_FLAGS_1,IP_FLAGS_0} + {IP_TTL, IP_PROTOCOL}
                                + {IP_SRC_ADDR_3,IP_SRC_ADDR_2} + {IP_SRC_ADDR_1,IP_SRC_ADDR_0}
                                + {IP_DST_ADDR_3,IP_DST_ADDR_2} + {IP_DST_ADDR_1,IP_DST_ADDR_0};
        //              = 0002 + BBCF = BBD1 = 1011101111010001 (1's complement 16-bit sum, formed by "end around carry" of 32-bit 2's complement sum)
    assign w_ip_checksum1 = w_ip_checksum0[31:16] + w_ip_checksum0[15:0];
        //              = ~BBD1 = 0100010000101110 = 442E (1's complement of 1's complement 16-bit sum)
    assign w_ip_checksum2  = ~w_ip_checksum1;
//@@ Packet add @@//
always @(posedge i_clk) begin
    if (i_rst)begin
        r_busy          <=1'b0;
        r_data          <=8'd0;
        r_data_valid    <=1'b0;
        r_counter       <=15'd0;
    end
    else if (r_busy)begin
        if(r_counter == w_eth_length + 6'd20)begin
            r_busy          <=1'b0;
            r_data          <=8'd0;
            r_data_valid    <=1'b0;
            r_counter       <=15'd0;
        end
        // Header Output
        else if(r_counter < HEADER_TOTAL_BYTE )begin
            r_busy          <=r_busy;
            r_data_valid    <=1'b1;
            r_counter       <=r_counter + 1'b1;
            case (r_counter)
                12'h0 : r_data <= ETH_DST_MAC_5;
                12'h1 : r_data <= ETH_DST_MAC_4;
                12'h2 : r_data <= ETH_DST_MAC_3;
                12'h3 : r_data <= ETH_DST_MAC_2;
                12'h4 : r_data <= ETH_DST_MAC_1;
                12'h5 : r_data <= ETH_DST_MAC_0;
                12'h6 : r_data <= ETH_SRC_MAC_5;
                12'h7 : r_data <= ETH_SRC_MAC_4;
                12'h8 : r_data <= ETH_SRC_MAC_3;
                12'h9 : r_data <= ETH_SRC_MAC_2;
                12'ha : r_data <= ETH_SRC_MAC_1;
                12'hb : r_data <= ETH_SRC_MAC_0;
                12'hc : r_data <= ETH_TYPE_1;
                12'hd : r_data <= ETH_TYPE_0;
                12'he : r_data <= IP_VERSION_LENGTH;
                12'hf : r_data <= IP_DSCP_ECN;
                12'h10: r_data <= w_ip_length[15:8];
                12'h11: r_data <= w_ip_length[7:0];
                12'h12: r_data <= IP_IDENTIFICATION_1;
                12'h13: r_data <= IP_IDENTIFICATION_0;
                12'h14: r_data <= IP_FLAGS_1;
                12'h15: r_data <= IP_FLAGS_0;
                12'h16: r_data <= IP_TTL;
                12'h17: r_data <= IP_PROTOCOL;
                12'h18: r_data <= w_ip_checksum2[15:8];
                12'h19: r_data <= w_ip_checksum2[7:0];
                12'h1a: r_data <= IP_SRC_ADDR_3;
                12'h1b: r_data <= IP_SRC_ADDR_2;
                12'h1c: r_data <= IP_SRC_ADDR_1;
                12'h1d: r_data <= IP_SRC_ADDR_0;
                12'h1e: r_data <= IP_DST_ADDR_3; // c0
                12'h1f: r_data <= IP_DST_ADDR_2; // a8
                12'h20: r_data <= IP_DST_ADDR_1; // 01
                12'h21: r_data <= IP_DST_ADDR_0; // 02
                12'h22: r_data <= i_segment_num[15:8]; // UDP SOURCE [15:8]
                12'h23: r_data <= i_segment_num[7:0]; // UDP SOURCE [7:0]
                12'h24: r_data <= i_index_clone;  // UDP DST [15:8]
                12'h25: r_data <= i_row_number; // UDP DST[7:0]
                12'h26: r_data <= w_udp_length[15:8];//05
                12'h27: r_data <= w_udp_length[7:0];//a8
                12'h28: r_data <= w_udp_checksum[15:8];//00
                12'h29: r_data <= w_udp_checksum[7:0];//00

                default:r_data <= 8'hff;
            endcase
        end
        // Data part
        else if(r_counter < w_eth_length) begin
            r_busy          <=r_busy;
            r_data_valid    <=r_data_valid;
            r_counter       <=r_counter + 1'b1;
            r_data          <= i_vramdata;
        end
        // Wait CRC & Preamble
        else begin
            r_busy          <=r_busy;
            r_data          <=8'd0;
            r_data_valid    <=1'b0;
            r_counter       <=r_counter + 1'b1;
        end
    end
	else if (i_start == 1'b1) begin
		r_busy          <= 1'b1;
        r_data          <= 8'd0;
        r_data_valid    <= 1'b0;
        r_counter       <= r_counter;
	end
    else begin
        r_busy          <=1'b0;
        r_data          <=8'd0;
        r_data_valid    <=1'b0;
        r_counter       <=15'd0;
    end
end

//>> OUTPUT ASSIGN >>//
    assign o_busy        = r_busy;
    assign o_data        = r_data;
    assign o_data_valid  = r_data_valid;

endmodule
