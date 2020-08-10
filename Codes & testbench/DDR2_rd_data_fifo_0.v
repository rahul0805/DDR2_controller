`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_rd_data_fifo_0
  (
   input                       clk,
   input                       reset,
   input                       fifo_rd_en,
   input                       read_en_delayed_rise,
   input                       read_en_delayed_fall,
   input                       first_rising,
   input [`MEMORY_WIDTH-1:0]   read_data_rise,
   input [`MEMORY_WIDTH-1:0]   read_data_fall,

   output                      read_data_valid,
   output [`MEMORY_WIDTH-1:0]  read_data_fifo_rise,
   output [`MEMORY_WIDTH-1:0]  read_data_fifo_fall
   );

   reg [`MEMORY_WIDTH*2-1:0]   fifos_data_out1;
   reg [3:0]                   fifo_rd_addr;
   reg [3:0]                   rise0_wr_addr;
   reg [3:0]                   fall0_wr_addr;
   reg                         fifo_rd_en_r0;
   reg                         fifo_rd_en_r1;
   reg                         fifo_rd_en_r2;
   reg [`MEMORY_WIDTH-1:0]     rise_fifo_data;
   reg [`MEMORY_WIDTH-1:0]     fall_fifo_data;

   wire [`MEMORY_WIDTH-1:0]    rise_fifo_out;
   wire [`MEMORY_WIDTH-1:0]    fall_fifo_out;

   reg                         reset_r1
                               /* synthesis syn_preserve=1 */;

   assign read_data_valid     = fifo_rd_en_r2;
   assign read_data_fifo_fall = fifos_data_out1[`MEMORY_WIDTH-1:0];
   assign read_data_fifo_rise = fifos_data_out1[`MEMORY_WIDTH*2-1 :
                                                `MEMORY_WIDTH];

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   // Read Pointer and fifo data output sequencing

   // Read Enable generation for fifos based on write enable

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1) begin
         fifo_rd_en_r0          <= 1'b0;
         fifo_rd_en_r1          <= 1'b0;
         fifo_rd_en_r2          <= 1'b0;
      end
      else begin
         fifo_rd_en_r0          <= fifo_rd_en ;
         fifo_rd_en_r1          <= fifo_rd_en_r0;
         fifo_rd_en_r2          <= fifo_rd_en_r1;
      end
   end

   // Write Pointer increment for FIFOs

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1)
        rise0_wr_addr[3:0] <= 4'h0;
      else if (read_en_delayed_rise == 1'b1)
        rise0_wr_addr[3:0] <= rise0_wr_addr[3:0] + 1'b1;
   end

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1)
        fall0_wr_addr[3:0] <= 4'h0;
      else if (read_en_delayed_fall == 1'b1)
        fall0_wr_addr[3:0] <= fall0_wr_addr[3:0] + 1'b1;
   end

   ///////////// FIFO Data Output Sequencing /////////////////////////

   always @ (posedge clk) begin
      if (fifo_rd_en_r0 == 1'b1) begin
         rise_fifo_data[`MEMORY_WIDTH-1:0] <= rise_fifo_out[`MEMORY_WIDTH-1:0];
         fall_fifo_data[`MEMORY_WIDTH-1:0] <= fall_fifo_out[`MEMORY_WIDTH-1:0];
      end
   end

   always @ (posedge clk) begin
      if (reset_r1 == 1'b1)
         fifo_rd_addr[3:0]   <= 4'h0;
      else if (fifo_rd_en_r0 == 1'b1)
         fifo_rd_addr[3:0]    <= fifo_rd_addr[3:0] + 1'b1;
   end

   always @ (posedge clk)
     begin
        if (reset_r1 == 1'b1)
          fifos_data_out1[`MEMORY_WIDTH*2-1:0] <= 16'h0000;
        else if (fifo_rd_en_r1 == 1'b1) begin
           if (first_rising == 1'b1)
             fifos_data_out1[`MEMORY_WIDTH*2-1:0] <= {fall_fifo_data,
                                                      rise_fifo_data};
           else
             fifos_data_out1[`MEMORY_WIDTH*2-1:0] <= {rise_fifo_data,
                                                      fall_fifo_data};
        end
     end

   //**************************************************************************
   // Distributed RAM 4 bit wide FIFO instantiations (2 FIFOs per strobe,
   // rising edge data fifo and falling edge data fifo)
   //**************************************************************************
   // FIFOs associated with DQS(0)

     DDR2_ram_d_0 ram_rise0
       (
        .dpo     (rise_fifo_out[`MEMORY_WIDTH-1:0]),
        .a0      (rise0_wr_addr[0]),
        .a1      (rise0_wr_addr[1]),
        .a2      (rise0_wr_addr[2]),
        .a3      (rise0_wr_addr[3]),
        .d       (read_data_rise[`MEMORY_WIDTH-1:0]),
        .dpra0   (fifo_rd_addr[0]),
        .dpra1   (fifo_rd_addr[1]),
        .dpra2   (fifo_rd_addr[2]),
        .dpra3   (fifo_rd_addr[3]),
        .wclk    (clk),
        .we      (read_en_delayed_rise)
        );

   DDR2_ram_d_0 ram_fall0
     (
      .dpo     (fall_fifo_out[`MEMORY_WIDTH-1:0]),
      .a0      (fall0_wr_addr[0]),
      .a1      (fall0_wr_addr[1]),
      .a2      (fall0_wr_addr[2]),
      .a3      (fall0_wr_addr[3]),
      .d       (read_data_fall[`MEMORY_WIDTH-1:0]),
      .dpra0   (fifo_rd_addr[0]),
      .dpra1   (fifo_rd_addr[1]),
      .dpra2   (fifo_rd_addr[2]),
      .dpra3   (fifo_rd_addr[3]),
      .wclk    (clk),
      .we      (read_en_delayed_fall)
      );


endmodule
