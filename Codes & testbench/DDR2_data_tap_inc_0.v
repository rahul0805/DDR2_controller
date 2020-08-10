`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_data_tap_inc_0
  (
   input                               clk,
   input                               reset,
   input [`DATABITSPERSTROBE-1:0]      calibration_dq,
   input                               ctrl_calib_start,
   input                               dlyinc,
   input                               dlyce,
   input                               chan_done,

   output                              dq_data,
   output [`DATABITSPERSTROBE-1:0]     data_dlyinc,
   output [`DATABITSPERSTROBE-1:0]     data_dlyce,
   output [`DATABITSPERSTROBE-1:0]     data_dlyrst,
   output                              calib_done,
   output reg [`DATABITSPERSTROBE-1:0] per_bit_skew
   );

   wire                                muxout_d0d1;
   wire                                muxout_d2d3;
   wire                                muxout_d4d5;
   wire                                muxout_d6d7;
   wire                                muxout_d0_to_d3;
   wire                                muxout_d4_to_d7;
   wire [`DATABITSPERSTROBE-1:0]       data_dlyinc_int;
   wire [`DATABITSPERSTROBE-1:0]       data_dlyce_int;
   reg                                 calib_done_int;
   reg                                 calib_done_int_r1;
   reg [`DATABITSPERSTROBE-1:0]        calibration_dq_r
                                       /* synthesis syn_maxfan = 5 */
                                       /* synthesis syn_preserve=1 */;

   reg [`DATABITSPERSTROBE-1:0]        chan_sel_int
                                       /* synthesis syn_maxfan = 5 */;
   wire [`DATABITSPERSTROBE-1:0]       chan_sel;

   reg                                 reset_r1
                                       /* synthesis syn_preserve=1 */;

  //***************************************************************************

   assign data_dlyrst = {`DATABITSPERSTROBE{reset_r1}};
   assign data_dlyinc = data_dlyinc_int;
   assign data_dlyce  = data_dlyce_int;
   assign calib_done  = calib_done_int;

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   always @( posedge clk )
     calib_done_int_r1 <= calib_done_int;

   // synthesis attribute max_fanout of calibration_dq_r is 5
   // synthesis attribute equivalent_register_removal of calibration_dq_r is "no";
   always @(posedge clk) begin
      calibration_dq_r <=  calibration_dq;
   end

   
   // DQ Data Select Mux
   //Stage 1 Muxes
   assign muxout_d0d1 = chan_sel[1] ? calibration_dq_r[1] : calibration_dq_r[0];
   assign muxout_d2d3 = chan_sel[3] ? calibration_dq_r[3] : calibration_dq_r[2];
   assign muxout_d4d5 = chan_sel[5] ? calibration_dq_r[5] : calibration_dq_r[4];
   assign muxout_d6d7 = chan_sel[7] ? calibration_dq_r[7] : calibration_dq_r[6];

   //Stage 2 Muxes
   assign muxout_d0_to_d3 = (chan_sel[2] | chan_sel[3]) ?  muxout_d2d3:
                            muxout_d0d1;
   assign muxout_d4_to_d7 = (chan_sel[6] | chan_sel[7]) ?  muxout_d6d7:
                            muxout_d4d5;

   //Stage 3 Muxes
   assign dq_data = (chan_sel[4] | chan_sel[5] | chan_sel[6] | chan_sel[7]) ?
                    muxout_d4_to_d7: muxout_d0_to_d3;

   

   // RC: After calibration is complete, the Q1 output of each IDDR in the DQS
   // group is recorded. It should either be a static 1 or 0, depending on
   // which bit time is aligned to the rising edge of the FPGA CLK. If some
   // of the bits are 0, and some are 1 - this indicates there is "bit-
   // misalignment" within that DQS group. This will be handled later during
   // pattern calibration and by enabling the delay/swap circuit to delay
   // certain IDDR outputs by one bit time. For now, just record this "offset
   // pattern" and provide this to the pattern calibration logic.
   always @(posedge clk) begin
     if (reset_r1 || (!calib_done_int))
       per_bit_skew = `DATABITSPERSTROBE'd0;
     else if (calib_done_int && (!calib_done_int_r1))
       // Store offset pattern immediately after per-bit calib finished
       per_bit_skew = calibration_dq;
   end

   generate
      genvar i;
      for (i=0; i<=`DATABITSPERSTROBE-1; i=i+1)
        begin :  dlyce_dlyinc
           assign data_dlyce_int[i] = chan_sel[i] ? dlyce : 1'b0;
           assign data_dlyinc_int[i] = chan_sel[i] ? dlyinc : 1'b0;
        end
   endgenerate

   // module that controls the calib_done.
   always @(posedge clk)
     if (reset_r1)
       calib_done_int <= 1'b0;
     else if (ctrl_calib_start)
       if (~|chan_sel)
         calib_done_int <= 1'b1;

   // module that controls the chan_sel.
   // synthesis attribute max_fanout of chan_sel_int is 5
   always @(posedge clk)
     if (reset_r1)
       chan_sel_int <= `DATABITSPERSTROBE'd1;
     else if (ctrl_calib_start)
       if (chan_done)
         chan_sel_int <= chan_sel_int << 1;

   generate
      genvar      j;
      for (j=0; j<=`DATABITSPERSTROBE-1; j=j+1)
        begin :  chan_sel_gen
           assign chan_sel[j] = chan_sel_int[j];
        end
   endgenerate


endmodule
