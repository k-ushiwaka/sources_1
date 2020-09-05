// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Thu Sep  3 16:22:31 2020
// Host        : DESKTOP-BLB0722 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/source/sim_stream/sim_stream.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_138, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_138,locked,clk_in1" */;
  output clk_138;
  output locked;
  input clk_in1;
endmodule
