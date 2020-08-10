`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

(* X_CORE_INFO = "ddr2_dc_v4, Coregen 12.4" , CORE_GENERATION_INFO = "ddr2_dc_v4,mig_v3_61,{component_name=DDR2_iobs_0, data_width=32, data_strobe_width=4, data_mask_width=4, clk_width=2, fifo_16=2, cs_width=1, odt_width=1, cke_width=1, row_address=13, registered=0, single_rank=1, dual_rank=0, databitsperstrobe=8, mask_enable=0, use_dm_port=0, column_address=10, bank_address=2, debug_en=0, load_mode_register=13'b0011001000011, ext_load_mode_register=13'b0000000001000, chip_address=1, ecc_enable=0, ecc_width=0, reset_active_low=1'b1, tby4tapvalue=14, rfc_count_value=8'b00011001, ras_count_value=5'b01001, rcd_count_value=3'b011, rp_count_value=3'b011, trtp_count_value=3'b001, twr_count_value=3'b100, twtr_count_value=3'b001, max_ref_width=11, max_ref_cnt=11'b11101010001, language=Verilog, synthesis_tool=ISE, interface_type=DDR2_SDRAM_Direct_Clocking, no_of_controllers=1}" *)
module DDR2_iobs_0
  (
   input                            clk,
   input                            clk90,
   input                            reset0,
   output [`CLK_WIDTH-1:0]          ddr_ck,
   output [`CLK_WIDTH-1:0]          ddr_ck_n,

   input [`DATA_WIDTH-1:0]          data_idelay_inc,
   input [`DATA_WIDTH-1:0]          data_idelay_ce,
   input [`DATA_WIDTH-1:0]          data_idelay_rst,
   input [`DATA_WIDTH-1:0]          delay_enable,

   input                            dqs_rst,
   input                            dqs_en,
   input [1:0]                      wr_en,
   input                            dm_wr_en,
   input [`DATA_WIDTH-1:0]          wr_data_rise,
   input [`DATA_WIDTH-1:0]          wr_data_fall,
   input [`DATA_MASK_WIDTH-1:0]     mask_data_rise,
   input [`DATA_MASK_WIDTH-1:0]     mask_data_fall,
   inout [`DATA_WIDTH-1:0]          ddr_dq,
   inout [`DATA_STROBE_WIDTH-1:0]   ddr_dqs,
   inout [`DATA_STROBE_WIDTH-1:0]   ddr_dqs_l,
   output [`DATA_MASK_WIDTH-1:0]    ddr_dm,
   output [`DATA_WIDTH-1:0]         rd_data_rise,
   output [`DATA_WIDTH-1:0]         rd_data_fall,

   input [`ROW_ADDRESS-1  :0]       ctrl_ddr2_address,
   input [`BANK_ADDRESS-1 :0]       ctrl_ddr2_ba,
   input                            ctrl_ddr2_ras_l,
   input                            ctrl_ddr2_cas_l,
   input                            ctrl_ddr2_we_l,
   input [`CS_WIDTH-1:0]            ctrl_ddr2_cs_l,
   input [`CKE_WIDTH-1:0]           ctrl_ddr2_cke,
   input [`ODT_WIDTH-1:0]           ctrl_ddr2_odt,

   output [`ROW_ADDRESS-1  :0]      ddr_address,
   output [`BANK_ADDRESS-1 :0]      ddr_ba,
   output                           ddr_ras_l,
   output                           ddr_cas_l,
   output                           ddr_we_l,
   output [`CKE_WIDTH-1:0]          ddr_cke,
   output [`ODT_WIDTH-1:0]          ddr_odt,
   output [`CS_WIDTH-1:0]           ddr_cs_l
   );

  //***************************************************************************

   DDR2_infrastructure_iobs_0 infrastructure_iobs_00
     (
      .clk                  (clk),
      .ddr_ck               (ddr_ck),
      .ddr_ck_n             (ddr_ck_n)
      );

   DDR2_data_path_iobs_0 data_path_iobs_00
     (
      .clk                  (clk),
      .clk90                (clk90),
      .reset0               (reset0),
      .dqs_rst              (dqs_rst),
      .dqs_en               (dqs_en),
      .delay_enable         (delay_enable),
      .data_idelay_inc      (data_idelay_inc),
      .data_idelay_ce       (data_idelay_ce),
      .data_idelay_rst      (data_idelay_rst),
      .wr_data_rise         (wr_data_rise),
      .wr_data_fall         (wr_data_fall),
      .wr_en                (wr_en),
      .dm_wr_en             (dm_wr_en),
      .rd_data_rise         (rd_data_rise),
      .rd_data_fall         (rd_data_fall),
      .mask_data_rise       (mask_data_rise),
      .mask_data_fall       (mask_data_fall),
      .ddr_dq               (ddr_dq),
      .ddr_dqs              (ddr_dqs),
      .ddr_dqs_l            (ddr_dqs_l),
      .ddr_dm               (ddr_dm)
      );

   DDR2_controller_iobs_0 controller_iobs_00
     (
      .ctrl_ddr2_address    (ctrl_ddr2_address),
      .ctrl_ddr2_ba         (ctrl_ddr2_ba),
      .ctrl_ddr2_ras_l      (ctrl_ddr2_ras_l),
      .ctrl_ddr2_cas_l      (ctrl_ddr2_cas_l),
      .ctrl_ddr2_we_l       (ctrl_ddr2_we_l),
      .ctrl_ddr2_cs_l       (ctrl_ddr2_cs_l),
      .ctrl_ddr2_cke        (ctrl_ddr2_cke),
      .ctrl_ddr2_odt        (ctrl_ddr2_odt),

      .ddr_address          (ddr_address),
      .ddr_ba               (ddr_ba),
      .ddr_ras_l            (ddr_ras_l),
      .ddr_cas_l            (ddr_cas_l),
      .ddr_we_l             (ddr_we_l),
      .ddr_cke              (ddr_cke),
      .ddr_odt              (ddr_odt),
      .ddr_cs_l             (ddr_cs_l)
      );

endmodule
