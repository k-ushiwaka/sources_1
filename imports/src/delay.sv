module delay#(
    parameter DATA_WIDTH = 1,
    parameter DELAY_TIME = 10
)
(
    //System signal
    input       i_clk,
    input       i_rst,

    //Input Data
    input   [DATA_WIDTH-1 : 0] i_data,

    //Output Data
    output  [DATA_WIDTH-1 : 0] o_data
);

//local signal
genvar  i;
logic   [DELAY_TIME-1 : 0][DATA_WIDTH-1 : 0]  r_buff;

//Shift Register
always_ff@(posedge i_clk)begin
    if(i_rst)   r_buff[0] <= {DATA_WIDTH{1'b0}};
    else        r_buff[0] <= i_data;
end

generate
    for(i=1;i<DELAY_TIME;i++)begin : shift_register
        always_ff@(posedge i_clk)begin
            if(i_rst)   r_buff[i] <= {DATA_WIDTH{1'b0}};
            else        r_buff[i] <= r_buff[i-1];
        end
    end
endgenerate

//Output
assign o_data = r_buff[DELAY_TIME-1];

endmodule