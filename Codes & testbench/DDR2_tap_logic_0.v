`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

(* X_CORE_INFO = "ddr2_dc_v4, Coregen 12.4" , CORE_GENERATION_INFO = "ddr2_dc_v4,mig_v3_61,{component_name=DDR2_tap_logic_0, data_width=32, data_strobe_width=4, data_mask_width=4, clk_width=2, fifo_16=2, cs_width=1, odt_width=1, cke_width=1, row_address=13, registered=0, single_rank=1, dual_rank=0, databitsperstrobe=8, mask_enable=0, use_dm_port=0, column_address=10, bank_address=2, debug_en=0, load_mode_register=13'b0011001000011, ext_load_mode_register=13'b0000000001000, chip_address=1, ecc_enable=0, ecc_width=0, reset_active_low=1'b1, tby4tapvalue=14, rfc_count_value=8'b00011001, ras_count_value=5'b01001, rcd_count_value=3'b011, rp_count_value=3'b011, trtp_count_value=3'b001, twr_count_value=3'b100, twtr_count_value=3'b001, max_ref_width=11, max_ref_cnt=11'b11101010001, language=Verilog, synthesis_tool=ISE, interface_type=DDR2_SDRAM_Direct_Clocking, no_of_controllers=1}" *)
module DDR2_tap_logic_0
  (
   input                             clk,
   input                             reset0,
   input                             ctrl_dummyread_start,
   input [`DATA_WIDTH-1:0]           calibration_dq,
   output                            sel_done,
   output [`DATA_WIDTH-1:0]          data_idelay_inc,
   output [`DATA_WIDTH-1:0]          data_idelay_ce,
   output [`DATA_WIDTH-1:0]          data_idelay_rst,
   output [`DATA_WIDTH-1:0]          per_bit_skew,

   // Debug Signals
   input                             dbg_idel_up_all,
   input                             dbg_idel_down_all,
   input                             dbg_idel_up_dq,
   input                             dbg_idel_down_dq,
   input [`DQ_BITS-1:0]              dbg_sel_idel_dq,
   input                             dbg_sel_all_idel_dq,
   output [(6*`DATA_WIDTH)-1:0]      dbg_calib_dq_tap_cnt,
   output [`DATA_STROBE_WIDTH-1:0]   dbg_data_tap_inc_done,
   output                            dbg_sel_done
   );

   wire [`DATA_STROBE_WIDTH-1:0]     dlyinc_dqs;
   wire [`DATA_STROBE_WIDTH-1:0]     dlyce_dqs;
   wire [`DATA_WIDTH-1:0]            data_dlyinc;
   wire [`DATA_WIDTH-1:0]            data_dlyce;
   reg  [`DATA_WIDTH-1:0]            data_dlyinc_r;
   reg  [`DATA_WIDTH-1:0]            data_dlyce_r;
   wire [`DATA_STROBE_WIDTH-1:0]     chan_done_dqs;
   wire [`DATA_STROBE_WIDTH-1:0]     dq_data_dqs;
   wire [`DATA_STROBE_WIDTH-1:0]     calib_done_dqs;

   reg                               data_tap_inc_done;
   reg                               tap_sel_done;

   reg                               reset0_r1
                                     /* synthesis syn_preserve=1 */;

   // Debug
   integer                        x;
   reg [5:0]                     dbg_dq_tap_cnt [`DATA_WIDTH-1:0];

  //***************************************************************************

   // For controller to stop dummy reads
   assign sel_done = tap_sel_done;

   // synthesis attribute equivalent_register_removal of reset0_r1 is "no";
   always @( posedge clk )
     reset0_r1 <= reset0;

   // All DQS set groups calibrated for each bit of correspoding DQS set
   // After all DQS sets calibrated, per bit calibration completed flag
   // tap_sel_done asserted
   always @ (posedge clk) begin
      if (reset0_r1 == 1'b1) begin
         data_tap_inc_done   <= 1'b0;
         tap_sel_done        <= 1'b0;
      end
      else begin
         data_tap_inc_done   <= (&calib_done_dqs[`DATA_STROBE_WIDTH-1:0]);
         tap_sel_done        <= (data_tap_inc_done);
      end
   end

  //***************************************************************************
  // Debug output ("dbg_*")
  // NOTES:
  //  1. All debug outputs coming out of TAP_LOGIC are clocked off CLK0,
  //     although they are also static after calibration is complete. This
  //     means the user can either connect them to a Chipscope ILA, or to
  //     either a sync/async VIO input block. Using an async VIO has the
  //     advantage of not requiring these paths to meet cycle-to-cycle timing.
  //  2. The widths of most of these debug buses are dependent on the # of
  //     DQS/DQ bits (e.g. dq_tap_cnt width = 6 * (# of DQ bits)
  // SIGNAL DESCRIPTION:
  //  1. tap_sel_done:      1 bit - asserted as per bit calibration 
  //                        (first stage) is completed.
  //  2. data_tap_inc_done: # of DQS bits - each one asserted when 
  //                        per bit calibration is completed for 
  //                        corresponding byte.
  //  3. calib_dq_tap_cnt:  final IDELAY tap counts for all DQ IDELAYs
  //***************************************************************************

   assign dbg_sel_done = tap_sel_done;
   assign dbg_data_tap_inc_done = calib_done_dqs;

   assign data_idelay_ce  = `DEBUG_EN ? data_dlyce_r : data_dlyce;
   assign data_idelay_inc = `DEBUG_EN ? data_dlyinc_r : data_dlyinc;

  always @ (posedge clk) begin
    if (reset0_r1) begin
      data_dlyce_r  <= 'b0;
      data_dlyinc_r <= 'b0;
    end else begin
      data_dlyce_r  <= 'b0;
      data_dlyinc_r <= 'b0;

      if (!data_tap_inc_done) begin
        data_dlyce_r  <= data_dlyce;
        data_dlyinc_r <= data_dlyinc;
      end else if ( `DEBUG_EN == 1 ) begin
        // DEBUG: allow user to vary IDELAY tap settings
        // For DQ IDELAY taps
	if (dbg_idel_up_all || dbg_idel_down_all ||
            dbg_sel_all_idel_dq) begin
          for (x = 0; x < `DATA_WIDTH; x = x + 1) begin: loop_dly_inc_dq
            data_dlyce_r[x]  <= dbg_idel_up_all | dbg_idel_down_all |
                                  dbg_idel_up_dq  | dbg_idel_down_dq;
            data_dlyinc_r[x] <= dbg_idel_up_all | dbg_idel_up_dq;
          end
        end else begin
          data_dlyce_r <= 'b0;
          data_dlyce_r[dbg_sel_idel_dq]  <= dbg_idel_up_dq | dbg_idel_down_dq;
          data_dlyinc_r[dbg_sel_idel_dq] <= dbg_idel_up_dq;
        end
      end
    end
  end

  //*****************************************************************
  // Record IDELAY tap values by "snooping" IDELAY control signals
  //*****************************************************************

  // record DQ IDELAY tap values
  genvar dbg_dq_tc_i;
  generate
    for (dbg_dq_tc_i = 0; dbg_dq_tc_i < `DATA_WIDTH;
         dbg_dq_tc_i = dbg_dq_tc_i + 1) begin: gen_dbg_dq_tap_cnt
      assign dbg_calib_dq_tap_cnt[(6*dbg_dq_tc_i)+5:(6*dbg_dq_tc_i)]
               = dbg_dq_tap_cnt[dbg_dq_tc_i];
    always @(posedge clk)
      if (reset0_r1)
        dbg_dq_tap_cnt[dbg_dq_tc_i] <= 6'b000000;
      else
        if (data_idelay_ce[dbg_dq_tc_i])
          if (data_idelay_inc[dbg_dq_tc_i])
            dbg_dq_tap_cnt[dbg_dq_tc_i]
              <= dbg_dq_tap_cnt[dbg_dq_tc_i] + 1;
          else
            dbg_dq_tap_cnt[dbg_dq_tc_i]
              <= dbg_dq_tap_cnt[dbg_dq_tc_i] - 1;
      end
  endgenerate

   //***************************************************************************
   // tap_ctrl instances
   //***************************************************************************

   genvar dqs_i;
   generate
     for(dqs_i = 0; dqs_i < `DATA_STROBE_WIDTH; dqs_i = dqs_i+1)
     begin: gen_tap_ctrl
       DDR2_tap_ctrl_0 u_tap_ctrl_dqs
         (
          .clk                   (clk),
          .reset                 (reset0),
          .dq_data               (dq_data_dqs[dqs_i]),
          .ctrl_dummyread_start  (ctrl_dummyread_start),
          .dlyinc                (dlyinc_dqs[dqs_i]),
          .dlyce                 (dlyce_dqs[dqs_i]),
          .chan_done             (chan_done_dqs[dqs_i])
          );
     end
   endgenerate

   //***************************************************************************
   // data_tap_inc instances
   //***************************************************************************

   genvar dqs_ii;
   generate
     for(dqs_ii = 0; dqs_ii < `DATA_STROBE_WIDTH; dqs_ii = dqs_ii+1)
     begin: gen_data_tap_inc
       DDR2_data_tap_inc_0 u_data_tap_inc
         (
          .clk                (clk),
          .reset              (reset0),
          .calibration_dq     (calibration_dq[(`DATABITSPERSTROBE*(dqs_ii+1))-1:
                                              `DATABITSPERSTROBE*dqs_ii]),
          .ctrl_calib_start   (ctrl_dummyread_start),
          .dlyinc             (dlyinc_dqs[dqs_ii]),
          .dlyce              (dlyce_dqs[dqs_ii]),
          .chan_done          (chan_done_dqs[dqs_ii]),
          .dq_data            (dq_data_dqs[dqs_ii]),
          .data_dlyinc      (data_dlyinc[(`DATABITSPERSTROBE*(dqs_ii+1))-1:
                                             `DATABITSPERSTROBE*dqs_ii]),
          .data_dlyce       (data_dlyce[(`DATABITSPERSTROBE*(dqs_ii+1))-1:
                                            `DATABITSPERSTROBE*dqs_ii]),
          .data_dlyrst      (data_idelay_rst[(`DATABITSPERSTROBE*(dqs_ii+1))-1:
                                             `DATABITSPERSTROBE*dqs_ii]),
          .calib_done       (calib_done_dqs[dqs_ii]),
          .per_bit_skew       (per_bit_skew[(`DATABITSPERSTROBE*(dqs_ii+1))-1:
                                             `DATABITSPERSTROBE*dqs_ii])
          );
     end
   endgenerate


endmodule
