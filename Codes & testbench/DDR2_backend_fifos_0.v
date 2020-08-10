`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_backend_fifos_0
  (
   input                       clk0,
   input                       clk90,
   input                       rst,

   input                       init_done,
   //write address fifo signals
   input [35:0]                app_af_addr,
   input                       app_af_wren,
   input                       ctrl_af_rden,
   output [35:0]               af_addr,
   output                      af_empty,
   output                      af_almost_full,

   //write data fifo signals
   input [(`DQ_WIDTH*2)-1:0]   app_wdf_data,
   input [(`DM_WIDTH*2)-1:0]   app_mask_data,
   input                       app_wdf_wren,
   input                       ctrl_wdf_rden,
   output [(`DQ_WIDTH*2)-1:0]  wdf_data,
   output [(`DM_WIDTH*2)-1:0]  mask_data,
   output                      wdf_almost_full
   );

   wire [`FIFO_16-1:0]          wr_df_almost_full_w;

   reg [2:0]                   init_count;
   reg                         init_wren;
   reg [(`DQ_WIDTH*2)-1:0]     init_data;
   reg                         init_flag;
   wire [(`DQ_WIDTH*2)-1:0]    init_mux_app_wdf_data;
   wire [(`DM_WIDTH*2)-1:0]    init_mux_app_mask_data;
   wire                        init_mux_app_wdf_wren;
   wire [143:0]                pattern_F;
   wire [143:0]                pattern_0;
   wire [143:0]                pattern_A;
   wire [143:0]                pattern_5;

   reg                         rst_r1
                               /* synthesis syn_preserve=1 */;

   wire [`ROW_ADDRESS -1:0]    load_mode_reg;

   assign  pattern_F = 144'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
   assign  pattern_0 = 144'h0000_0000_0000_0000_0000_0000_0000_0000_0000;
   assign  pattern_A = 144'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
   assign  pattern_5 = 144'h5555_5555_5555_5555_5555_5555_5555_5555_5555;

   assign  wdf_almost_full      = wr_df_almost_full_w[0];

   assign load_mode_reg = `LOAD_MODE_REGISTER;

   // synthesis attribute equivalent_register_removal of rst_r1 is "no";
   always @( posedge clk0 )
     rst_r1 <= rst;

   always @(posedge clk0)
     begin
        if(rst_r1) begin
           init_count <= 3'd0;
           init_wren <= 1'd0;
           init_data <= 2*`DQ_WIDTH'd0;
           init_flag <= 1'd0;
        end else begin
           case(init_count)

             3'd0: begin
                if(init_flag)begin
                   init_count <= 3'd0;
                   init_wren <= 1'd0;
                   init_data <= 2*`DQ_WIDTH'd0;
                end else begin
                   init_count <= 3'd1;
                   init_wren <= 1'd1;
                   init_data <= {pattern_F[`DQ_WIDTH-1:0],
                                 pattern_0[`DQ_WIDTH-1:0]};
                end
             end

             3'd1: begin
                if(load_mode_reg[2:0] == 3'b011)
                  init_count <= 3'd2;
                else
                  init_count <= 3'd6;

                init_wren <= 1'd1;
                init_data <=  {pattern_F[`DQ_WIDTH-1:0],
                               pattern_0[`DQ_WIDTH-1:0]};
             end

             3'd2: begin
                init_count <= 3'd3;
                init_wren <= 1'd1;
                init_data <=  {pattern_F[`DQ_WIDTH-1:0],
                               pattern_0[`DQ_WIDTH-1:0]};
             end

             3'd3: begin
                init_count <= 3'd4;
                init_wren <= 1'd1;
                init_data <=  {pattern_F[`DQ_WIDTH-1:0],
                               pattern_0[`DQ_WIDTH-1:0]};
             end

             3'd4: begin
                init_count <= 3'd5;
                init_wren <= 1'd1;
                init_data <=  {pattern_A[`DQ_WIDTH-1:0],
                               pattern_5[`DQ_WIDTH-1:0]};
             end

             3'd5: begin
                init_count <= 3'd6;
                init_wren <= 1'd1;
                init_data <=  {pattern_5[`DQ_WIDTH-1:0],
                               pattern_A[`DQ_WIDTH-1:0]};
             end

             3'd6: begin
                init_count <= 3'd7;
                init_wren <= 1'd1;
                init_data <=  {pattern_A[`DQ_WIDTH-1:0],
                               pattern_5[`DQ_WIDTH-1:0]};
             end

             3'd7: begin
                init_count <= 3'd0;
                init_wren <= 1'd1;
                init_data <=  {pattern_5[`DQ_WIDTH-1:0],
                               pattern_A[`DQ_WIDTH-1:0]};
                init_flag <= 1'b1;
             end

             default:begin
                init_count <= 3'd0;
                init_wren <= 1'd0;
                init_data <= 2*`DQ_WIDTH'd0;
                init_flag <= 1'd0;
             end

           endcase // case(init_count)
        end // else: !if(rst_r1)
     end // always@ (clk0)

   assign init_mux_app_wdf_data  = init_done ? app_wdf_data : init_data;
   assign init_mux_app_mask_data = init_done ? app_mask_data :
          {2*`DM_WIDTH{1'b0}};
   assign init_mux_app_wdf_wren  = init_done ? app_wdf_wren : init_wren ;

   DDR2_rd_wr_addr_fifo_0 rd_wr_addr_fifo_00
     (
      .clk0               (clk0),
      .clk90              (clk90),
      .rst                (rst),
      .app_af_addr        (app_af_addr),
      .app_af_wren        (app_af_wren),
      .ctrl_af_rden       (ctrl_af_rden),
      .af_addr            (af_addr),
      .af_empty           (af_empty),
      .af_almost_full     (af_almost_full)
      );

   DDR2_wr_data_fifo_16 wr_data_fifo_160
     (
      .clk0                   (clk0),
      .clk90                  (clk90),
      .rst                    (rst),
      .app_wdf_data           (init_mux_app_wdf_data[31:0]),
      .app_mask_data          (init_mux_app_mask_data[3:0]),
      .app_wdf_wren           (init_mux_app_wdf_wren),
      .ctrl_wdf_rden          (ctrl_wdf_rden),
      .wdf_data               (wdf_data[31:0]),
      .mask_data              (mask_data[3:0]),
      .wr_df_almost_full      (wr_df_almost_full_w[0])
      );


   DDR2_wr_data_fifo_16 wr_data_fifo_161
     (
      .clk0                   (clk0),
      .clk90                  (clk90),
      .rst                    (rst),
      .app_wdf_data           (init_mux_app_wdf_data[63:32]),
      .app_mask_data          (init_mux_app_mask_data[7:4]),
      .app_wdf_wren           (init_mux_app_wdf_wren),
      .ctrl_wdf_rden          (ctrl_wdf_rden),
      .wdf_data               (wdf_data[63:32]),
      .mask_data              (mask_data[7:4]),
      .wr_df_almost_full      (wr_df_almost_full_w[1])
      );



endmodule
