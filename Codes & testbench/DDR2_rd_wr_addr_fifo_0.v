`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_rd_wr_addr_fifo_0
  (
   input         clk0,
   input         clk90,
   input         rst,
   input [35:0]  app_af_addr,
   input         app_af_wren,
   input         ctrl_af_rden,

   output [35:0] af_addr,
   output        af_empty,
   output reg    af_almost_full
   );

   wire [35:0]   fifo_input_write_addr;
   wire [35:0]   fifo_output_write_addr;

   reg [35:0]    compare_value_r;
   reg [35:0]    app_af_addr_r;
   reg [35:0]    fifo_input_addr_r;
   reg           af_en_r;
   reg           af_en_2r;
   wire          compare_result;

   wire          clk270;
   wire          af_al_full_0;

   reg           af_en_2r_270;
   reg [35:0]    fifo_input_270;

   reg           af_al_full_180;
   reg           af_al_full_90;

   reg           rst_r1
                 /* synthesis syn_preserve=1 */;

   // [31:29]  -- command to controller
   // [28]     -- conflict bit
   // [27:0]   --- address

   assign fifo_input_write_addr[35:0] = {compare_result, app_af_addr_r[34:0]};
   assign af_addr[35:0]              = fifo_output_write_addr;
   assign compare_result = (compare_value_r[`CHIP_ADDRESS + `BANK_ADDRESS +
                                            `ROW_ADDRESS + `COLUMN_ADDRESS-1:
                                            `COLUMN_ADDRESS] ==
                            fifo_input_write_addr[`CHIP_ADDRESS + `BANK_ADDRESS
                                                  +`ROW_ADDRESS+`COLUMN_ADDRESS
                                                  - 1: `COLUMN_ADDRESS]) ? 1'b0
                           : 1'b1;

   assign        clk270 = ~clk90;

   // synthesis attribute equivalent_register_removal of rst_r1 is "no";
   always @( posedge clk0 )
     rst_r1 <= rst;

   always @(posedge clk0) begin
      if(af_en_r)
        compare_value_r<= fifo_input_write_addr;
      app_af_addr_r[35:0]     <= app_af_addr[35:0];
      fifo_input_addr_r[35:0] <= fifo_input_write_addr[35:0];
   end

   always @(posedge clk0) begin
      if(rst_r1) begin
         af_en_r              <= 1'b0;
         af_en_2r             <= 1'b0;
      end
      else begin
         af_en_r              <= app_af_wren;
         af_en_2r             <= af_en_r;
      end
   end

   // A fix for FIFO16 according to answer record #22462

   always @(posedge clk270) begin
      af_en_2r_270 <= af_en_2r;
      fifo_input_270  <= fifo_input_addr_r;
   end

   // 3 Filp-flops logic is implemented at output to avoid the timimg errors

   always @(negedge clk0)
     af_al_full_180 <= af_al_full_0;

   always @(posedge clk90)
     af_al_full_90 <= af_al_full_180;

   always @(posedge clk0)
     af_almost_full <= af_al_full_90;

   // Read/Write Address FIFO

   FIFO16 #
     (
      .ALMOST_EMPTY_OFFSET     (12'h007),
      .ALMOST_FULL_OFFSET      (12'h00F),
      .DATA_WIDTH              (36),
      .FIRST_WORD_FALL_THROUGH ("TRUE")
      )
     af_fifo16
       (
        .ALMOSTEMPTY    (),
        .ALMOSTFULL     (af_al_full_0),
        .DO             (fifo_output_write_addr[31:0]),
        .DOP            (fifo_output_write_addr[35:32]),
        .EMPTY          (af_empty),
        .FULL           (),
        .RDCOUNT        (),
        .RDERR          (),
        .WRCOUNT        (),
        .WRERR          (),
        .DI             (fifo_input_270[31:0]),
        .DIP            (fifo_input_270[35:32]),
        .RDCLK          (clk0),
        .RDEN           (ctrl_af_rden),
        .RST            (rst_r1),
        .WRCLK          (clk270),
        .WREN           (af_en_2r_270)
        );

endmodule
