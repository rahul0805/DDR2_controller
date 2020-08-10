`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_user_interface_0
  (
   input                            clk,
   input                            clk90,
   input                            reset,
   input [`DATA_WIDTH-1:0]          read_data_rise,
   input [`DATA_WIDTH-1:0]          read_data_fall,
   input                            ctrl_rden,
   input [`DATA_WIDTH-1:0]          per_bit_skew,
   input                            init_done,
   input [35:0]                     app_af_addr,
   input                            app_af_wren,
   input                            ctrl_af_rden,
   input [(`DQ_WIDTH*2)-1:0]        app_wdf_data,
   input [(`DM_WIDTH*2)-1:0]        app_mask_data,
   input                            app_wdf_wren,
   input                            ctrl_wdf_rden,
				    
   output [35:0]                    af_addr,
   output                           af_empty,
   output                           af_almost_full,
   output [(`DQ_WIDTH*2)-1:0]       read_data_fifo_out,

   output                           read_data_valid,	    
	    
   output [(`DQ_WIDTH*2)-1:0]       wdf_data,
   output [(`DM_WIDTH*2)-1:0]       mask_data,
   output [`DATA_WIDTH-1:0]         delay_enable,
   output                           comp_done,
   		    
   output                           wdf_almost_full,
   output                           cal_first_loop,

   // Debug Signals
   output [`DATA_STROBE_WIDTH-1:0]  dbg_first_rising,
   output [`DATA_STROBE_WIDTH-1:0]  dbg_cal_first_loop,
   output [`DATA_STROBE_WIDTH-1:0]  dbg_comp_done,
   output [`DATA_STROBE_WIDTH-1:0]  dbg_comp_error
   );

   wire [`DQ_WIDTH-1:0]         read_data_fifo_rise_i;
   wire [`DQ_WIDTH-1:0]         read_data_fifo_fall_i;




   assign read_data_fifo_out  =  {read_data_fifo_rise_i, read_data_fifo_fall_i};

   DDR2_rd_data_0 rd_data_00
     (
      .clk                  (clk),
      .reset                (reset),
      .ctrl_rden            (ctrl_rden),
      .read_data_rise       (read_data_rise),
      .read_data_fall       (read_data_fall),
      .per_bit_skew         (per_bit_skew),
      .delay_enable         (delay_enable),
      .read_data_fifo_rise  (read_data_fifo_rise_i),
      .read_data_fifo_fall  (read_data_fifo_fall_i),
      .read_data_valid      (read_data_valid),
      .comp_done            (comp_done),
      .cal_first_loop       (cal_first_loop),

      // Debug Signals
      .dbg_first_rising     (dbg_first_rising),
      .dbg_cal_first_loop   (dbg_cal_first_loop),
      .dbg_comp_done        (dbg_comp_done),
      .dbg_comp_error       (dbg_comp_error)
      );

   DDR2_backend_fifos_0 backend_fifos_00
     (
      .clk0                 (clk),
      .clk90                (clk90),
      .rst                  (reset),
      .init_done            (init_done),
      .app_af_addr          (app_af_addr),
      .app_af_wren          (app_af_wren),
      .ctrl_af_rden         (ctrl_af_rden),
      .af_addr              (af_addr),
      .af_empty             (af_empty),
      .af_almost_full       (af_almost_full),
      .app_wdf_data         (app_wdf_data),
      .app_mask_data        (app_mask_data),
      .app_wdf_wren         (app_wdf_wren),
      .ctrl_wdf_rden        (ctrl_wdf_rden),
      .wdf_data             (wdf_data),
      .mask_data            (mask_data),
      .wdf_almost_full      (wdf_almost_full)
      );


endmodule
