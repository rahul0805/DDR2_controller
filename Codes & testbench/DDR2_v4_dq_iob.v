`timescale 1ns/1ps

module DDR2_v4_dq_iob
  (
   input       clk,
   input       clk90,
   input       reset0,
   input       data_dlyinc,
   input       data_dlyce,
   input       data_dlyrst,
   input       write_data_rise,
   input       write_data_fall,
   input [1:0] ctrl_wren,
   input       delay_enable,
   output      rd_data_rise,
   output      rd_data_fall,
   inout       ddr_dq
   );

   wire        dq_in;
   wire        dq_out;
   wire        dq_delayed;
   wire [1:0]  write_en_l;
   wire        write_en_l_r1;
   wire        dq_q1;
   wire        dq_q1_r;
   wire        dq_q2;
   wire        vcc;
   wire        gnd;
   reg         reset0_r1
               /* synthesis syn_preserve=1 */;

  //*******************************************************************

   assign   vcc        = 1'b1;
   assign   gnd        = 1'b0;

   assign   write_en_l = ~ctrl_wren;

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset0_r1 <= reset0;

   ODDR #
     (
      .DDR_CLK_EDGE ("SAME_EDGE"),
      .SRTYPE       ("SYNC")
      )
     oddr_dq
       (
        .Q    (dq_out),
        .C    (clk90),
        .CE   (vcc),
        .D1   (write_data_rise),
        .D2   (write_data_fall),
        .R    (gnd),
        .S    (gnd)
        );

   // 3-state enable for the data I/O generated such that to enable
   // write data output one-half clock cycle before
   // the first data word, and disable the write data
   // one-half clock cycle after the last data word
   ODDR #
     (
      .DDR_CLK_EDGE ("SAME_EDGE"),
      .SRTYPE       ("ASYNC")
      )
     tri_state_dq
       (
        .Q    (write_en_l_r1),
        .C    (clk90),
        .CE   (vcc),
        .D1   (write_en_l[0]),
        .D2   (write_en_l[1]),
        .R    (gnd),
        .S    (gnd)
        );

   IOBUF  iobuf_dq
     (
      .I    (dq_out),
      .T    (write_en_l_r1),
      .IO   (ddr_dq),
      .O    (dq_in)
      );

   IDELAY #
     (
      .IOBDELAY_TYPE  ("VARIABLE"),
      .IOBDELAY_VALUE (0)
      )
     idelay_dq
       (
        .O    (dq_delayed),
        .I    (dq_in),
        .C    (clk),
        .CE   (data_dlyce),
        .INC  (data_dlyinc),
        .RST  (data_dlyrst)
        );

   IDDR #
     (
      .DDR_CLK_EDGE ("SAME_EDGE"),
      .SRTYPE       ("SYNC")
      )
     iddr_dq
       (
        .Q1   (dq_q1),
        .Q2   (dq_q2),
        .C    (clk),
        .CE   (vcc),
        .D    (dq_delayed),
        .R    (gnd),
        .S    (gnd)
        );

   //*******************************************************************
   // RC: Optional circuit to delay the bit by one bit time - may be
   // necessary if there is bit-misalignment (e.g. rising edge of FPGA
   // clock may be capturing bit[n] for DQ[0] but bit[n+1] for DQ[1])
   // within a DQS group. The operation for delaying by one bit time
   // involves delaying the Q1 (rise) output of the IDDR, and "flipping"
   // the Q bits
   //*******************************************************************

   FDRSE u_fd_dly_q1
     (
      .Q    (dq_q1_r),
      .C    (clk),
      .CE   (vcc),
      .D    (dq_q1),
      .R    (gnd),
      .S    (gnd)
      );

   assign rd_data_rise = delay_enable ? dq_q2   : dq_q1;
   assign rd_data_fall = delay_enable ? dq_q1_r : dq_q2;

endmodule
