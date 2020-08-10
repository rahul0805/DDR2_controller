`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_data_write_0
  (
   input                          clk,
   input                          clk90,
   input                          reset90,
   input [(`DQ_WIDTH*2)-1:0]      wdf_data,
   input [(`DM_WIDTH*2)-1:0]      mask_data,
   input                          ctrl_wren,
   input                          ctrl_dqs_rst,
   input                          ctrl_dqs_en,
   output                         dqs_rst,
   output                         dqs_en,
   output [1:0]                   wr_en,
   output                         dm_wr_en,
   output [`DQ_WIDTH-1:0]         wr_data_rise,
   output [`DQ_WIDTH-1:0]         wr_data_fall,
   output [`DATA_MASK_WIDTH-1:0]  mask_data_rise,
   output [`DATA_MASK_WIDTH-1:0]  mask_data_fall
   ) /* synthesis syn_preserve=1 */;

   reg                            wr_en_clk270_r1;
   reg                            wr_en_clk270_r2;
   reg                            wr_en_clk90_r2;
   reg                            wr_en_clk90_r3;
   reg                            wr_en_clk90_r4;

   reg                            dqs_rst_r1;
   reg                            dqs_rst_r2;

   reg                            dqs_en_r1;
   reg                            dqs_en_r2;
   reg                            dqs_en_r3
                                  /* synthesis syn_maxfan = 5 */;

   reg                            reset90_r1;



   //***************************************************************************

   assign dqs_rst    = dqs_rst_r2;
   assign dqs_en     = dqs_en_r3;

   // 3-state enable for the data I/O generated such that to enable
   // write data output one-half clock cycle before
   // the first data word, and disable the write data
   // one-half clock cycle after the last data word
   assign wr_en[0]   = wr_en_clk90_r3 | wr_en_clk90_r4;
   assign wr_en[1]   = wr_en_clk90_r2 | wr_en_clk90_r3;
   assign dm_wr_en   = wr_en_clk270_r2;

   always @( posedge clk90 )
     reset90_r1 <= reset90;

   always @ (negedge clk90) begin
      wr_en_clk270_r1 <= ctrl_wren;
      wr_en_clk270_r2 <= wr_en_clk270_r1;
      dqs_rst_r1      <= ctrl_dqs_rst;
      dqs_en_r1       <= ~ctrl_dqs_en;
   end

   // synthesis attribute max_fanout of dqs_en_r3 is 5
   always @ (negedge clk) begin
      dqs_rst_r2  <= dqs_rst_r1;
      dqs_en_r2   <= dqs_en_r1;
      dqs_en_r3   <= dqs_en_r2;
   end

   always @ (posedge clk90) begin
      wr_en_clk90_r2 <= wr_en_clk270_r1;
      wr_en_clk90_r3 <= wr_en_clk90_r2;
      wr_en_clk90_r4 <= wr_en_clk90_r3;
   end

  //***************************************************************************
  // Format write data/mask: Data is in format: {rise, fall}
  //***************************************************************************

   assign wr_data_rise = wdf_data[(`DQ_WIDTH*2)-1:`DQ_WIDTH];
   assign wr_data_fall = wdf_data[`DQ_WIDTH-1:0];
   
   
   
   assign mask_data_rise = mask_data[(`DM_WIDTH*2)-1:`DM_WIDTH];
   assign mask_data_fall = mask_data[`DM_WIDTH-1:0];


endmodule
