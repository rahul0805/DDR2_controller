`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_infrastructure_iobs_0
  (
   input                    clk,
   output [`CLK_WIDTH-1:0]  ddr_ck,
   output [`CLK_WIDTH-1:0]  ddr_ck_n
   );

   wire [`CLK_WIDTH-1:0]    ddr_ck_q;

   //***************************************************************************
   // Memory clock generation
   //***************************************************************************

   genvar ck_i;
   generate
     for(ck_i = 0; ck_i < `CLK_WIDTH; ck_i = ck_i+1) begin: gen_ck
       ODDR #
         (
          .SRTYPE       ("SYNC"),
          .DDR_CLK_EDGE ("OPPOSITE_EDGE")
          )
         u_oddr_ck_i
           (
            .Q   (ddr_ck_q[ck_i]),
            .C   (clk),
            .CE  (1'b1),
            .D1  (1'b0),
            .D2  (1'b1),
            .R   (1'b0),
            .S   (1'b0)
            );

       OBUFDS u_obuf_ck_i
         (
          .I   (ddr_ck_q[ck_i]),
          .O   (ddr_ck[ck_i]),
          .OB  (ddr_ck_n[ck_i])
          );
     end
   endgenerate

endmodule
