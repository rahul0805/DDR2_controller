`timescale 1ns/1ps

module DDR2_wr_data_fifo_16
  (
   input         clk0,
   input         clk90,
   input         rst,

   //wdf signals
   input [31:0]  app_wdf_data,
   input [3:0]   app_mask_data,
   input         app_wdf_wren,
   input         ctrl_wdf_rden,

   output [31:0] wdf_data,
   output [3:0]  mask_data,
   output        wr_df_almost_full
   );

   reg           ctrl_wdf_rden_270;
   reg           ctrl_wdf_rden_90;

   reg           rst_r1
                 /* synthesis syn_preserve=1 */;

   // synthesis attribute equivalent_register_removal of rst_r1 is "no";
   always @( posedge clk0 )
     rst_r1 <= rst;

   always @(negedge clk90)
     ctrl_wdf_rden_270 <= ctrl_wdf_rden;

   always @(posedge clk90)
     ctrl_wdf_rden_90 <= ctrl_wdf_rden_270;

   FIFO16 #
     (
      .ALMOST_EMPTY_OFFSET     (12'h007),
      .ALMOST_FULL_OFFSET      (12'h00F),
      .DATA_WIDTH              (36),
      .FIRST_WORD_FALL_THROUGH ("FALSE")
      )
     Wdf_1
       (
        .ALMOSTEMPTY    (),
        .ALMOSTFULL     (wr_df_almost_full),
        .DO             (wdf_data[31:0]),
        .DOP            (mask_data[3:0]),
        .EMPTY          (),
        .FULL           (),
        .RDCOUNT        (),
        .RDERR          (),
        .WRCOUNT        (),
        .WRERR          (),
        .DI             (app_wdf_data[31:0]),
        .DIP            (app_mask_data[3:0]),
        .RDCLK          (clk90),
        .RDEN           (ctrl_wdf_rden_90),
        .RST            (rst_r1),
        .WRCLK          (clk0),
        .WREN           (app_wdf_wren)
        );


endmodule
