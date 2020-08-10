`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_controller_iobs_0
  (
   input [`ROW_ADDRESS-1:0]   ctrl_ddr2_address,
   input [`BANK_ADDRESS-1:0]  ctrl_ddr2_ba,
   input                      ctrl_ddr2_ras_l,
   input                      ctrl_ddr2_cas_l,
   input                      ctrl_ddr2_we_l,
   input [`CS_WIDTH-1:0]      ctrl_ddr2_cs_l,
   input [`CKE_WIDTH-1:0]     ctrl_ddr2_cke,
   input [`ODT_WIDTH-1:0]     ctrl_ddr2_odt,

   output [`ROW_ADDRESS-1:0]  ddr_address,
   output [`BANK_ADDRESS-1:0] ddr_ba,
   output                     ddr_ras_l,
   output                     ddr_cas_l,
   output                     ddr_we_l,
   output [`CKE_WIDTH-1:0]    ddr_cke,
   output [`ODT_WIDTH-1:0]    ddr_odt,
   output [`CS_WIDTH-1:0]     ddr_cs_l
   );

   //***************************************************************************

   //***************************************************************************
   // Output flop instantiation
   // NOTE: Make sure all control/address flops are placed in IOBs
   //***************************************************************************

   // RAS: = 1 at reset
   OBUF obuf_ras
     (
      .I  (ctrl_ddr2_ras_l),
      .O  (ddr_ras_l)
      );

   // CAS: = 1 at reset
   OBUF obuf_cas
     (
      .I  (ctrl_ddr2_cas_l),
      .O  (ddr_cas_l)
      );

   // WE: = 1 at reset
   OBUF obuf_we
     (
      .I  (ctrl_ddr2_we_l),
      .O  (ddr_we_l)
      );

   // chip select: = 1 at reset
   genvar cs_i;
   generate
     for(cs_i = 0; cs_i < `CS_WIDTH; cs_i = cs_i + 1) begin: gen_cs_n
       OBUF u_obuf_cs_n
         (
          .I  (ctrl_ddr2_cs_l[cs_i]),
          .O  (ddr_cs_l[cs_i])
          );
     end
   endgenerate

   // CKE: = 0 at reset
   genvar cke_i;
   generate
     for (cke_i = 0; cke_i < `CKE_WIDTH; cke_i = cke_i + 1) begin: gen_cke
        OBUF u_obuf_cke
          (
           .I  (ctrl_ddr2_cke[cke_i]),
           .O  (ddr_cke[cke_i])
           );
     end
   endgenerate

   // ODT control = 0 at reset
   genvar odt_i;
   generate
     for (odt_i = 0; odt_i < `ODT_WIDTH; odt_i = odt_i + 1) begin: gen_odt
       OBUF u_obuf_odt
         (
          .I  (ctrl_ddr2_odt[odt_i]),
          .O  (ddr_odt[odt_i])
          );
     end
   endgenerate

   // address: = 0 at reset
   genvar addr_i;
   generate
     for (addr_i = 0; addr_i < `ROW_ADDRESS; addr_i = addr_i + 1) begin: gen_addr
       OBUF u_obuf_addr
         (
          .I  (ctrl_ddr2_address[addr_i]),
          .O  (ddr_address[addr_i])
          );
     end
   endgenerate

   // bank address = 0 at reset
   genvar ba_i;
   generate
     for (ba_i = 0; ba_i < `BANK_ADDRESS; ba_i = ba_i + 1) begin: gen_ba
       OBUF u_obuf_ba
         (
          .I  (ctrl_ddr2_ba[ba_i]),
          .O  (ddr_ba[ba_i])
          );
     end
   endgenerate

endmodule
