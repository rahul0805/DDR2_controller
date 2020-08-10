`timescale 1ns/1ps

`include "../rtl/DDR2_parameters_0.v"


module DDR2_rd_data_0
  (
   in
	put                            clk,
   input                            reset,
   input                            ctrl_rden,
   input [`DATA_WIDTH-1:0]          read_data_rise,
   input [`DATA_WIDTH-1:0]          read_data_fall,
   input [`DATA_WIDTH-1:0]          per_bit_skew,
   output [`DATA_WIDTH-1:0]         delay_enable,
   output                           comp_done,
   output                           read_data_valid,
   output [`DATA_WIDTH-1:0]         read_data_fifo_rise,
   output [`DATA_WIDTH-1:0]         read_data_fifo_fall,
   output reg                       cal_first_loop,

   // Debug Signals
   output [`DATA_STROBE_WIDTH-1:0]  dbg_first_rising,
   output [`DATA_STROBE_WIDTH-1:0]  dbg_cal_first_loop,
   output [`DATA_STROBE_WIDTH-1:0]  dbg_comp_done,
   output [`DATA_STROBE_WIDTH-1:0]  dbg_comp_error
   );



   wire [`DATA_STROBE_WIDTH-1:0]    cal_first_loop_i;
   reg  [`DATA_STROBE_WIDTH-1:0]    cal_first_loop_r2;
   reg                              calib_done;
   wire [`DATA_STROBE_WIDTH-1:0]    comp_done_int;
   wire [`DATA_STROBE_WIDTH-1:0]    comp_error_i;
   reg                              comp_error;
   reg                              fifo_read_enable_r;
   reg                              fifo_read_enable_2r;
   wire [`DATA_STROBE_WIDTH-1:0]    first_rising_int;
   wire [`DATA_STROBE_WIDTH-1:0]    read_en_delayed_rise;
   wire [`DATA_STROBE_WIDTH-1:0]    read_en_delayed_fall;
   wire [`DATA_STROBE_WIDTH-1:0]    read_data_valid_i;
   reg                              reset_r1
                                    /* synthesis syn_preserve=1 */;

   //***************************************************************************

  //***************************************************************************
  // Debug output ("dbg_*")
  // NOTES:
  //  1. All debug outputs coming out of RD_DATA are clocked off CLK0,
  //     although they are also static after calibration is complete. This
  //     means the user can either connect them to a Chipscope ILA, or to
  //     either a sync/async VIO input block. Using an async VIO has the
  //     advantage of not requiring these paths to meet cycle-to-cycle timing.
  //  2. The widths of most of these debug buses are dependent on the # of
  //     DQS/DQ bits (e.g. first_rising = (# of DQS bits)
  // SIGNAL DESCRIPTION:
  //  1. first_rising:   # of DQS bits - asserted for each byte if rise and 
  //                     fall data arrive "staggered" w/r to each other.
  //  2. cal_first_loop: # of DQS bits - deasserted ('0') for corresponding byte 
  //                     if pattern calibration is not completed on 
  //                     first pattern read command.
  //  3. comp_done:      #of DQS bits - each one asserted as pattern calibration 
  //                     (second stage) is completed for corresponding byte.
  //  4. comp_error:     # of DQS bits - each one asserted when a calibration 
  //                     error encountered in pattern calibrtation stage for 
  //                     corresponding byte. 
  //***************************************************************************

   assign dbg_first_rising   = first_rising_int;
   assign dbg_cal_first_loop = cal_first_loop_r2;
   assign dbg_comp_done      = comp_done_int;
   assign dbg_comp_error     = comp_error_i;

   assign read_data_valid = read_data_valid_i[0];
   assign comp_done    = & comp_done_int[`DATA_STROBE_WIDTH-1:0] ;

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   always @( posedge clk )
     calib_done <= comp_done;

   always @( posedge clk )
     comp_error <= | comp_error_i;

   //***************************************************************************
   // cal_first_loop: Flag for controller to issue a second pattern calibration
   // read if the first one does not result in a successful calibration.
   // Second pattern calibration command is issued to all DQS sets by NANDing
   // of CAL_FIRST_LOOP from all PATTERN_COMPARE modules. The set calibrated on
   // first pattern calibration command ignores the second calibration command,
   // since it will in CAL_DONE state (in PATTERN_COMPARE module) for the ones
   // calibrated. The set that is not calibrated on first pattern calibration
   // command, is calibrated on second calibration command.
   //***************************************************************************

   always @( posedge clk )
     cal_first_loop_r2 <= cal_first_loop_i;

  always @(posedge clk)
    if(reset_r1)
      cal_first_loop <= 1'b1;
    else if ((cal_first_loop_r2 != cal_first_loop_i) && (~&cal_first_loop_i))
      cal_first_loop <= 1'b0;
    else
      cal_first_loop <= 1'b1;

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1) begin
         fifo_read_enable_r   <= 1'b0;
         fifo_read_enable_2r   <= 1'b0;
      end
      else begin
         fifo_read_enable_r   <= read_en_delayed_rise[0];
         fifo_read_enable_2r   <= fifo_read_enable_r;
      end
   end




   DDR2_pattern_compare8  pattern_0
     (
      .clk                    (clk),
      .rst                    (reset),
      .ctrl_rden              (ctrl_rden),
      .calib_done             (calib_done),
      .rd_data_rise           (read_data_rise[7:0]),
      .rd_data_fall           (read_data_fall[7:0]),
      .per_bit_skew           (per_bit_skew[7:0]),
      .delay_enable           (delay_enable[7:0]),
      .comp_error             (comp_error_i[0]),
      .comp_done              (comp_done_int[0]),
      .first_rising           (first_rising_int[0]),
      .rd_en_rise             (read_en_delayed_rise[0]),
      .rd_en_fall             (read_en_delayed_fall[0]),
      .cal_first_loop         (cal_first_loop_i[0])
      );


   DDR2_pattern_compare8  pattern_1
     (
      .clk                    (clk),
      .rst                    (reset),
      .ctrl_rden              (ctrl_rden),
      .calib_done             (calib_done),
      .rd_data_rise           (read_data_rise[15:8]),
      .rd_data_fall           (read_data_fall[15:8]),
      .per_bit_skew           (per_bit_skew[15:8]),
      .delay_enable           (delay_enable[15:8]),
      .comp_error             (comp_error_i[1]),
      .comp_done              (comp_done_int[1]),
      .first_rising           (first_rising_int[1]),
      .rd_en_rise             (read_en_delayed_rise[1]),
      .rd_en_fall             (read_en_delayed_fall[1]),
      .cal_first_loop         (cal_first_loop_i[1])
      );


   DDR2_pattern_compare8  pattern_2
     (
      .clk                    (clk),
      .rst                    (reset),
      .ctrl_rden              (ctrl_rden),
      .calib_done             (calib_done),
      .rd_data_rise           (read_data_rise[23:16]),
      .rd_data_fall           (read_data_fall[23:16]),
      .per_bit_skew           (per_bit_skew[23:16]),
      .delay_enable           (delay_enable[23:16]),
      .comp_error             (comp_error_i[2]),
      .comp_done              (comp_done_int[2]),
      .first_rising           (first_rising_int[2]),
      .rd_en_rise             (read_en_delayed_rise[2]),
      .rd_en_fall             (read_en_delayed_fall[2]),
      .cal_first_loop         (cal_first_loop_i[2])
      );


   DDR2_pattern_compare8  pattern_3
     (
      .clk                    (clk),
      .rst                    (reset),
      .ctrl_rden              (ctrl_rden),
      .calib_done             (calib_done),
      .rd_data_rise           (read_data_rise[31:24]),
      .rd_data_fall           (read_data_fall[31:24]),
      .per_bit_skew           (per_bit_skew[31:24]),
      .delay_enable           (delay_enable[31:24]),
      .comp_error             (comp_error_i[3]),
      .comp_done              (comp_done_int[3]),
      .first_rising           (first_rising_int[3]),
      .rd_en_rise             (read_en_delayed_rise[3]),
      .rd_en_fall             (read_en_delayed_fall[3]),
      .cal_first_loop         (cal_first_loop_i[3])
      );


   //***************************************************************************
   // rd_data_fifo instances
   //***************************************************************************

   genvar fifo_i;
   generate
     for(fifo_i = 0; fifo_i < `DATA_STROBE_WIDTH; fifo_i = fifo_i+1)
     begin: gen_rd_data_fifo
       DDR2_rd_data_fifo_0 u_rd_data_fifo
         (
          .clk                  (clk),
          .reset                (reset),
          .fifo_rd_en           (fifo_read_enable_2r),
          .read_en_delayed_rise (read_en_delayed_rise[fifo_i]),
          .read_en_delayed_fall (read_en_delayed_fall[fifo_i]),
          .first_rising         (first_rising_int[fifo_i]),
          .read_data_rise       (read_data_rise[(`MEMORY_WIDTH*(fifo_i+1))-1:
                                                `MEMORY_WIDTH*fifo_i]),
          .read_data_fall       (read_data_fall[(`MEMORY_WIDTH*(fifo_i+1))-1:
                                                `MEMORY_WIDTH*fifo_i]),
          .read_data_fifo_rise  (read_data_fifo_rise[(`MEMORY_WIDTH*(fifo_i+1))-1:
                                                     `MEMORY_WIDTH*fifo_i]),
          .read_data_fifo_fall  (read_data_fifo_fall[(`MEMORY_WIDTH*(fifo_i+1))-1:
                                                     `MEMORY_WIDTH*fifo_i]),
          .read_data_valid      (read_data_valid_i[fifo_i])
          );
     end
   endgenerate

endmodule
