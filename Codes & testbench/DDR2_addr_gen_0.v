`timescale 1ns/1ps

module DDR2_addr_gen_0
  (
   input             clk0,
   input             rst,
   input             bkend_wraddr_en,
   //Write address fifo signals
   output reg [35:0] app_af_addr,
   output reg        app_af_wren
   );

   //***************************************************************************
   // ADDRESS generation for Write and Read Address FIFOs
   // RAM initialization patterns
   // RAMB16_S36 configuration set to 512x36 mode
   // INIP_OO: Refresh -1
   // INIP_OO: Precharge -2
   // INIP_OO: Write -4
   // INIP_OO: Read -5
   //***************************************************************************

   localparam RAM_INIT_00 = {128'h0003C154_0003C198_0003C088_0003C0EC,
                             128'h00023154_00023198_00023088_000230EC};
   localparam RAM_INIT_01 = {128'h00023154_00023198_00023088_000230EC,
                             128'h0003C154_0003C198_0003C088_0003C0EC};
   localparam RAM_INIT_02 = {128'h0083C154_0083C198_0083C088_0083C0EC,
                             128'h00823154_00823198_00823088_008230EC};
   localparam RAM_INIT_03 = {128'h0083C154_0083C198_0083C088_0083C0EC,
                             128'h00823154_00823198_00823088_008230EC};
   localparam RAM_INIT_04 = {128'h0043C154_0043C198_0043C088_0043C0EC,
                             128'h00423154_00423198_00423088_004230EC};
   localparam RAM_INIT_05 = {128'h0043C154_0043C198_0043C088_0043C0EC,
                             128'h00423154_00423198_00423088_004230EC};
   localparam RAM_INIT_06 = {128'h00C3C154_00C3C198_00C3C088_00C3C0EC,
                             128'h00C23154_00C23198_00C23088_00C230EC};
   localparam RAM_INIT_07 = {128'h00C3C154_00C3C198_00C3C088_00C3C0EC,
                             128'h00C23154_00C23198_00C23088_00C230EC};
   localparam RAM_INITP_00 = {128'h55555555_44444444_55555555_44444444,
                              128'h55555555_44444444_55555555_44444444};

   wire [8:0]    wr_rd_addr;
   wire          wr_rd_addr_en;

   reg [5:0]     wr_addr_count;
   reg           bkend_wraddr_en_reg;
   reg           wr_rd_addr_en_reg
                 /* synthesis syn_preserve=1 */;
   reg           bkend_wraddr_en_3r;

   wire [31:0]   unused_data_in;
   wire [3:0]    unused_data_in_p;
   wire          gnd;
   wire [35:0]   addr_out;

   reg           rst_r1
                 /* synthesis syn_preserve=1 */;

   assign        unused_data_in = 32'h00000000;
   assign        unused_data_in_p = 4'h0;
   assign        gnd = 1'b0;

   // synthesis attribute equivalent_register_removal of rst_r1 is "no";
   always @( posedge clk0 )
     rst_r1 <= rst;

   RAMB16_S36 #
     (
      .INIT_00   (RAM_INIT_00),
      .INIT_01   (RAM_INIT_01),
      .INIT_02   (RAM_INIT_02),
      .INIT_03   (RAM_INIT_03),
      .INIT_04   (RAM_INIT_04),
      .INIT_05   (RAM_INIT_05),
      .INIT_06   (RAM_INIT_06),
      .INIT_07   (RAM_INIT_07),
      .INITP_00  (RAM_INITP_00)
      )
     wr_rd_addr_lookup
       (
        .DO   (addr_out[31:0]),
        .DOP  (addr_out[35:32]),
        .ADDR (wr_rd_addr[8:0]),
        .CLK  (clk0),
        .DI   (unused_data_in[31:0]),
        .DIP  (unused_data_in_p[3:0]),
        .EN   (wr_rd_addr_en_reg),
        .SSR  (gnd),
        .WE   (gnd)
        );

   assign        wr_rd_addr_en = (bkend_wraddr_en == 1'b1);

// synthesis attribute equivalent_register_removal of wr_rd_addr_en_reg is "no";
   always @ (posedge clk0) begin
      if (rst_r1)
        wr_rd_addr_en_reg <= 1'b0;
      else
        wr_rd_addr_en_reg <= wr_rd_addr_en;
   end

   //register backend enables
   always @ (posedge clk0) begin
      if (rst_r1) begin
         bkend_wraddr_en_reg <= 1'b0;
         bkend_wraddr_en_3r  <= 1'b0;
      end
      else begin
         bkend_wraddr_en_reg <= bkend_wraddr_en;
         bkend_wraddr_en_3r  <= bkend_wraddr_en_reg;
      end
   end

   // Fifo enables
   always @ (posedge clk0) begin
      if (rst_r1)
        app_af_wren <= 1'b0;
      else
        app_af_wren <= bkend_wraddr_en_3r;
   end

   // FIFO addresses
   always @ (posedge clk0) begin
      if (bkend_wraddr_en_3r)
        app_af_addr <= addr_out;
      else
        app_af_addr <= 36'h00000;
   end

   // address input for RAM
   always @ (posedge clk0) begin
      if (rst_r1)
        wr_addr_count[5:0] <= 6'b111111;
      else if (bkend_wraddr_en)
        wr_addr_count[5:0] <= wr_addr_count[5:0] + 1;
      else
        wr_addr_count[5:0] <= wr_addr_count[5:0];
   end

   assign wr_rd_addr[8:0] = (bkend_wraddr_en_reg) ? {3'b000,wr_addr_count[5:0]}:
                            9'b000000000;

endmodule
