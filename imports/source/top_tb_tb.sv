`timescale 1 ps / 1 ps

module top_tb_tb;
localparam STEP = 5000;
localparam STEP_148 = 6700;


//Port
//System signal
    logic           i_clk_p       ;
    logic           i_clk_n       ;
    logic           i_clk_sdi     ;
    logic           i_rst         ;
    logic   [9:0]   i_y           ;
    logic   [9:0]   i_cbcr        ;
    logic           i_sav         ;
    logic           i_eav         ;
    logic           i_trs         ;
    logic           w_valid       ;
    logic   [23:0]  w_rgb         ;
// SDI MAKE
    integer fd,fd2,fd3,fd4;
    integer test_d;
    integer rtn,i;
    logic   [9:0]   r_xyz;
    logic   [9:0]   y_data;
    logic   [9:0]   cbcr_data;
    logic   [11:0]  o_sync_v_count;

    top_tb
    #(
        .EXAMPLE_SIM_GTRESET_SPEEDUP("TRUE"),
        .USE_BUFG                   (0)
    )
    U_top_tb
    (
        .i_sys_clk_p(i_clk_p),
        .i_sys_clk_n(i_clk_n),
        .i_clk_148  (i_clk_sdi),
        .i_rst      (i_rst),
        .i_y_data   (i_y),    
        .i_cbcr_data(i_cbcr),
        .i_rx_sav   (i_sav),
        .i_rx_eav   (i_eav),
        .i_rx_trs   (i_trs),
        .o_sync_v_count(o_sync_v_count),   
        .o_valid    (w_valid),
        .o_data     (w_rgb)
    );
//Initial RST
    initial begin
        #0      i_rst=0;
        #(STEP_148) i_rst=1;
        #(STEP_148*400);
        i_rst = 0;
    end
// Clocking
    always begin
            i_clk_p <= 0; #(STEP/2);
            i_clk_p <= 1; #(STEP/2);
    end
    always begin
            i_clk_n <= 1; #(STEP/2);
            i_clk_n <= 0; #(STEP/2);
    end
    always begin
            i_clk_sdi <= 0; #(STEP_148/2);
            i_clk_sdi <= 1; #(STEP_148/2);
end
integer k;
// SDI Data Generate
    initial begin
        #(STEP_148*100);@(posedge i_clk_sdi);
        for( k=0;k<2;k++)begin
            test_d =$fopen("test_420.txt","r");
            r_xyz[9:0] = 10'b1111000001;
            #(STEP_148*100);@(posedge i_clk_sdi);
            for(int j = 0; j < 1100 ; j++)begin
                if(j >= 20)              r_xyz[7] <= 1'b0;
                else                     r_xyz[7] <= 1'b1;
                for( i = 0; i < 2254 ; i++)begin
                    if(i < 100)             r_xyz[6] <= 1'b1;
                    else                    r_xyz[6] <= 1'b0;
    
//////////////////////////EAV/////////////////////////////////
                    if(i == 0)begin
                        i_y     <= 10'h3ff;
                        i_cbcr  <= 10'h3ff;
                        i_sav   <= 0;
                        i_eav   <= 1;
                        i_trs   <= 1;
                    end
                    else if(i == 1)begin
                        i_y     <= 10'h000;
                        i_cbcr  <= 10'h000;
                        i_sav   <= 0;
                        i_eav   <= 1;
                        i_trs   <= 1;
                    end
                    else if(i == 2)begin
                        i_y     <= 10'h000;
                        i_cbcr  <= 10'h000;
                        i_sav   <= 0;
                        i_eav   <= 1;
                        i_trs   <= 1;
                    end
                    else if(i == 3)begin
                        i_y     <= r_xyz;
                        i_cbcr  <= r_xyz;
                        i_sav   <= 0;
                        i_eav   <= 1;
                        i_trs   <= 1;
                    end
//////////////////////////Horizon Blank/////////////////////////////////
                    else if(i >= 4 && i <= 329)begin
                        i_y     <= 10'hzzz;
                        i_cbcr  <= 10'hzzz;
                        i_sav   <= 0;
                        i_eav   <= 0;
                        i_trs   <= 0;
                    end
//////////////////////////SAV/////////////////////////////////
                    else if(i == 330)begin
                        i_y     <= 10'h3ff;
                        i_cbcr  <= 10'h3ff;
                        i_sav   <= 1;
                        i_eav   <= 0;
                        i_trs   <= 1;
                    end
                    else if(i == 331)begin
                        i_y     <= 10'h000;
                        i_cbcr  <= 10'h000;
                        i_sav   <= 1;
                        i_eav   <= 0;
                        i_trs   <= 1;
                    end
                    else if(i == 332)begin
                        i_y     <= 10'h000;
                        i_cbcr  <= 10'h000;
                        i_sav   <= 1;
                        i_eav   <= 0;
                        i_trs   <= 1;
                    end
                    else if(i == 333)begin
                        i_y     <= r_xyz;
                        i_cbcr  <= r_xyz;
                        i_sav   <= 1;
                        i_eav   <= 0;
                        i_trs   <= 1;
                    end
//////////////////////////DATA/////////////////////////////////
                    else if(i >= 334 && r_xyz[7] == 1'b0)begin
                        rtn     <= $fscanf(test_d,"%d %d",y_data,cbcr_data); 
                        i_y     <= (y_data<<2);//$urandom_range(20,1000);
                        i_cbcr  <= (cbcr_data<<2);//$urandom_range(100,1000);
                        i_sav   <= 0;
                        i_eav   <= 0;
                        i_trs   <= 0;
                    end                
//////////////////////////Other/////////////////////////////////
                    else begin
                        i_y     <= 10'hzzz;
                        i_cbcr  <= 10'hzzz;
                        i_sav   <= 0;
                        i_eav   <= 0;
                        i_trs   <= 0;
                    end
                    #(STEP); @(posedge i_clk_sdi);
                end
            end
            $fclose(test_d);
        end
        $fclose(fd);
        $fclose(fd2);
        $fclose(fd3);
        $fclose(fd4);
        
    end
// Write File 
    initial begin
        fd =    $fopen("imagedata.raw", "wb");
        fd2 =   $fopen("decode_BGR.txt", "wb");
        fd3 =   $fopen("imagedata_2frame.raw", "wb");
        fd4 =   $fopen("decode_BGR_2frame.txt", "wb");
    end
    always@(posedge i_clk_p)begin
        if(k==0)begin
            if(w_valid== 1'b1)begin
                $fwrite(fd,"%c",w_rgb[23:16]);
                $fwrite(fd,"%c",w_rgb[15:8]);
                $fwrite(fd,"%c",w_rgb[7:0]);
                $fwrite(fd2,"%4d",w_rgb[23:16]);
                $fwrite(fd2,"%4d",w_rgb[15:8]);
                $fwrite(fd2,"%4d",w_rgb[7:0]);
                $fwrite(fd2,"\n");
            end
            $fflush(fd);
            $fflush(fd2);
        end
        else begin
            if(w_valid== 1'b1)begin
                $fwrite(fd3,"%c",w_rgb[23:16]);
                $fwrite(fd3,"%c",w_rgb[15:8]);
                $fwrite(fd3,"%c",w_rgb[7:0]);
                $fwrite(fd4,"%4d",w_rgb[23:16]);
                $fwrite(fd4,"%4d",w_rgb[15:8]);
                $fwrite(fd4,"%4d",w_rgb[7:0]);
                $fwrite(fd4,"\n");
            end
            $fflush(fd3);
            $fflush(fd4);
        end
    end
endmodule
