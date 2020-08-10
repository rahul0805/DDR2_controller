`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_backend_rom_0
  (
   input                       clk0,
   input                       rst,
   // enables signals from state machine
   input                       bkend_data_en,
   input                       bkend_wraddr_en,
   input                       bkend_rd_data_valid,
   // write address fifo signals
   output [35:0]               app_af_addr,
   output                      app_af_wren,
   // write data fifo signals
   output [(`DQ_WIDTH*2)-1:0]  app_wdf_data,
   output [(`DM_WIDTH*2)-1:0]  app_mask_data,
   // data for the backend compare logic
   output [(`DQ_WIDTH*2)-1:0]  app_compare_data,
   output                      app_wdf_wren
   );

   wire [`FIFO_16-1:0]          app_wdf_wren_w;


   wire [31:0]                 app_wdf_data0;
   wire [31:0]                 app_wdf_data1;



   wire [3:0]                  app_mask_data0;
   wire [3:0]                  app_mask_data1;



   wire [31:0]                 app_compare_data0;
   wire [31:0]                 app_compare_data1;


   assign app_wdf_data = { app_wdf_data1[31:16],app_wdf_data0[31:16] ,
                           app_wdf_data1[15:0],app_wdf_data0[15:0]};

   assign app_mask_data = { app_mask_data1[3:2],app_mask_data0[3:2] ,
                            app_mask_data1[1:0],app_mask_data0[1:0]};

   assign app_compare_data = { app_compare_data1[31:16],app_compare_data0[31:16] ,
                               app_compare_data1[15:0],app_compare_data0[15:0]};

   assign app_wdf_wren = app_wdf_wren_w[`FIFO_16-1];


   DDR2_addr_gen_0 addr_gen_00
     (
      .clk0               (clk0),
      .rst                (rst),
      .bkend_wraddr_en    (bkend_wraddr_en),
      .app_af_addr        (app_af_addr),
      .app_af_wren        (app_af_wren)
      );


   DDR2_data_gen_16 data_gen_16_0
     (
      .clk0                 (clk0),
      .rst                  (rst),
      .bkend_data_en        (bkend_data_en),
      .bkend_rd_data_valid  (bkend_rd_data_valid),
      .app_wdf_data         (app_wdf_data0[31:0]),
      .app_mask_data        (app_mask_data0[3:0]),
      .app_compare_data     (app_compare_data0[31:0]),
      .app_wdf_wren         (app_wdf_wren_w[0])
      );


   DDR2_data_gen_16 data_gen_16_1
     (
      .clk0                 (clk0),
      .rst                  (rst),
      .bkend_data_en        (bkend_data_en),
      .bkend_rd_data_valid  (bkend_rd_data_valid),
      .app_wdf_data         (app_wdf_data1[31:0]),
      .app_mask_data        (app_mask_data1[3:0]),
      .app_compare_data     (app_compare_data1[31:0]),
      .app_wdf_wren         (app_wdf_wren_w[1])
      );



endmodule
