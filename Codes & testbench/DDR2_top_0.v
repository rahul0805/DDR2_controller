`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

(* X_CORE_INFO = "ddr2_dc_v4, Coregen 12.4" , CORE_GENERATION_INFO = "ddr2_dc_v4,mig_v3_61,{component_name=DDR2_top_0, data_width=32, data_strobe_width=4, data_mask_width=4, clk_width=2, fifo_16=2, cs_width=1, odt_width=1, cke_width=1, row_address=13, registered=0, single_rank=1, dual_rank=0, databitsperstrobe=8, mask_enable=0, use_dm_port=0, column_address=10, bank_address=2, debug_en=0, load_mode_register=13'b0011001000011, ext_load_mode_register=13'b0000000001000, chip_address=1, ecc_enable=0, ecc_width=0, reset_active_low=1'b1, tby4tapvalue=14, rfc_count_value=8'b00011001, ras_count_value=5'b01001, rcd_count_value=3'b011, rp_count_value=3'b011, trtp_count_value=3'b001, twr_count_value=3'b100, twtr_count_value=3'b001, max_ref_width=11, max_ref_cnt=11'b11101010001, language=Verilog, synthesis_tool=ISE, interface_type=DDR2_SDRAM_Direct_Clocking, no_of_controllers=1}" *)
module DDR2_top_0
  (
   input                           clk_0,
   input                           clk_90,
   input                           sys_rst,
   input                           sys_rst90,
   
   output                          ddr2_ras_n,
   output                          ddr2_cas_n,
   output                          ddr2_we_n,
   output [`ODT_WIDTH-1:0]         ddr2_odt,
   output [`CKE_WIDTH-1:0]         ddr2_cke,
   output [`CS_WIDTH-1:0]          ddr2_cs_n,

   inout [`DATA_WIDTH-1:0]         ddr2_dq,
   inout [`DATA_STROBE_WIDTH-1:0]  ddr2_dqs,
   inout [`DATA_STROBE_WIDTH-1:0]  ddr2_dqs_n,
   output [`DATA_MASK_WIDTH-1:0]   ddr2_dm,
   output [`BANK_ADDRESS-1:0]      ddr2_ba,
   output [`ROW_ADDRESS-1:0]       ddr2_a,
   output [`CLK_WIDTH-1:0]         ddr2_ck,
   output [`CLK_WIDTH-1:0]         ddr2_ck_n,

   //test bench signals
   output                          wdf_almost_full,
   output                          af_almost_full,
   output [2:0]                    burst_length_div2,
   output                          read_data_valid,
   output [(`DQ_WIDTH*2)-1:0]      read_data_fifo_out,
   input [35:0]                    app_af_addr,
   input                           app_af_wren,
   input [(`DQ_WIDTH*2)-1:0]       app_wdf_data,
   input [(`DM_WIDTH*2)-1:0]       app_mask_data,
   input                           app_wdf_wren,
   
   output                          clk_tb,
   output                          reset_tb,
   output                          init_done,

   // Debug Signals
   input                           dbg_idel_up_all,
   input                           dbg_idel_down_all,
   input                           dbg_idel_up_dq,
   input                           dbg_idel_down_dq,
   input [`DQ_BITS-1:0]            dbg_sel_idel_dq,
   input                           dbg_sel_all_idel_dq,
   output [(6*`DATA_WIDTH)-1:0]    dbg_calib_dq_tap_cnt,
   output [`DATA_STROBE_WIDTH-1:0] dbg_data_tap_inc_done,
   output                          dbg_sel_done,
   output [`DATA_STROBE_WIDTH-1:0] dbg_first_rising,
   output [`DATA_STROBE_WIDTH-1:0] dbg_cal_first_loop,
   output [`DATA_STROBE_WIDTH-1:0] dbg_comp_done,
   output [`DATA_STROBE_WIDTH-1:0] dbg_comp_error,
   output                          dbg_init_done
   );

   wire [(`DQ_WIDTH*2)-1:0]        wr_df_data;
   wire [(`DM_WIDTH*2)-1:0]        mask_df_data;
   wire [`DATA_WIDTH-1:0]          rd_data_rise;
   wire [`DATA_WIDTH-1:0]          rd_data_fall;

   wire                            af_empty_w;

   wire                            dq_tap_sel_done;
   wire [35:0]                     af_addr;
   wire                            ctrl_af_rden;
   wire                            ctrl_wr_df_rden;
   wire                            ctrl_dummy_rden;
   wire                            ctrl_dqs_enable;
   wire                            ctrl_dqs_reset;
   wire                            ctrl_wr_en;
   wire                            ctrl_rden;

   wire [`DATA_WIDTH-1:0]          data_idelay_inc;
   wire [`DATA_WIDTH-1:0]          data_idelay_ce;
   wire [`DATA_WIDTH-1:0]          data_idelay_rst;

   wire [1:0]                      wr_en;
   wire                            dm_wr_en;
   wire                            dqs_rst;
   wire                            dqs_en;

   wire [`DATA_WIDTH-1:0]          wr_data_rise;
   wire [`DATA_WIDTH-1:0]          wr_data_fall;
   wire [`DATA_MASK_WIDTH-1:0]     mask_data_fall;
   wire [`DATA_MASK_WIDTH-1:0]     mask_data_rise;
   wire [`ROW_ADDRESS-1:0]         ctrl_ddr2_address;
   wire [`BANK_ADDRESS-1:0]        ctrl_ddr2_ba;
   wire                            ctrl_ddr2_ras_l;
   wire                            ctrl_ddr2_cas_l;
   wire                            ctrl_ddr2_we_l;
   wire [`CS_WIDTH-1:0]            ctrl_ddr2_cs_l;
   wire [`CKE_WIDTH-1:0]           ctrl_ddr2_cke;
   wire [`ODT_WIDTH-1:0]           ctrl_ddr2_odt;

   wire                            ctrl_dummy_wr_sel;
   wire                            comp_done;
   wire                            cal_first_loop;

   wire [`DATA_WIDTH-1:0]          per_bit_skew;
   wire [`DATA_WIDTH-1:0]          delay_enable;

  //***************************************************************************

   assign                          clk_tb =clk_0;
   assign                          reset_tb = sys_rst;

   

   DDR2_data_path_0 data_path_00
     (
      .clk                   (clk_0),
      .clk90                 (clk_90),
      .reset0                (sys_rst),
      .reset90               (sys_rst90),
      .ctrl_dummyread_start  (ctrl_dummy_rden),
      .wdf_data              (wr_df_data),
      .mask_data             (mask_df_data),
      .ctrl_wren             (ctrl_wr_en),
      .ctrl_dqs_rst          (ctrl_dqs_reset),
      .ctrl_dqs_en           (ctrl_dqs_enable),
      .ctrl_dummy_wr_sel     (ctrl_dummy_wr_sel),
      .data_idelay_inc       (data_idelay_inc),
      .data_idelay_ce        (data_idelay_ce),
      .data_idelay_rst       (data_idelay_rst),
      .sel_done              (dq_tap_sel_done),
      .dqs_rst               (dqs_rst),
      .dqs_en                (dqs_en),
      .wr_en                 (wr_en),
      .dm_wr_en              (dm_wr_en),
      .wr_data_rise          (wr_data_rise),
      .wr_data_fall          (wr_data_fall),
      .mask_data_rise        (mask_data_rise),
      .mask_data_fall        (mask_data_fall),
      .calibration_dq        (rd_data_rise),
      .per_bit_skew          (per_bit_skew),

      // Debug Signals
      .dbg_idel_up_all       (dbg_idel_up_all),
      .dbg_idel_down_all     (dbg_idel_down_all),
      .dbg_idel_up_dq        (dbg_idel_up_dq),
      .dbg_idel_down_dq      (dbg_idel_down_dq),
      .dbg_sel_idel_dq       (dbg_sel_idel_dq),
      .dbg_sel_all_idel_dq   (dbg_sel_all_idel_dq),
      .dbg_calib_dq_tap_cnt  (dbg_calib_dq_tap_cnt),
      .dbg_data_tap_inc_done (dbg_data_tap_inc_done),
      .dbg_sel_done          (dbg_sel_done)
      );

   DDR2_iobs_0 iobs_00
     (
      .ddr_ck                (ddr2_ck),
      .ddr_ck_n              (ddr2_ck_n),

      .clk                   (clk_0),
      .clk90                 (clk_90),
      .reset0                (sys_rst),
      .data_idelay_inc       (data_idelay_inc),
      .data_idelay_ce        (data_idelay_ce),
      .data_idelay_rst       (data_idelay_rst),
      .delay_enable          (delay_enable),
      .dqs_rst               (dqs_rst),
      .dqs_en                (dqs_en),
      .wr_en                 (wr_en),
      .dm_wr_en              (dm_wr_en),
      .wr_data_rise          (wr_data_rise),
      .wr_data_fall          (wr_data_fall),
      .mask_data_rise        (mask_data_rise),
      .mask_data_fall        (mask_data_fall),
      .rd_data_rise          (rd_data_rise),
      .rd_data_fall          (rd_data_fall),
      .ddr_dq                (ddr2_dq),
      .ddr_dqs               (ddr2_dqs),
      .ddr_dqs_l             (ddr2_dqs_n),
      .ddr_dm                (ddr2_dm),
      .ctrl_ddr2_address     (ctrl_ddr2_address),
      .ctrl_ddr2_ba          (ctrl_ddr2_ba),
      .ctrl_ddr2_ras_l       (ctrl_ddr2_ras_l),
      .ctrl_ddr2_cas_l       (ctrl_ddr2_cas_l),
      .ctrl_ddr2_we_l        (ctrl_ddr2_we_l),
      .ctrl_ddr2_cs_l        (ctrl_ddr2_cs_l),
      .ctrl_ddr2_cke         (ctrl_ddr2_cke),
      .ctrl_ddr2_odt         (ctrl_ddr2_odt),
      .ddr_address           (ddr2_a),
      .ddr_ba                (ddr2_ba),
      .ddr_ras_l             (ddr2_ras_n),
      .ddr_cas_l             (ddr2_cas_n),
      .ddr_we_l              (ddr2_we_n),
      .ddr_cke               (ddr2_cke),
      .ddr_odt               (ddr2_odt),
      .ddr_cs_l              (ddr2_cs_n)
      );


   DDR2_user_interface_0 user_interface_00
     (
      .clk                   (clk_0),
      .clk90                 (clk_90),
      .reset                 (sys_rst),
      .read_data_rise        (rd_data_rise),
      .read_data_fall        (rd_data_fall),
      .ctrl_rden             (ctrl_rden),
      .per_bit_skew          (per_bit_skew),
      .init_done             (init_done),
      .delay_enable          (delay_enable),
      .read_data_fifo_out    (read_data_fifo_out),
      .read_data_valid       (read_data_valid),
      .af_empty              (af_empty_w),
      .af_almost_full        (af_almost_full),
      .app_af_addr           (app_af_addr),
      .app_af_wren           (app_af_wren),
      .ctrl_af_rden          (ctrl_af_rden),
      .af_addr               (af_addr),
      .app_wdf_data          (app_wdf_data),
      .app_mask_data         (app_mask_data),
      .app_wdf_wren          (app_wdf_wren),
      .ctrl_wdf_rden         (ctrl_wr_df_rden),
      .wdf_data              (wr_df_data),
      .mask_data             (mask_df_data),
      .wdf_almost_full       (wdf_almost_full),
      
      .comp_done             (comp_done),
      .cal_first_loop        (cal_first_loop),

      // Debug Signals
      .dbg_first_rising      (dbg_first_rising),
      .dbg_cal_first_loop    (dbg_cal_first_loop),
      .dbg_comp_done         (dbg_comp_done),
      .dbg_comp_error        (dbg_comp_error)
      );


   DDR2_ddr2_controller_0 ddr2_controller_00
     (
      .clk0                  (clk_0),
      .rst                   (sys_rst),
      .burst_length_div2     (burst_length_div2),
      .af_addr               (af_addr),
      .af_empty              (af_empty_w),
      .phy_dly_slct_done     (dq_tap_sel_done),
      .ctrl_dummyread_start  (ctrl_dummy_rden),
      .ctrl_af_rden          (ctrl_af_rden),
      .ctrl_wdf_rden         (ctrl_wr_df_rden),
      .ctrl_dqs_rst          (ctrl_dqs_reset),
      .ctrl_dqs_en           (ctrl_dqs_enable),
      .ctrl_wren             (ctrl_wr_en),
      .ctrl_rden             (ctrl_rden),
      .ctrl_ddr2_address     (ctrl_ddr2_address),
      .ctrl_ddr2_ba          (ctrl_ddr2_ba),
      .ctrl_ddr2_ras_l       (ctrl_ddr2_ras_l),
      .ctrl_ddr2_cas_l       (ctrl_ddr2_cas_l),
      .ctrl_ddr2_we_l        (ctrl_ddr2_we_l),
      .ctrl_ddr2_cs_l        (ctrl_ddr2_cs_l),
      .ctrl_ddr2_cke         (ctrl_ddr2_cke),
      .ctrl_ddr2_odt         (ctrl_ddr2_odt),
      .ctrl_dummy_wr_sel     (ctrl_dummy_wr_sel),
      .comp_done             (comp_done),
      .init_done             (init_done),
      .cal_first_loop        (cal_first_loop),

      // Debug Signals
      .dbg_init_done         (dbg_init_done)
      );


endmodule
