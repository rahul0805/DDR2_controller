`timescale 1ns/1ps

`include "../rtl/DDR2_parameters_0.v"

module DDR2_infrastructure
  (
   
   input        sys_clk_n,
   input        sys_clk_p,
   input        sys_clk,
   input        clk200_n,
   input        clk200_p,
   input        idly_clk_200,

   output       clk_0,
   output       clk_90,
   output       clk_200, 
   input        idelay_ctrl_rdy,
   input        sys_reset_in_n,
   output       sys_rst,
   output       sys_rst90,
   output       sys_rst200
   );

   // # of clock cycles to delay deassertion of reset. Needs to be a fairly
   // high number not so much for metastability protection, but to give time
   // for reset (i.e. stable clock cycles) to propagate through all state
   // machines and to all control signals (i.e. not all control signals have
   // resets, instead they rely on base state logic being reset, and the effect
   // of that reset propagating through the logic). Need this because we may not
   // be getting stable clock cycles while reset asserted (i.e. since reset
   // depends on DCM lock status)

   localparam RST_SYNC_NUM = 25;

   
   wire                   clk0_bufg_in;
   wire                   clk90_bufg_in;
   wire                   clk0_bufg_out;
   wire                   clk90_bufg_out;
   wire                   clk200_bufg_out;
   wire                   dcm_lock;

   wire                   ref_clk200_in;
   wire                   sys_clk_in;

   wire                   sys_reset;

   reg [RST_SYNC_NUM-1:0] rst0_sync_r;
   reg [RST_SYNC_NUM-1:0] rst200_sync_r;
   reg [RST_SYNC_NUM-1:0] rst90_sync_r;
   wire                   rst_tmp;

   assign sys_reset = `RESET_ACTIVE_LOW ? ~sys_reset_in_n: sys_reset_in_n;

   
   assign clk_0       = clk0_bufg_out;
   assign clk_90      = clk90_bufg_out;
   assign clk_200     = clk200_bufg_out;

   generate
   if(`CLK_TYPE == "DIFFERENTIAL") begin : DIFF_ENDED_CLKS_INST

     IBUFGDS_LVPECL_25  SYS_CLK_INST
       (
        .I  (sys_clk_p),
        .IB (sys_clk_n),
        .O  (sys_clk_in)
        );

     IBUFGDS_LVPECL_25 IDLY_CLK_INST
       (
        .I  (clk200_p),
        .IB (clk200_n),
        .O  (ref_clk200_in)
        );

   end else if(`CLK_TYPE == "SINGLE_ENDED") begin : SINGLE_ENDED_CLKS_INST
     IBUFG  SYS_CLK_INST
       (
        .I  (sys_clk),
        .O  (sys_clk_in)
        );

     IBUFG IDLY_CLK_INST
       (
        .I  (idly_clk_200),
        .O  (ref_clk200_in)
        );

   end
   endgenerate

   BUFG CLK_200_BUFG
     (
      .O (clk200_bufg_out),
      .I (ref_clk200_in)
      );

   DCM_BASE #
     (
      .DLL_FREQUENCY_MODE    ("HIGH"),
      .DUTY_CYCLE_CORRECTION ("TRUE"),
      .FACTORY_JF            (16'hF0F0)
      )
   DCM_BASE0
     (
      .CLK0      (clk0_bufg_in),
      .CLK180    (),
      .CLK270    (),
      .CLK2X     (),
      .CLK2X180  (),
      .CLK90     (clk90_bufg_in),
      .CLKDV     (),
      .CLKFX     (),
      .CLKFX180  (),
      .LOCKED    (dcm_lock),
      .CLKFB     (clk0_bufg_out),
      .CLKIN     (sys_clk_in),
      .RST       (sys_reset)
      );

   BUFG DCM_CLK0
     (
      .O (clk0_bufg_out),
      .I (clk0_bufg_in)
      );

   BUFG DCM_CLK90
     (
      .O (clk90_bufg_out),
      .I (clk90_bufg_in)
      );

   //***************************************************************************
   // Reset synchronization
   // NOTES:
   //   1. shut down the whole operation if the DCM hasn't yet locked (and by
   //      inference, this means that external SYS_RST_IN has been asserted -
   //      DCM deasserts DCM_LOCK as soon as SYS_RST_IN asserted)
   //   2. In the case of all resets except rst200, also assert reset if the
   //      IDELAY master controller is not yet ready
   //   3. asynchronously assert reset. This was we can assert reset even if
   //      there is no clock (needed for things like 3-stating output buffers).
   //      reset deassertion is synchronous.
   //***************************************************************************

   assign rst_tmp = ~dcm_lock | ~idelay_ctrl_rdy | sys_reset;

   always @(posedge clk_0  or posedge rst_tmp)
     if (rst_tmp)
       rst0_sync_r <= {RST_SYNC_NUM{1'b1}};
     else
       // logical left shift by one (pads with 0)
       rst0_sync_r <= rst0_sync_r << 1;

   always @(posedge clk_90  or posedge rst_tmp)
     if (rst_tmp)
       rst90_sync_r <= {RST_SYNC_NUM{1'b1}};
     else
       rst90_sync_r <= rst90_sync_r << 1;

   // make sure CLK200 doesn't depend on IDELAY_CTRL_RDY, else chicken n' egg
   always @(posedge clk_200  or negedge dcm_lock)
     if (!dcm_lock)
       rst200_sync_r <= {RST_SYNC_NUM{1'b1}};
     else
       rst200_sync_r <= rst200_sync_r << 1;


   assign sys_rst    = rst0_sync_r[RST_SYNC_NUM-1];
   assign sys_rst90  = rst90_sync_r[RST_SYNC_NUM-1];
   assign sys_rst200 = rst200_sync_r[RST_SYNC_NUM-1];

endmodule
