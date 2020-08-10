`timescale 1ns/1ps

(* X_CORE_INFO = "mig_v3_61_ddr2_dc_v4, Coregen 12.4" *)
module DDR2
  (
   inout  [31:0]   cntrl0_ddr2_dq,
   output [12:0]   cntrl0_ddr2_a,
   output [1:0]    cntrl0_ddr2_ba,
   output          cntrl0_ddr2_ras_n,
   output          cntrl0_ddr2_cas_n,
   output          cntrl0_ddr2_we_n,
   output [0:0]    cntrl0_ddr2_cs_n,
   output [0:0]    cntrl0_ddr2_odt,
   output [0:0]    cntrl0_ddr2_cke,
   input           sys_clk,
   input           idly_clk_200,
   input           sys_reset_in_n,
   output          cntrl0_init_done,
   output          cntrl0_clk_tb,
   output          cntrl0_reset_tb,
   output          cntrl0_wdf_almost_full,
   output          cntrl0_af_almost_full,
   output          cntrl0_read_data_valid,
   input           cntrl0_app_wdf_wren,
   input           cntrl0_app_af_wren,
   output [2:0]    cntrl0_burst_length_div2,
   input  [35:0]   cntrl0_app_af_addr,
   output [63:0]   cntrl0_read_data_fifo_out,
   input  [63:0]   cntrl0_app_wdf_data,
   inout  [3:0]    cntrl0_ddr2_dqs,
   inout  [3:0]    cntrl0_ddr2_dqs_n,
   output [1:0]    cntrl0_ddr2_ck,
   output [1:0]    cntrl0_ddr2_ck_n
   ) /* synthesis syn_useioff = 1 */;

  wire clk_0;
  wire clk_90;
  wire clk_200;
  wire sys_rst;
  wire sys_rst90;
  wire sys_rst200;
  wire sys_clk_p;
  wire sys_clk_n;
  wire clk200_p;
  wire clk200_n;

  wire [0:0] dbg_idel_up_all;
  wire [0:0] dbg_idel_down_all;
  wire [0:0] dbg_idel_up_dq;
  wire [0:0] dbg_idel_down_dq;
  wire [4:0] dbg_sel_idel_dq;
  wire [0:0] dbg_sel_all_idel_dq;
  wire [191:0] dbg_calib_dq_tap_cnt;
  wire [3:0] dbg_data_tap_inc_done;
  wire [0:0] dbg_sel_done;
  wire [3:0] dbg_first_rising;
  wire [3:0] dbg_cal_first_loop;
  wire [3:0] dbg_comp_done;
  wire [3:0] dbg_comp_error;
  wire [0:0] dbg_init_done;

  //***********************************
  // PHY Debug Port demo
  //***********************************
  wire [35:0]  cs_control0;
  wire [35:0]  cs_control1;
  wire [35:0]  cs_control2;
  wire [192:0] vio0_in;
  wire [42:0]  vio1_in;
  wire [9:0]   vio2_out;

  assign sys_clk_p = 1'b1;
  assign sys_clk_n = 1'b0;
  assign clk200_p = 1'b1;
  assign clk200_n = 1'b0;

DDR2_top_0     top_00
   (
     .ddr2_dq                   (cntrl0_ddr2_dq),
     .ddr2_a                    (cntrl0_ddr2_a),
     .ddr2_ba                   (cntrl0_ddr2_ba),
     .ddr2_ras_n                (cntrl0_ddr2_ras_n),
     .ddr2_cas_n                (cntrl0_ddr2_cas_n),
     .ddr2_we_n                 (cntrl0_ddr2_we_n),
     .ddr2_cs_n                 (cntrl0_ddr2_cs_n),
     .ddr2_odt                  (cntrl0_ddr2_odt),
     .ddr2_cke                  (cntrl0_ddr2_cke),
     .init_done                 (cntrl0_init_done),
     .clk_tb                    (cntrl0_clk_tb),
     .reset_tb                  (cntrl0_reset_tb),
     .wdf_almost_full           (cntrl0_wdf_almost_full),
     .af_almost_full            (cntrl0_af_almost_full),
     .read_data_valid           (cntrl0_read_data_valid),
     .app_wdf_wren              (cntrl0_app_wdf_wren),
     .app_af_wren               (cntrl0_app_af_wren),
     .burst_length_div2         (cntrl0_burst_length_div2),
     .app_af_addr               (cntrl0_app_af_addr),
     .read_data_fifo_out        (cntrl0_read_data_fifo_out),
     .app_wdf_data              (cntrl0_app_wdf_data),
     .app_mask_data             ({8{1'b0}}),
     .ddr2_dqs                  (cntrl0_ddr2_dqs),
     .ddr2_dqs_n                (cntrl0_ddr2_dqs_n),
     .ddr2_ck                   (cntrl0_ddr2_ck),
     .ddr2_ck_n                 (cntrl0_ddr2_ck_n),
     .ddr2_dm                (),
     //infrastructure signals,
     .clk_0                     (clk_0),
     .clk_90                    (clk_90),
     .sys_rst                   (sys_rst),
     .sys_rst90                 (sys_rst90),

     .dbg_idel_up_all              (dbg_idel_up_all),
     .dbg_idel_down_all            (dbg_idel_down_all),
     .dbg_idel_up_dq               (dbg_idel_up_dq),
     .dbg_idel_down_dq             (dbg_idel_down_dq),
     .dbg_sel_idel_dq              (dbg_sel_idel_dq),
     .dbg_sel_all_idel_dq          (dbg_sel_all_idel_dq),
     .dbg_calib_dq_tap_cnt         (dbg_calib_dq_tap_cnt),
     .dbg_data_tap_inc_done        (dbg_data_tap_inc_done),
     .dbg_sel_done                 (dbg_sel_done),
     .dbg_first_rising             (dbg_first_rising),
     .dbg_cal_first_loop           (dbg_cal_first_loop),
     .dbg_comp_done                (dbg_comp_done),
     .dbg_comp_error               (dbg_comp_error),
     .dbg_init_done                (dbg_init_done)   );


  DDR2_infrastructure infrastructure0
    (
     .sys_clk_p                 (sys_clk_p),
     .sys_clk_n                 (sys_clk_n),
     .clk200_p                  (clk200_p),
     .clk200_n                  (clk200_n),
     .sys_clk                   (sys_clk),
     .idly_clk_200              (idly_clk_200),
     .sys_reset_in_n            (sys_reset_in_n),
     .idelay_ctrl_rdy           (idelay_ctrl_rdy),
     .clk_0                     (clk_0),
     .clk_90                    (clk_90),
     .clk_200                   (clk_200),
     .sys_rst                   (sys_rst),
     .sys_rst90                 (sys_rst90),
     .sys_rst200                (sys_rst200)
     );

  DDR2_idelay_ctrl idelay_ctrl0
    (
     .clk200                    (clk_200),
     .reset                     (sys_rst200),
     .rdy_status                (idelay_ctrl_rdy)
     );

  //*************************************************************************
  // Hooks to prevent sim/syn compilation errors. When DEBUG_EN = 0, all the
  // debug input signals are floating. To avoid this, they are connected to
  // all zeros.
  //*************************************************************************
  assign dbg_idel_up_all       = 'b0;
  assign dbg_idel_down_all     = 'b0;
  assign dbg_idel_up_dq        = 'b0;
  assign dbg_idel_down_dq      = 'b0;
  assign dbg_sel_idel_dq       = 'b0;
  assign dbg_sel_all_idel_dq   = 'b0;


endmodule


