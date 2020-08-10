`timescale 1ns/1ps

module DDR2_v4_dm_iob
  (
   input    clk90,
   input    mask_data_rise,
   input    mask_data_fall,
   input    dm_wr_en,
   output   ddr_dm
   );

   wire     vcc;
   wire     gnd;
   wire     write_en_l;
   wire     write_en_l_r1;

   wire     dm_out;

   assign   vcc        = 1'b1;
   assign   gnd        = 1'b0;
   assign   write_en_l = dm_wr_en;

   FDRSE dm_oddr_ce
     (
      .Q    (write_en_l_r1),
      .C    (~clk90),
      .CE   (vcc),
      .D    (write_en_l),
      .R    (gnd),
      .S    (gnd)
      ) /* synthesis syn_preserve=1 */;

   ODDR #
     (
      .SRTYPE       ("SYNC"),
      .DDR_CLK_EDGE ("SAME_EDGE")
      )
     oddr_dm
       (
        .Q         (dm_out),
        .C         (clk90),
        .CE        (write_en_l_r1),
        .D1        (mask_data_rise),
        .D2        (mask_data_fall),
        .R         (gnd),
        .S         (gnd)
        );

   OBUF obuf_dm
     (
      .I         (dm_out),
      .O         (ddr_dm)
      );


endmodule