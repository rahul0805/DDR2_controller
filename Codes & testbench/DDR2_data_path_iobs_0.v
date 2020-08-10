`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_data_path_iobs_0
  (
   input                            clk,
   input                            clk90,
   input                            reset0,
   input [`DATA_WIDTH-1:0]          data_idelay_inc,
   input [`DATA_WIDTH-1:0]          data_idelay_ce,
   input [`DATA_WIDTH-1:0]          data_idelay_rst,
   input [`DATA_WIDTH-1:0]          delay_enable,
   input                            dqs_rst,
   input                            dqs_en,
   input [`DATA_WIDTH-1:0]          wr_data_rise,
   input [`DATA_WIDTH-1:0]          wr_data_fall,
   input [1:0]                      wr_en,
   input                            dm_wr_en,
   output [`DATA_WIDTH-1:0]         rd_data_rise,
   output [`DATA_WIDTH-1:0]         rd_data_fall,
   input [`DATA_MASK_WIDTH-1:0]     mask_data_rise,
   input [`DATA_MASK_WIDTH-1:0]     mask_data_fall,

   inout [`DATA_WIDTH-1:0]          ddr_dq,
   inout [`DATA_STROBE_WIDTH-1:0]   ddr_dqs,
   inout [`DATA_STROBE_WIDTH-1:0]   ddr_dqs_l,
   output [`DATA_MASK_WIDTH-1:0]    ddr_dm
   );

   //***************************************************************************

   //***************************************************************************
   // DQS instances
   //***************************************************************************

   genvar dqs_i;
   generate
     for(dqs_i = 0; dqs_i < `DATA_STROBE_WIDTH; dqs_i = dqs_i+1) begin: gen_dqs
         DDR2_v4_dqs_iob_0 u_iob_dqs
             (
              .clk              (clk),
              .reset            (reset0),
              .ctrl_dqs_rst     (dqs_rst),
              .ctrl_dqs_en      (dqs_en),
              .ddr_dqs          (ddr_dqs[dqs_i]),
              .ddr_dqs_l        (ddr_dqs_l[dqs_i])
              );
     end
   endgenerate


   //***************************************************************************
   // DM instances
   //***************************************************************************
   genvar dm_i;
   generate
     if (`USE_DM_PORT == 1'b1) begin: gen_dm_inst
       for(dm_i = 0; dm_i < `DATA_MASK_WIDTH; dm_i = dm_i+1) begin: gen_dm
         DDR2_v4_dm_iob u_iob_dm
           (
            .clk90           (clk90),
            .mask_data_rise  (mask_data_rise[dm_i]),
            .mask_data_fall  (mask_data_fall[dm_i]),
            .dm_wr_en        (dm_wr_en),
            .ddr_dm          (ddr_dm[dm_i])
            );
       end
     end
   endgenerate

   //***************************************************************************
   // DQ IOB instances
   //***************************************************************************

   genvar dq_i;
   generate
     for(dq_i = 0; dq_i < `DATA_WIDTH; dq_i = dq_i+1) begin: gen_dq
       DDR2_v4_dq_iob u_iob_dq
           (
            .clk              (clk),
            .clk90            (clk90),
            .reset0           (reset0),
            .data_dlyinc      (data_idelay_inc[dq_i]),
            .data_dlyce       (data_idelay_ce[dq_i]),
            .data_dlyrst      (data_idelay_rst[dq_i]),
            .write_data_rise  (wr_data_rise[dq_i]),
            .write_data_fall  (wr_data_fall[dq_i]),
            .ctrl_wren        (wr_en),
            .delay_enable     (delay_enable[dq_i]),
            .ddr_dq           (ddr_dq[dq_i]),
            .rd_data_rise     (rd_data_rise[dq_i]),
            .rd_data_fall     (rd_data_fall[dq_i])
            );
     end
   endgenerate

endmodule
