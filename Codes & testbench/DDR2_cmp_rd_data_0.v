`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_cmp_rd_data_0
  (
   input                     clk,
   input                     reset,
   input                     read_data_valid,
   input [(`DQ_WIDTH*2)-1:0] app_compare_data,
   input [(`DQ_WIDTH*2)-1:0] read_data_fifo_out,

   output                    error
   );

   reg                       valid;
   reg [`DM_WIDTH-1:0]       byte_err_rising;
   reg [`DM_WIDTH-1:0]       byte_err_falling;

   wire [`DM_WIDTH-1:0]      byte_err_rising_w;
   wire [`DM_WIDTH-1:0]      byte_err_falling_w;

   reg                       valid_1;
   reg [(`DQ_WIDTH*2)-1:0]   read_data_r;
   reg [(`DQ_WIDTH*2)-1:0]   read_data_r2;
   reg [(`DQ_WIDTH*2)-1:0]   write_data_r2;

   wire [`DQ_WIDTH-1:0]      data_pattern_falling;
   wire [`DQ_WIDTH-1:0]      data_pattern_rising;
   wire [`DQ_WIDTH-1:0]      data_falling;
   wire [`DQ_WIDTH-1:0]      data_rising;
   reg                       falling_error;
   reg                       rising_error;

   wire                      byte_err_rising_a;
   wire                      byte_err_falling_a;

   reg                       error_r1;
   reg                       error_r2;

   reg                       reset_r1
                             /* synthesis syn_preserve=1 */;

  //***************************************************************************

   assign data_falling         = read_data_r2[`DQ_WIDTH-1:0];
   assign data_rising          = read_data_r2[(`DQ_WIDTH*2)-1:`DQ_WIDTH];

   assign data_pattern_falling = write_data_r2[`DQ_WIDTH-1:0];
   assign data_pattern_rising  = write_data_r2[(`DQ_WIDTH*2)-1:`DQ_WIDTH];


   assign byte_err_falling_w[0] =   ((valid_1 == 1'b1) && (data_falling[7:0] != data_pattern_falling[7:0]))? 1'b1 : 1'b0;


   assign byte_err_falling_w[1] =   ((valid_1 == 1'b1) && (data_falling[15:8] != data_pattern_falling[15:8]))? 1'b1 : 1'b0;


   assign byte_err_falling_w[2] =   ((valid_1 == 1'b1) && (data_falling[23:16] != data_pattern_falling[23:16]))? 1'b1 : 1'b0;


   assign byte_err_falling_w[3] =   ((valid_1 == 1'b1) && (data_falling[31:24] != data_pattern_falling[31:24]))? 1'b1 : 1'b0;


   assign byte_err_rising_w[0] =   ((valid_1 == 1'b1) && (data_rising[7:0] != data_pattern_rising[7:0]))? 1'b1 : 1'b0;


   assign byte_err_rising_w[1] =   ((valid_1 == 1'b1) && (data_rising[15:8] != data_pattern_rising[15:8]))? 1'b1 : 1'b0;


   assign byte_err_rising_w[2] =   ((valid_1 == 1'b1) && (data_rising[23:16] != data_pattern_rising[23:16]))? 1'b1 : 1'b0;


   assign byte_err_rising_w[3] =   ((valid_1 == 1'b1) && (data_rising[31:24] != data_pattern_rising[31:24]))? 1'b1 : 1'b0;


   assign byte_err_rising_a    = |byte_err_rising[`DQ_WIDTH/8-1:0];
   assign byte_err_falling_a   = |byte_err_falling[`DQ_WIDTH/8-1:0];

   assign error = error_r2;

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   always @ (posedge clk) begin
      byte_err_rising[`DM_WIDTH-1:0]  <= byte_err_falling_w[`DM_WIDTH-1:0];
      byte_err_falling[`DM_WIDTH-1:0] <= byte_err_rising_w[`DM_WIDTH-1:0];
   end

   always @ (posedge clk) begin
      rising_error  <= byte_err_rising_a;
      falling_error <= byte_err_falling_a;
      error_r1      <= rising_error || falling_error;
   end

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1)
        error_r2 <= 1'b0;
      else if(error_r2 == 1'b0)
        error_r2 <= error_r1;
      else
        error_r2 <= error_r2;
   end

   //synthesis translate_off
   always @ (posedge clk) begin
      if (error_r1)
        $display ("DATA ERROR at time %t" , $time);
   end
   //synthesis translate_on

   always @ (posedge clk) begin
      read_data_r <= read_data_fifo_out;
   end

   always @ (posedge clk) begin
      read_data_r2 <= read_data_r;
      write_data_r2 <= app_compare_data;
   end

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1) begin
         valid   <= 1'b0;
         valid_1 <= 1'b0;
      end
      else begin
         valid   <= read_data_valid;
         valid_1 <= valid;
      end
   end

endmodule
