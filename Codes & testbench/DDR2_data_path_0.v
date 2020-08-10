`timescale 1ns/1ps

`include "../rtl/DDR2_parameters_0.v"

module DDR2_data_path_0
  (
   input                               clk,
   input                               clk90,
   input                               reset0,
   input                               reset90,
   input                               ctrl_dummyread_start,
   input [(`DQ_WIDTH*2)-1:0]           wdf_data,
   input [(`DM_WIDTH*2)-1:0]           mask_data,
   input                               ctrl_wren,
   input                               ctrl_dqs_rst,
   input                               ctrl_dqs_en,
   input                               ctrl_dummy_wr_sel,
   input [`DATA_WIDTH-1:0]             calibration_dq,

   output [`DATA_WIDTH-1:0]            data_idelay_inc,
   output [`DATA_WIDTH-1:0]            data_idelay_ce,
   output [`DATA_WIDTH-1:0]            data_idelay_rst,

   output                              sel_done,
   output                              dqs_rst,
   output                              dqs_en,
   output [1:0]                        wr_en,
   output                              dm_wr_en,
   output [`DATA_WIDTH-1:0]            wr_data_rise,
   output [`DATA_WIDTH-1:0]            wr_data_fall,
   output [`DATA_WIDTH-1:0]            per_bit_skew,

   output [`DATA_MASK_WIDTH-1:0]   mask_data_rise,
   output [`DATA_MASK_WIDTH-1:0]   mask_data_fall,

   // Debug Signals
   input                           dbg_idel_up_all,
   input                           dbg_idel_down_all,
   input                           dbg_idel_up_dq,
   input                           dbg_idel_down_dq,
   input [`DQ_BITS-1:0]            dbg_sel_idel_dq,
   input                           dbg_sel_all_idel_dq,
   output [(6*`DATA_WIDTH)-1:0]    dbg_calib_dq_tap_cnt,
   output [`DATA_STROBE_WIDTH-1:0] dbg_data_tap_inc_done,
   output                          dbg_sel_done
   );

   DDR2_data_write_0  data_write_0
     (
      .clk                  (clk),
      .clk90                (clk90),
      .reset90              (reset90),
      .wdf_data             (wdf_data),
      .mask_data            (mask_data),
      .ctrl_wren            (ctrl_wren),
      .ctrl_dqs_rst         (ctrl_dqs_rst),
      .ctrl_dqs_en          (ctrl_dqs_en),
      .dqs_rst              (dqs_rst),
      .dqs_en               (dqs_en),
      .wr_en                (wr_en),
      .dm_wr_en             (dm_wr_en),
      .wr_data_rise         (wr_data_rise),
      .wr_data_fall         (wr_data_fall),
      .mask_data_rise       (mask_data_rise),
      .mask_data_fall       (mask_data_fall)
      );






   DDR2_tap_logic_0 tap_logic_00
     (
      .clk                    (clk),
      .reset0                 (reset0),
      .ctrl_dummyread_start   (ctrl_dummyread_start),
      .calibration_dq         (calibration_dq),
      .data_idelay_inc        (data_idelay_inc),
      .data_idelay_ce         (data_idelay_ce),
      .data_idelay_rst        (data_idelay_rst),
      .sel_done               (sel_done),
      .per_bit_skew           (per_bit_skew),

      // Debug Signals
      .dbg_idel_up_all        (dbg_idel_up_all),
      .dbg_idel_down_all      (dbg_idel_down_all),
      .dbg_idel_up_dq         (dbg_idel_up_dq),
      .dbg_idel_down_dq       (dbg_idel_down_dq),
      .dbg_sel_idel_dq        (dbg_sel_idel_dq),
      .dbg_sel_all_idel_dq    (dbg_sel_all_idel_dq),
      .dbg_calib_dq_tap_cnt   (dbg_calib_dq_tap_cnt),
      .dbg_data_tap_inc_done  (dbg_data_tap_inc_done),
      .dbg_sel_done           (dbg_sel_done)
      );

endmodule
