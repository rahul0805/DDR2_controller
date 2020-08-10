`timescale 1ns/1ps

module DDR2_data_gen_16
  (
   input             clk0,
   input             rst,
   // enables signals from state machine
   input             bkend_data_en,
   input             bkend_rd_data_valid,
   // write data fifo signals
   output reg [31:0] app_wdf_data,
   output reg [3:0]  app_mask_data,
   // data for the backend compare logic
   output [31:0]     app_compare_data,
   output reg        app_wdf_wren
   ) /* synthesis syn_preserve=1 */;

   localparam     WR_IDLE_FIRST_DATA   =  2'b00;
   localparam     WR_SECOND_DATA       =  2'b01;
   localparam     WR_THIRD_DATA        =  2'b10;
   localparam     WR_FOURTH_DATA       =  2'b11;

   localparam     RD_IDLE_FIRST_DATA   =  2'b00;
   localparam     RD_SECOND_DATA       =  2'b01;
   localparam     RD_THIRD_DATA        =  2'b10;
   localparam     RD_FOURTH_DATA       =  2'b11;

   reg [1:0]      wr_state;
   reg [1:0]      rd_state;
   reg [15:0]     wr_data_pattern ;
   reg [15:0]     rd_data_pattern ;

   reg            app_wdf_wren_r;
   reg            app_wdf_wren_2r;
   reg            app_wdf_wren_3r;
   reg            bkend_rd_data_valid_r;

   wire [31:0]    app_wdf_data_r ;
   reg [31:0]     app_wdf_data_1r ;
   reg [31:0]     app_wdf_data_2r ;

   wire [3:0]     app_mask_data_r ;
   reg [3:0]      app_mask_data_1r ;
   reg [3:0]      app_mask_data_2r ;

   wire [15:0]    rd_rising_edge_data;
   wire [15:0]    rd_falling_edge_data;
   wire [1:0]     wr_data_mask_fall;
   wire [1:0]     wr_data_mask_rise;

   reg            rst_r1
                  /* synthesis syn_preserve=1 */;

   //***************************************************************************

   assign         wr_data_mask_rise = 2'd0;
   assign         wr_data_mask_fall = 2'd0;

   // synthesis attribute equivalent_register_removal of rst_r1 is "no";
   always @( posedge clk0 )
     rst_r1 <= rst;

   // DATA generation for WRITE DATA FIFOs & for READ DATA COMPARE

   // write data generation
   always @ (posedge clk0) begin
      if (rst_r1) begin
         wr_data_pattern[15:0] <= 16'h0000;
         wr_state <= WR_IDLE_FIRST_DATA;
      end
      else begin
         case (wr_state)
           WR_IDLE_FIRST_DATA :  begin
              if (bkend_data_en == 1'b1) begin
                 wr_data_pattern[15:0] <= 16'hFFFF;
                 wr_state <= WR_SECOND_DATA;
              end
              else
                wr_state <= WR_IDLE_FIRST_DATA;
           end

           WR_SECOND_DATA :      begin
              if (bkend_data_en == 1'b1) begin
                 wr_data_pattern[15:0] <= 16'hAAAA;
                 wr_state <= WR_THIRD_DATA;
              end
              else
                wr_state <= WR_SECOND_DATA;
           end

           WR_THIRD_DATA :       begin
              if (bkend_data_en == 1'b1) begin
                 wr_data_pattern[15:0] <= 16'h5555;
                 wr_state <= WR_FOURTH_DATA;
              end
              else
                wr_state <= WR_THIRD_DATA;
           end

           WR_FOURTH_DATA :      begin
              if (bkend_data_en == 1'b1) begin
                 wr_data_pattern[15:0] <= 16'h9999;
                 wr_state <= WR_IDLE_FIRST_DATA;
              end
              else
                wr_state <= WR_FOURTH_DATA;
           end
         endcase
      end
   end

   assign app_wdf_data_r[31:0] = (app_wdf_wren_r) ? {wr_data_pattern[15:0],
                                                     ~wr_data_pattern[15:0]} :
                                 32'h00000000;

   assign app_mask_data_r[3:0] = (app_wdf_wren_r) ? {wr_data_mask_rise[1:0],
                                                     wr_data_mask_fall[1:0]} :
                                 4'h0;

   always @ (posedge clk0) begin
      app_wdf_data_1r <= app_wdf_data_r ;
      app_wdf_data_2r <= app_wdf_data_1r;
      app_wdf_data    <= app_wdf_data_2r;
   end

   always @ (posedge clk0) begin
      app_mask_data_1r <= app_mask_data_r ;
      app_mask_data_2r <= app_mask_data_1r;
      app_mask_data    <= app_mask_data_2r;
   end

   always @ (posedge clk0) begin
      if (rst_r1) begin
         app_wdf_wren_r  <= 1'b0;
         app_wdf_wren_2r <= 1'b0;
         app_wdf_wren_3r <= 1'b0;
         app_wdf_wren    <= 1'b0;
      end
      else begin
         app_wdf_wren_r  <= bkend_data_en;
         app_wdf_wren_2r <= app_wdf_wren_r;
         app_wdf_wren_3r <= app_wdf_wren_2r;
         app_wdf_wren    <= app_wdf_wren_3r;
      end
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        bkend_rd_data_valid_r <= 1'b0;
      else
        bkend_rd_data_valid_r <= bkend_rd_data_valid;
   end

   // read comparison data generation
   always @ (posedge clk0) begin
      if (rst_r1) begin
         rd_data_pattern[15:0] <= 16'h0000;
         rd_state <= RD_IDLE_FIRST_DATA;
      end
      else begin
         case (rd_state)

           RD_IDLE_FIRST_DATA :  begin
              if (bkend_rd_data_valid) begin
                 rd_data_pattern[15:0] <= 16'hFFFF;
                 rd_state <= RD_SECOND_DATA;
              end
              else
                rd_state <= RD_IDLE_FIRST_DATA;
           end

           RD_SECOND_DATA :      begin
              rd_data_pattern[15:0] <= 16'hAAAA;
              rd_state <= RD_THIRD_DATA;
           end

           RD_THIRD_DATA :      begin
              if (bkend_rd_data_valid) begin
                 rd_data_pattern[15:0] <= 16'h5555;
                 rd_state <= RD_FOURTH_DATA;
              end
              else
                rd_state <= RD_THIRD_DATA;
           end

           RD_FOURTH_DATA :     begin
              rd_data_pattern[15:0] <= 16'h9999;
              rd_state <= RD_IDLE_FIRST_DATA;
           end

         endcase
      end
   end

   assign rd_rising_edge_data[15:0]  = { rd_data_pattern[15:0]};
   assign rd_falling_edge_data[15:0] = { ~rd_data_pattern[15:0]};

   //data to the compare circuit during read
   assign app_compare_data =(bkend_rd_data_valid_r)?{rd_rising_edge_data[15:0],
                                                     rd_falling_edge_data[15:0]}
                            : 32'h00000000;

endmodule
