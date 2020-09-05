module top_colorbar#(
    parameter  through = "TRUE"
)
(
    input   i_pclk,
    input   i_rst,
    input   i_sync_h,
    input   i_sync_v,
    input   [7:0]   i_r,
    input   [7:0]   i_g,
    input   [7:0]   i_b,
    input           i_sw,
    output  o_sync_h,
    output  o_sync_v,
    output  [7:0]   o_r,
    output  [7:0]   o_g,
    output  [7:0]   o_b
);
    logic   [10:0]  r_hcount;
    logic   [10:0]  r_vcount;
    logic   [7:0]   r_r;
    logic   [7:0]   r_g;
    logic   [7:0]   r_b;

//// Sync Counter ////
    always_ff@(posedge i_pclk)begin
        if(i_rst)           r_hcount <= 11'd0;
        else if(i_sync_h)   r_hcount <= r_hcount + 1'b1 ;
        else                r_hcount <= 11'd0;
    end
    always_ff@(posedge i_pclk)begin
        if(i_rst)                       r_vcount <= 11'd0;
        else if(i_sync_v)begin
            if(r_hcount == 11'd1919)    r_vcount <= r_vcount + 1'b1;
            else                        r_vcount <= r_vcount;
        end
        else                            r_vcount <= 11'd0;
    end

//// Test Pattern Generate ////
//    always_comb begin
//        if(i_sw==1'b1)begin
//            if      (r_vcount < 11'd359)begin
//                r_r = r_hcount[7:0];
//                r_g = 11'd0;
//                r_b = 11'd0;
//            end
//            else if (r_vcount < 11'd719)begin
//                r_r = 11'd0;
//                r_g = r_hcount[7:0];
//                r_b = 11'd0;
//            end
//            else begin
//                r_r = 11'd0;
//                r_g = 11'd0;
//                r_b = r_hcount[7:0];
//            end
//        end
//        else begin
//            r_r = i_r;
//            r_g = i_g;
//            r_b = i_b;
//        end
//    end
    always_comb begin
        if(i_sw==1'b1)begin
                r_r = 8'h77;
                r_g = 8'h77;
                r_b = 8'h77;
        end
        else begin
            r_r = i_r;
            r_g = i_g;
            r_b = i_b;
        end
    end

//>> Through Sync >>//
    assign  o_r         = r_r;
    assign  o_g         = r_g;
    assign  o_b         = r_b;
    assign  o_sync_h    = i_sync_h;
    assign  o_sync_v    = i_sync_v;

endmodule


// top_colorbar#(
//     .through("TRUE")
// )
// (
//     .i_pclk     (),
//     .i_rst      (),
//     .i_sync_h   (),
//     .i_sync_v   (),
//     .i_r        (),
//     .i_g        (),
//     .i_b        (),
//     .o_sync_h   (),
//     .o_sync_v   (),
//     .o_r        (),
//     .o_g        (),
//     .o_b        ()
// );C:\project_xi\production_onechip_ver2\production_onechip_ver2.srcs\sources_1\imports\source\tpg__colorbar.sv