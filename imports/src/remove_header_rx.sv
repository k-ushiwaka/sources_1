module remove_header_rx(
    input           i_rx_clk,
    input           i_rst,
    input   [7:0]   i_rx_data,
    input           i_data_enable,
    input           i_data_error,
    output  [7:0]   o_packet_data,
    output          o_data_enable,
    output  [7:0]   o_packet_param,
    output          o_param_enable,
    output          o_sof,
    output  [15:0]  o_data_length,
    output          o_param_flag,
    output          o_time_start
);
    `include "packet_param.vh"
    parameter HEADER_TOTAL_BYTE = ETH_HEADER_BYTE + IP_HEADER_BYTE  + UDP_HEADER_BYTE; //42
    parameter HEADER_ETH_BYTE   = ETH_HEADER_BYTE + IP_HEADER_BYTE ;
// Logic Header store //
    logic   [7:0][7:0]  r_preamble;
    logic   [47:0]  r_mac_addres_src;
    logic   [47:0]  r_mac_addres_dst;
    logic   [15:0]  r_eth_type;
    logic   [7:0]   r_version_length;
    logic   [7:0]   r_ip_type;
    logic   [15:0]  r_ip_length;
    logic   [15:0]  r_identification;
    logic   [15:0]  r_flagment;
    logic   [7:0]   r_ttl;
    logic   [7:0]   r_ip_protcol; 
    logic   [15:0]  r_header_checksum;
    logic   [31:0]  r_ip_addres_src;
    logic   [31:0]  r_ip_addres_dst;
    logic   [15:0]  r_port_src;         // -> segment number(not use)
    logic   [15:0]  r_port_dst;         // -> clone index number(not use) && row number (use)
    logic   [15:0]  r_udp_length;
    logic   [15:0]  r_udp_checksum;
    logic   [3:0][7:0]  r_crc;
// Logic //
    logic   [14:0]  r_counter;
    logic   [7:0]   r_udp_data;
    logic           r_udp_data_valid;
// FLAME SYNC LOGIC //
    logic           r_fsync_valid;
    logic   [15:0]  r_port_dst_past;

// Analysys Packet
    always_ff@(posedge i_rx_clk,posedge i_rst)begin
        if(i_rst)begin
            r_counter <= 15'd0;
            r_preamble          <= 64'd0;
            r_mac_addres_src    <= 48'd0;
            r_mac_addres_dst    <= 48'd0;
            r_eth_type          <= 16'd0;
            r_version_length    <= 8'd0;
            r_ip_type           <= 8'd0;
            r_ip_length         <= 16'd0;
            r_identification    <= 16'd0;
            r_flagment          <= 16'd0;
            r_ttl               <= 8'd0;
            r_ip_protcol        <= 8'd0;
            r_header_checksum   <= 16'd0;
            r_ip_addres_src     <= 32'd0;
            r_ip_addres_dst     <= 32'd0;
            r_port_src          <= 16'h0000;
            r_port_dst          <= 16'h0000;
            r_udp_length        <= 16'd0;
            r_udp_checksum      <= 16'd0;
            r_crc               <= 32'd0;
            r_udp_data          <= 8'd0;
            r_udp_data_valid    <= 1'b0;
        end
        else if(i_data_enable)begin
            if(r_counter < HEADER_TOTAL_BYTE + 4'd8)begin
                case(r_counter)
                    // Preamble 8 byte
                    15'h0 : r_preamble[7]           <= i_rx_data;
                    15'h1 : r_preamble[6]           <= i_rx_data;
                    15'h2 : r_preamble[5]           <= i_rx_data;
                    15'h3 : r_preamble[4]           <= i_rx_data;
                    15'h4 : r_preamble[3]           <= i_rx_data;
                    15'h5 : r_preamble[2]           <= i_rx_data;
                    15'h6 : r_preamble[1]           <= i_rx_data;
                    15'h7 : r_preamble[0]           <= i_rx_data;
                    15'h8 : r_mac_addres_src[47:40] <= i_rx_data;
                    15'h9 : r_mac_addres_src[39:32] <= i_rx_data;
                    15'ha : r_mac_addres_src[31:24] <= i_rx_data;
                    15'hb : r_mac_addres_src[23:16] <= i_rx_data;
                    15'hc : r_mac_addres_src[15:8]  <= i_rx_data;
                    15'hd : r_mac_addres_src[7:0]   <= i_rx_data;
                    15'he : r_mac_addres_dst[47:40] <= i_rx_data; 
                    15'hf : r_mac_addres_dst[39:32] <= i_rx_data;
                    15'h10: r_mac_addres_dst[31:24] <= i_rx_data;
                    15'h11: r_mac_addres_dst[23:16] <= i_rx_data;
                    15'h12: r_mac_addres_dst[15:8]  <= i_rx_data;
                    15'h13: r_mac_addres_dst[7:0]   <= i_rx_data;
                    15'h14: r_eth_type[15:8]        <= i_rx_data;
                    15'h15: r_eth_type[7:0]         <= i_rx_data;
                    15'h16: r_version_length        <= i_rx_data;    
                    15'h17: r_ip_type               <= i_rx_data;
                    15'h18: r_ip_length[15:8]       <= i_rx_data;
                    15'h19: r_ip_length[7:0]        <= i_rx_data;
                    15'h1a: r_identification[15:8]  <= i_rx_data;
                    15'h1b: r_identification[7:0]   <= i_rx_data;
                    15'h1c: r_flagment[15:8]        <= i_rx_data;
                    15'h1d: r_flagment[7:0]         <= i_rx_data;
                    15'h1e: r_ttl                   <= i_rx_data;
                    15'h1f: r_ip_protcol            <= i_rx_data;
                    15'h20: r_header_checksum[15:8] <= i_rx_data;
                    15'h21: r_header_checksum[7:0]  <= i_rx_data;
                    15'h22: r_ip_addres_src[31:24]  <= i_rx_data;
                    15'h23: r_ip_addres_src[23:16]  <= i_rx_data;
                    15'h24: r_ip_addres_src[15:8]   <= i_rx_data;
                    15'h25: r_ip_addres_src[7:0]    <= i_rx_data;
                    15'h26: r_ip_addres_dst[31:24]  <= i_rx_data;
                    15'h27: r_ip_addres_dst[23:16]  <= i_rx_data;
                    15'h28: r_ip_addres_dst[15:8]   <= i_rx_data;
                    15'h29: r_ip_addres_dst[7:0]    <= i_rx_data;
                    15'h2a: r_port_src[15:8]        <= i_rx_data;
                    15'h2b: r_port_src[7:0]         <= i_rx_data;
                    15'h2c: r_port_dst[15:8]        <= i_rx_data;
                    15'h2d: r_port_dst[7:0]         <= i_rx_data;
                    15'h2e: r_udp_length[15:8]      <= i_rx_data;
                    15'h2f: r_udp_length[7:0]       <= i_rx_data;
                    15'h30: r_udp_checksum[15:8]    <= i_rx_data;
                    15'h31: r_udp_checksum[7:0]     <= i_rx_data;
                    default:begin
                        r_preamble          <= r_preamble          ;
                        r_mac_addres_src    <= r_mac_addres_src    ;
                        r_mac_addres_dst    <= r_mac_addres_dst    ;
                        r_eth_type          <= r_eth_type          ;
                        r_version_length    <= r_version_length    ;
                        r_ip_type           <= r_ip_type           ;
                        r_ip_length         <= r_ip_length         ;
                        r_identification    <= r_identification    ;
                        r_flagment          <= r_flagment          ;
                        r_ttl               <= r_ttl               ;
                        r_ip_protcol        <= r_ip_protcol        ;
                        r_header_checksum   <= r_header_checksum   ;
                        r_ip_addres_src     <= r_ip_addres_src     ;
                        r_ip_addres_dst     <= r_ip_addres_dst     ;
                        r_port_src          <= r_port_src          ;
                        r_port_dst          <= r_port_dst          ;
                        r_udp_length        <= r_udp_length        ;
                        r_udp_checksum      <= r_udp_checksum      ;
                        r_crc               <= r_crc               ;
                        r_udp_data          <= r_udp_data          ;
                        r_udp_data_valid    <= r_udp_data_valid    ;
                    end
                endcase   
                r_counter <= r_counter + 1'b1;
            end
            else if(r_counter < HEADER_ETH_BYTE + 4'd8 + r_udp_length  )begin
                if(r_ip_addres_src == 64'hc0a80141 &&r_ip_addres_dst == 64'hc0a80132)begin
                    r_udp_data_valid    <= 1'b1;
                    r_udp_data          <= i_rx_data;
                    r_counter <= r_counter + 1'b1;
                end
                else begin
                    r_udp_data_valid    <= 1'b0;
                    r_udp_data          <= i_rx_data;
                    r_counter <= r_counter + 1'b1;
                end
            end
            else begin
                r_crc[3] <= i_rx_data;
                r_crc[2] <= r_crc[3];
                r_crc[1] <= r_crc[2];
                r_crc[0] <= r_crc[1];
                r_counter <= r_counter + 1'b1;
                r_udp_data_valid    <= 1'b0;
            end
        end
        else begin
            r_counter           <= 15'd0;
            r_udp_data_valid    <= 1'b0;
        end
    end

//>> OUTPUT ASSIGN >> //
    assign o_data_length  = r_udp_length- UDP_HEADER_BYTE;
    // data (r_port_dst[12] == 0)
    assign o_packet_data  = (r_port_dst[12] == 1'b0) ? r_udp_data : 8'd0 ;
    assign o_data_enable  = (r_port_dst[12] == 1'b0) ? ((~i_data_error)?r_udp_data_valid:1'b0) : 1'd0 ;
    // data (r_port_dst[12] == 1)
    assign o_packet_param = (r_port_dst[12] == 1'b1) ? r_udp_data : 8'd0 ;
    assign o_param_enable = (r_port_dst[12] == 1'b1) ? ((~i_data_error)?r_udp_data_valid:1'b0) : 1'd0 ;
    assign o_sof          = r_port_dst[11] & o_data_enable;
    assign o_param_flag   = r_port_dst[12];

    assign o_time_start   = (r_udp_length- UDP_HEADER_BYTE != 1410) && o_data_enable && (r_port_dst[7:0] == 8'd89);
endmodule