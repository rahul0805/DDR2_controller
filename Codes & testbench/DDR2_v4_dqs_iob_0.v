`timescale 1ns/1ps

module DDR2_v4_dqs_iob_0
  (
   input        clk,
   input        reset,
   input        ctrl_dqs_rst,
   input        ctrl_dqs_en,
   inout        ddr_dqs_l,
   inout        ddr_dqs
   );

   wire         dqs_in;
   wire         dqs_out;
   wire         ctrl_dqs_en_r1;
   wire         vcc;
   wire         gnd;
   wire         clk180;
   reg          data1;
   reg          reset_r1
                /* synthesis syn_preserve=1 */;

  //*******************************************************************

   assign       vcc         = 1'b1;
   assign       gnd         = 1'b0;
   assign       clk180      = ~clk;

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   always @ (posedge clk180) begin
      if (ctrl_dqs_rst == 1'b1)
        data1 <= 1'b0;
      else
        data1 <= 1'b1;
   end

   ODDR #
     (
      .SRTYPE       ("SYNC"),
      .DDR_CLK_EDGE ("OPPOSITE_EDGE")
      )
     oddr_dqs
       (
        .Q    (dqs_out),
        .C    (clk180),
        .CE   (vcc),
        .D1   (data1),
        .D2   (gnd),
        .R    (gnd),
        .S    (gnd)
        );

   (* IOB = "FORCE" *) FDP tri_state_dqs
     (
      .Q    (ctrl_dqs_en_r1),
      .C    (clk180),
      .D    (ctrl_dqs_en),
      .PRE  (gnd)
      ) /* synthesis syn_useioff = 1 */;


   IOBUFDS iobuf_dqs
     (
      .O    (dqs_in),
      .IO   (ddr_dqs),
      .IOB  (ddr_dqs_l),
      .I    (dqs_out),
      .T    (ctrl_dqs_en_r1)
      );



endmodule
