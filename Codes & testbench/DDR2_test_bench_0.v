`timescale 1ns/1ps

`include "../rtl/DDR2_parameters_0.v"

module DDR2_test_bench_0
  (
   input                      clk,
   input                      reset,
   input                      wdf_almost_full,
   input                      af_almost_full,
   input [2:0]                burst_length_div2,
   input                      read_data_valid,
   input [(`DQ_WIDTH*2)-1:0]  read_data_fifo_out,
   input                      init_done,

   output [35:0]              app_af_addr,
   output                     app_af_wren,
   output [(`DQ_WIDTH*2)-1:0] app_wdf_data,
   output [(`DM_WIDTH*2)-1:0] app_mask_data,
   output                     app_wdf_wren,
   output                     error
   );

   localparam                 IDLE   =  3'b000;
   localparam                 WRITE  =  3'b001;
   localparam                 READ   =  3'b010;

   reg [2:0]                  state;
   reg [2:0]                  burst_count;
   reg                        write_data_en;
   reg                        write_addr_en;
   reg [3:0]                  state_cnt;

   wire [(`DQ_WIDTH*2)-1:0]   app_cmp_data;
   wire [2:0]                 burst_len;

   reg                        reset_r1
                              /* synthesis syn_preserve=1 */;
   reg                        wdf_almost_full_r;

   assign                     burst_len = burst_length_div2;

   // synthesis attribute equivalent_register_removal of reset_r1 is "no";
   always @( posedge clk )
     reset_r1 <= reset;

   always @(posedge clk)
     begin
        if(reset_r1 == 1'b1)
          wdf_almost_full_r <= 1'b0;
        else
          wdf_almost_full_r <= wdf_almost_full;
     end

   // State Machine for writing to WRITE DATA & ADDRESS FIFOs
   // state machine changed for low FIFO threshold values
   always @ (posedge clk) begin
      if (reset_r1 == 1'b1) begin  // State Machine in IDLE state
         write_data_en <= 1'b0;
         write_addr_en <= 1'b0;
         state[2:0]    <= IDLE;
         state_cnt     <= 4'b0000;
      end
      else begin
         case (state[2:0])

           3'b000: begin // IDLE
              write_data_en <= 1'b0;
              write_addr_en <= 1'b0;
              if (wdf_almost_full_r == 1'b0 && af_almost_full == 1'b0 &&
                  init_done == 1'b1) begin
                 state[2:0]       <=  WRITE;
                 burst_count[2:0] <=  burst_len; // Burst length divided by 2
              end
              else begin
                 state[2:0]       <= IDLE;
                 burst_count[2:0] <= 3'b000;
              end
           end // case: 3'b000

           3'b001: begin // WRITE
              if (wdf_almost_full_r == 1'b0 && af_almost_full == 1'b0) begin
                 if(state_cnt == 4'd8) begin
                    state            <= READ;
                    state_cnt        <= 4'd0;
                    write_data_en    <= 1'b1;
                 end
                 else begin
                    state[2:0]       <= WRITE;
                    write_data_en    <= 1'b1;
                 end

                 if (burst_count[2:0] != 3'b000)
                   burst_count[2:0] <= burst_count[2:0] - 1'b1;
                 else
                   burst_count[2:0] <=  burst_len - 1'b1;

                 if (burst_count[2:0] == 3'b001) begin
                    write_addr_en  <= 1'b1;
                    state_cnt <= state_cnt + 1'b1;
                 end
                 else
                   write_addr_en  <= 1'b0;
              end
              else begin
                 write_addr_en    <= 1'b0;
                 write_data_en    <= 1'b0;
              end
           end // case: 3'b001

           3'b010: begin // READ
              if ( af_almost_full == 1'b0) begin
                 if(state_cnt == 4'd8) begin
                    write_addr_en  <= 1'b0;
                    if (wdf_almost_full_r == 1'b0) begin
                       state_cnt     <= 4'd0;
                       state         <= WRITE;
                    end
                 end
                 else begin
                    state[2:0]     <= READ;
                    write_addr_en  <= 1'b1;
                    write_data_en  <= 1'b0;
                    state_cnt      <= state_cnt + 1;
                 end // else: !if(state_cnt == 4'd7)
              end
              // Modified to fix the dead lock condition
              else begin
                 if(state_cnt == 4'd8) begin
                    state[2:0]       <= IDLE;
                    write_addr_en    <= 1'b0;
                    write_data_en    <= 1'b0;
                    state_cnt        <= 4'd0;
                 end
                 else begin
                    state[2:0]       <= READ; // it will remain in READ state till it completes 8 reads
                    write_addr_en    <= 1'b0;
                    write_data_en    <= 1'b0;
                    state_cnt        <= state_cnt; // state count will retain
                 end
              end

           end // case: 3'b001

           default: begin
              write_data_en <= 1'b0;
              write_addr_en <= 1'b0;
              state[2:0]    <= IDLE;
           end
         endcase
      end
   end

   DDR2_cmp_rd_data_0 cmp_rd_data_00
     (
      .clk                 (clk),
      .reset               (reset),
      .read_data_valid     (read_data_valid),
      .app_compare_data    (app_cmp_data),
      .read_data_fifo_out  (read_data_fifo_out),
      .error               (error)
      );

   DDR2_backend_rom_0 backend_rom_00
     (
      .clk0                (clk),
      .rst                 (reset),
      .bkend_data_en       (write_data_en),
      .bkend_wraddr_en     (write_addr_en),
      .bkend_rd_data_valid (read_data_valid),
      .app_af_addr         (app_af_addr),
      .app_af_wren         (app_af_wren),
      .app_wdf_data        (app_wdf_data),
      .app_mask_data       (app_mask_data),
      .app_compare_data    (app_cmp_data),
      .app_wdf_wren        (app_wdf_wren)
      );


endmodule