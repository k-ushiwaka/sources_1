module add_crc32(
	input           i_clk,
    input           i_rst,
	input   [7:0]   i_data,
	input           i_data_valid,
	output  [7:0]   o_data,
	output          o_data_valid
	);
//// Logic ////
	logic [31:0]    r_crc;
	logic [3:0]     r_trailer_left;
	logic [31:0]    r_v_crc;

    logic [7:0]     r_data;
    logic           r_data_valid;

    integer i=0;

//### FF ###//
    always_ff@(posedge i_clk)begin
        if(i_rst)begin
            r_data          <= 8'b00000000;
            r_data_valid    <= 1'b0;
            r_trailer_left  <= 4'b0000;
            r_crc           <= 32'hffffffff;
            r_v_crc         <= 32'hffffffff; 
        end
        else if(i_data_valid)begin
            r_data          <= i_data;
            r_data_valid    <= 1'b1;
            r_trailer_left  <= 4'b1111;
//            r_crc   <= r_v_crc;
            // update CRC
            for (i=0; i<8; i=i+1)begin
                if (i_data[i] == r_v_crc[31])   r_v_crc = {r_v_crc[30:0],1'b0};
                else                            r_v_crc = {r_v_crc[30:0],1'b0} ^ 32'h04c11db7;
            end
            r_crc   <= r_v_crc;
        end
        else if(r_trailer_left[3]) begin
            // append the CRC
			r_data          <= ~({r_crc[24],r_crc[25],r_crc[26],r_crc[27],r_crc[28],r_crc[29],r_crc[30],r_crc[31]});
            r_data_valid    <= 1'b1;
            r_trailer_left  <= {r_trailer_left[2:0],1'b0};
			r_crc           <= {r_crc[23:0] ,8'b11111111};
        end
        else begin
            r_data          <= 8'b00000000;
            r_data_valid    <= 1'b0;
            r_trailer_left  <= 4'b0000;
            r_crc           <= 32'hffffffff;
            r_v_crc         <= 32'hffffffff; 
        end
    end
//>>> ASSIGN >>>//
    assign o_data           = r_data;
    assign o_data_valid     = r_data_valid;

endmodule
