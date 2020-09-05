module add_preamble(
	input           i_clk,
	input			i_rst,
	input   [7:0]   i_data,
	input           i_data_valid,
	output  [7:0]   o_data,
	output          o_data_valid
	);
//// Logic ////
	logic   [7:0]   w_delay_data;
	logic   [7:0]   r_delay_data_valid;
    logic           r_data_valid;
    logic   [7:0]   r_data;
//DD Delay DD//
    delay#(
        .DATA_WIDTH(8),
        .DELAY_TIME(8)
    )
    U_delay_data(
        .i_clk(i_clk),
        .i_rst(1'b0),
        .i_data(i_data),
        .o_data(w_delay_data)
    );
//## FF ##//
    //r_delay_data_valid//
    always_ff@(posedge i_clk)begin
        if(i_rst)   	r_delay_data_valid <= 8'b00000000;	
        else            r_delay_data_valid <= {r_delay_data_valid[7:0], i_data_valid};
    end
    //r_data,r_data_valid//
	always_ff@(posedge i_clk) begin
		if (i_data_valid == 1'b1) begin
			if (r_delay_data_valid[7] == 1'b1) begin
				// passing through data
				r_data              <= w_delay_data;
				r_data_valid    	<= 1'b1;
			end 
			else if (r_delay_data_valid[6] == 1'b1)begin
				r_data          <= 8'b11010101;
				r_data_valid    <= 1'b1;
			end
			else begin
				// preamble nibbles
				r_data          <= 8'b01010101;
				r_data_valid    <= 1'b1;
			end
		end
		else if(r_delay_data_valid >= 8'b10000000)begin
			r_data              <= w_delay_data;
			r_data_valid    	<= 1'b1;
		end
        else begin
            r_data          <= 8'b00000000;
            r_data_valid    <= 1'b0;
        end
	end
//>> ASSIGN >>//
    assign o_data           = r_data;
    assign o_data_valid     = r_data_valid;
endmodule