`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_ddr2_controller_0
  (
   // controller inputs
   input                        clk0,
   input                        rst,
   // FIFO  signals
   input [35:0]                 af_addr,
   input                        af_empty
                                /* synthesis syn_maxfan = 10 */,

   input                        comp_done,
   // Input signals for the Dummy Reads
   input                        phy_dly_slct_done,
   input                        cal_first_loop,
   output reg                   ctrl_dummyread_start,
   // FIFO read enable signals
   output                       ctrl_af_rden,
   output                       ctrl_wdf_rden,
   // Rst and Enable signals for DQS logic
   output                       ctrl_dqs_rst,
   output                       ctrl_dqs_en,
   // Read and Write Enable signals to the phy interface
   output                       ctrl_wren,
   output                       ctrl_rden,

   (* IOB = "FORCE" *)          output [`ROW_ADDRESS-1:0]  ctrl_ddr2_address,
   (* IOB = "FORCE" *)          output [`BANK_ADDRESS-1:0] ctrl_ddr2_ba,
   (* IOB = "FORCE" *)          output                     ctrl_ddr2_ras_l,
   (* IOB = "FORCE" *)          output                     ctrl_ddr2_cas_l,
   (* IOB = "FORCE" *)          output                     ctrl_ddr2_we_l,
   (* IOB = "FORCE" *)          output [`CS_WIDTH-1:0]     ctrl_ddr2_cs_l,
   (* IOB = "FORCE" *)          output [`CKE_WIDTH-1:0]    ctrl_ddr2_cke,
   (* IOB = "FORCE" *)          output [`ODT_WIDTH-1:0]    ctrl_ddr2_odt,
   output [2:0]                 burst_length_div2,
   output                       ctrl_dummy_wr_sel,
   output reg                   init_done,

   // Debug Signals
   output                       dbg_init_done
   );

   // time to wait between consecutive commands in PHY_INIT - this is a
   // generic number, and must be large enough to account for worst case
   // timing parameter (tRFC - refresh-to-active) across all memory speed
   // grades and operating frequencies.
   localparam CNTNEXT = 7'b1101110;

   localparam INIT_IDLE                =  22'b0000000000000000000001; //0
   localparam INIT_LOAD_MODE           =  22'b0000000000000000000010; //1
   localparam INIT_MODE_REGISTER_WAIT  =  22'b0000000000000000000100; //2
   localparam INIT_PRECHARGE           =  22'b0000000000000000001000; //3
   localparam INIT_PRECHARGE_WAIT      =  22'b0000000000000000010000; //4
   localparam INIT_AUTO_REFRESH        =  22'b0000000000000000100000; //5
   localparam INIT_AUTO_REFRESH_WAIT   =  22'b0000000000000001000000; //6
   localparam INIT_COUNT_200           =  22'b0000000000000010000000; //7
   localparam INIT_COUNT_200_WAIT      =  22'b0000000000000100000000; //8
   localparam INIT_DUMMY_READ_CYCLES   =  22'b0000000000001000000000; //9
   localparam INIT_DUMMY_ACTIVE        =  22'b0000000000010000000000; //10
   localparam INIT_DUMMY_ACTIVE_WAIT   =  22'b0000000000100000000000; //11
   localparam INIT_DUMMY_WRITE         =  22'b0000000001000000000000; //12
   localparam INIT_DUMMY_WRITE_READ    =  22'b0000000010000000000000; //13
   localparam INIT_DUMMY_READ          =  22'b0000000100000000000000; //14
   localparam INIT_DUMMY_READ_WAIT     =  22'b0000001000000000000000; //15
   localparam INIT_DUMMY_FIRST_READ    =  22'b0000010000000000000000; //16
   localparam INIT_DEEP_MEMORY_ST      =  22'b0000100000000000000000; //17
   localparam INIT_PATTERN_WRITE       =  22'b0001000000000000000000; //18
   localparam INIT_PATTERN_WRITE_READ  =  22'b0010000000000000000000; //19
   localparam INIT_PATTERN_READ        =  22'b0100000000000000000000; //20
   localparam INIT_PATTERN_READ_WAIT   =  22'b1000000000000000000000; //21

   localparam IDLE                     =  17'b00000000000000001; //0;
   localparam LOAD_MODE                =  17'b00000000000000010; //1;
   localparam MODE_REGISTER_WAIT       =  17'b00000000000000100; //2;
   localparam PRECHARGE                =  17'b00000000000001000; //3;
   localparam PRECHARGE_WAIT           =  17'b00000000000010000; //4;
   localparam AUTO_REFRESH             =  17'b00000000000100000; //5;
   localparam AUTO_REFRESH_WAIT        =  17'b00000000001000000; //6;
   localparam ACTIVE                   =  17'b00000000010000000; //7;
   localparam ACTIVE_WAIT              =  17'b00000000100000000; //8;
   localparam FIRST_READ               =  17'b00000001000000000; //9;
   localparam BURST_READ               =  17'b00000010000000000; //10;
   localparam READ_WAIT                =  17'b00000100000000000; //11;
   localparam FIRST_WRITE              =  17'b00001000000000000; //12;
   localparam BURST_WRITE              =  17'b00010000000000000; //13;
   localparam WRITE_WAIT               =  17'b00100000000000000; //14;
   localparam WRITE_READ               =  17'b01000000000000000; //15;
   localparam READ_WRITE               =  17'b10000000000000000; //16;

   parameter  COL_WIDTH                = `COLUMN_ADDRESS;
   parameter  ROW_WIDTH                = `ROW_ADDRESS;

   // internal signals
   reg [3:0]                    init_count;
   reg [3:0]                    init_count_cp;
   reg                          init_memory;
   reg [7:0]                    count_200_cycle;
   wire                         ref_flag;
   reg                          ref_flag_0;
   reg                          ref_flag_0_r;
   reg                          auto_ref;
   reg [16:0]                   next_state;
   reg [16:0]                   state;
   reg [16:0]                   state_r2;
   reg [16:0]                   state_r3;

   reg [21:0]                   init_next_state;
   reg [21:0]                   init_state;
   reg [21:0]                   init_state_r2;

   reg [`ROW_ADDRESS -1:0]      row_addr_r ;
   reg [`ROW_ADDRESS -1:0]      ddr2_address_init_r;
   reg [`ROW_ADDRESS -1:0]      ddr2_address_r1;
   reg [`BANK_ADDRESS-1:0]      ddr2_ba_r1;
   reg [`ROW_ADDRESS -1:0]      ddr2_address_r2;
   reg [`BANK_ADDRESS-1:0]      ddr2_ba_r2;

   // counters for DDR2 controller
   reg                          mrd_count;
   reg [2:0]                    rp_count;
   reg [7:0]                    rfc_count;
   reg [2:0]                    rcd_count;
   reg [4:0]                    ras_count;
   reg [3:0]                    wr_to_rd_count;
   reg [3:0]                    rd_to_wr_count;
   reg [3:0]                    rtp_count;
   reg [3:0]                    wtp_count;

   reg [`MAX_REF_WIDTH-1:0]     refi_count;
   reg [2:0]                    cas_count;
   reg [3:0]                    cas_check_count;
   reg [2:0]                    wrburst_cnt;
   reg [2:0]                    read_burst_cnt;
   reg [2:0]                    ctrl_wren_cnt;
   reg [3:0]                    rdburst_cnt;

   reg [35:0]                   af_addr_r ;
   reg [35:0]                   af_addr_r1 ;

   reg                          wdf_rden_r;
   reg                          wdf_rden_r2;
   reg                          wdf_rden_r3;
   reg                          wdf_rden_r4;
   reg                          ctrl_wdf_rden_int;
   wire                         af_rden;
   reg                          ddr2_ras_r2;
   reg                          ddr2_cas_r2;
   reg                          ddr2_we_r2;
   reg                          ddr2_ras_r;
   reg                          ddr2_cas_r;
   reg                          ddr2_we_r;
   reg                          ddr2_ras_r3;
   reg                          ddr2_cas_r3;
   reg                          ddr2_we_r3;

   reg [3:0]                    idle_cnt;

   reg                          ctrl_dummyread_start_r1;
   reg                          ctrl_dummyread_start_r2;
   reg                          ctrl_dummyread_start_r3;
   reg                          ctrl_dummyread_start_r4;
   reg                          ctrl_dummyread_start_r5;
   reg                          ctrl_dummyread_start_r6;
   reg                          ctrl_dummyread_start_r7;
   reg                          ctrl_dummyread_start_r8;
   reg                          ctrl_dummyread_start_r9;

   reg                          conflict_resolved_r;

   reg                          dqs_reset;
   reg                          dqs_reset_r1;
   reg                          dqs_reset_r2;
   reg                          dqs_reset_r3;
   reg                          dqs_reset_r4;
   reg                          dqs_reset_r5;
   reg                          dqs_reset_r6;

   reg                          dqs_en;
   reg                          dqs_en_r1;
   reg                          dqs_en_r2;
   reg                          dqs_en_r3;
   reg                          dqs_en_r4;
   reg                          dqs_en_r5;
   reg                          dqs_en_r6;

   reg                          ctrl_wdf_read_en;
   reg                          ctrl_wdf_read_en_r1;
   reg                          ctrl_wdf_read_en_r2;
   reg                          ctrl_wdf_read_en_r3;
   reg                          ctrl_wdf_read_en_r4;
   reg                          ctrl_wdf_read_en_r5;
   reg                          ctrl_wdf_read_en_r6;
   reg [`CS_WIDTH-1:0]          ddr2_cs_r1;
   reg [`CS_WIDTH-1:0]          ddr2_cs_r;
   reg [`CKE_WIDTH-1:0]         ddr2_cke_r
                                /* synthesis syn_preserve=1 */;
   reg [1:0]                    chip_cnt;
   reg [2:0]                    auto_cnt;

   //  Precharge fix for deep memory
   reg [2:0]                    pre_cnt;

   // Rst and Enable signals for DQS logic
   reg                          ctrl_dqs_rst_r1;
   reg                          ctrl_dqs_en_r1;
   // Read and Write Enable signals to the phy interface
   wire                         ctrl_wren_r1;
   reg                          ctrl_wren_r1_i;
   reg                          ctrl_rden_r1;
   reg                          dummy_read_en;
   wire                         ctrl_init_done;

   //wire         count_200cycle_done;
   reg                          count_200cycle_done_r;

   wire [2:0]                   burst_cnt;

   reg                          ctrl_write_en;
   reg                          ctrl_write_en_r1;
   reg                          ctrl_write_en_r2;
   reg                          ctrl_write_en_r3;
   reg                          ctrl_write_en_r4;
   reg                          ctrl_write_en_r5;
   reg                          ctrl_write_en_r6;

   reg                          ctrl_read_en;
   reg                          ctrl_read_en_r;
   reg                          ctrl_read_en_r1;
   reg                          ctrl_read_en_r2;
   reg                          ctrl_read_en_r3;
   reg                          ctrl_read_en_r4;
   reg [3:0]                    odt_cnt
                                /* synthesis syn_maxfan = 1 */;
   reg [3:0]                    odt_en_cnt
                                /* synthesis syn_maxfan = 1 */;
   reg [`ODT_WIDTH-1 :0 ]       odt_en
                                /* synthesis syn_maxfan = 1 */;

   wire                         conflict_detect;
   reg                          conflict_detect_r;

   reg [`ROW_ADDRESS -1:0]      load_mode_reg;
   reg [`ROW_ADDRESS -1:0]      ext_mode_reg;

   wire [3:0]                   cas_latency_value;
   wire [2:0]                   burst_length_value;
   wire [3:0]                   additive_latency_value;
   wire                         odt_enable;
   wire                         registered_dimm;
   wire                         ecc_value;

   reg                          wr;
   reg                          rd;
   reg                          lmr;
   reg                          pre;
   reg                          ref;
   reg                          act;

   reg                          wr_r;
   reg                          rd_r;
   reg                          lmr_r;
   reg                          pre_r;
   reg                          ref_r;
   reg                          act_r;
   reg                          af_empty_r;
   reg                          lmr_pre_ref_act_cmd_r;
   wire [2:0]                   command_address;
   reg [`ODT_WIDTH-1:0]         ctrl_odt;

   reg [4:0]                    cke_200us_cnt;
   reg                          done_200us;

   reg                          dummy_write_state_r;

   wire                         dummy_write_state;
   reg                          ctrl_dummy_write;
   reg                          comp_done_r;

   reg [`CS_WIDTH-1:0]          ddr2_cs_r_out;
   reg [`CS_WIDTH-1:0]          ddr2_cs_r_odt
                                /* synthesis syn_preserve=1 */;
   reg [6:0]                    count6;

   reg                          rst_r1
                                /* synthesis syn_preserve=1 */;

   reg                          odt_en_single;
   reg [`CS_WIDTH-1:0]          ddr2_cs_r_odt_r1;
   reg [`CS_WIDTH-1:0]          ddr2_cs_r_odt_r2;

   reg                          init_done_int;

   wire                         dummy_read_state;
   wire [`ROW_ADDRESS-1:0]      ddr_addr_col;

   //***************************************************************************

  //***************************************************************************
  // Debug output ("dbg_*")
  // NOTES:
  //  1. All debug outputs coming out of DDR2_CONTROLLER are clocked off CLK0,
  //     although they are also static after calibration is complete. This
  //     means the user can either connect them to a Chipscope ILA, or to
  //     either a sync/async VIO input block. Using an async VIO has the
  //     advantage of not requiring these paths to meet cycle-to-cycle timing.
  // SIGNAL DESCRIPTION:
  //  1. init_done: 1 bit - asserted if both per bit and pattern calibration
  //                are completed.
  //***************************************************************************

   assign dbg_init_done = init_done_int;

   // synthesis attribute equivalent_register_removal of rst_r1 is "no";
   always @( posedge clk0 )
     rst_r1 <= rst;

   always @ (posedge clk0) begin
      if (rst_r1)
        ctrl_dummy_write         <= 1'b1;
      else if(init_state[20] /*INIT_PATTERN_READ*/)
        ctrl_dummy_write         <= 1'b0;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        comp_done_r        <= 1'b0;
      else
        comp_done_r        <= comp_done;
   end

   assign ctrl_wdf_rden   = ctrl_wdf_rden_int;

   //*****************************************************************
   // Mode Register (MR):
   //   [15:14] - unused          - 00
   //   [13]    - reserved        - 0
   //   [12]    - Power-down mode - 0 (normal)
   //   [11:9]  - write recovery  - same value as written to CAS_LATENCY_VALUE
   //   [8]     - DLL reset       - 0 or 1
   //   [7]     - Test Mode       - 0 (normal)
   //   [6:4]   - CAS latency     - CAS_LATENCY_VALUE
   //   [3]     - Burst Type      - BURST_TYPE
   //   [2:0]   - Burst Length    - BURST_LENGTH_VALUE
   //*****************************************************************

   assign cas_latency_value = {1'b0, load_mode_reg[6:4]};
   assign burst_length_value = load_mode_reg[2:0];

   //*****************************************************************
   // Extended Mode Register (MR):
   //   [15:14] - unused          - 00
   //   [13]    - reserved        - 0
   //   [12]    - output enable   - 0 (enabled)
   //   [11]    - RDQS enable     - 0 (disabled)
   //   [10]    - DQS# enable     - 0 (enabled)
   //   [9:7]   - OCD Program     - 111 or 000 (first 111, then 000 during init)
   //   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
   //   [5:3]   - Additive CAS    - ADDITIVE_LATENCY_VALUE
   //   [2]     - RTT[0]
   //   [1]     - Output drive    - REDUCE_DRV (= 0(full), = 1 (reduced)
   //   [0]     - DLL enable      - 0 (normal)
   //*****************************************************************

   assign additive_latency_value = {1'b0, ext_mode_reg[5:3]};
   assign odt_enable = ext_mode_reg[2] | ext_mode_reg[6];

   assign registered_dimm = `REGISTERED;
   assign burst_length_div2 = burst_cnt;
   assign command_address =   af_addr[34:32];
   assign ecc_value=    `ECC_ENABLE;

   // fifo control signals
   assign ctrl_af_rden = af_rden;
   // synthesis attribute max_fanout of af_empty is 10
   assign conflict_detect = af_addr[35]& ctrl_init_done & ~af_empty;

   assign dummy_read_state = (init_state_r2[14] /*INIT_DUMMY_READ*/ |
                              init_state_r2[15] /*INIT_DUMMY_READ_WAIT*/);

   //commands

  //*****************************************************************
  // interpret commands from Command/Address FIFO
  //*****************************************************************


   always @(command_address or ctrl_init_done or af_empty) begin
      wr = 1'b0;
      rd = 1'b0;
      lmr = 1'b0;
      pre = 1'b0;
      ref = 1'b0;
      act = 1'b0;
      if(ctrl_init_done & ~af_empty) begin
         case(command_address)
           3'b000: lmr = 1'b1;
           3'b001: ref = 1'b1;
           3'b010: pre = 1'b1;
           3'b011: act = 1'b1;
           3'b100: wr  = 1'b1;
           3'b101: rd  = 1'b1;
         endcase // case(af_addr[34:32])
      end // if (ctrl_init_done & ~af_empty)
   end // always @ (af_addr)

   // register address outputs
   always @ (posedge clk0) begin
      if (rst_r1) begin
         wr_r <= 1'b0;
         rd_r <= 1'b0;
         lmr_r <= 1'b0;
         pre_r <= 1'b0;
         ref_r <= 1'b0;
         act_r <= 1'b0;
         af_empty_r <= 1'b0;
         lmr_pre_ref_act_cmd_r <= 1'b0;
      end
      else begin
         wr_r <= wr;
         rd_r <= rd;
         lmr_r <= lmr;
         pre_r <= pre;
         ref_r <= ref;
         act_r <= act;
         af_empty_r <= af_empty;
         lmr_pre_ref_act_cmd_r <= lmr | pre | ref | act;
      end
   end

   // register address outputs
   always @ (posedge clk0) begin
      if (rst_r1) begin
         af_addr_r          <= 36'h00000;
         af_addr_r1         <= 36'h00000;
         conflict_detect_r   <= 1'b0;
      end
      else begin
         af_addr_r <= af_addr;
         af_addr_r1 <= af_addr_r;
         conflict_detect_r <= conflict_detect;
      end
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        load_mode_reg  <= `LOAD_MODE_REGISTER;
      else if((state[1] /*LOAD_MODE*/)& lmr_r &
              (af_addr_r[(`BANK_ADDRESS + `ROW_ADDRESS + `COLUMN_ADDRESS)-1:
                         (`COLUMN_ADDRESS + `ROW_ADDRESS)]== `BANK_ADDRESS'h0))
        load_mode_reg  <=  af_addr [`ROW_ADDRESS-1:0];
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        ext_mode_reg  <= `EXT_LOAD_MODE_REGISTER;
      else if((state[1] /*LOAD_MODE*/) & lmr_r &
              (af_addr_r[(`BANK_ADDRESS+`ROW_ADDRESS + `COLUMN_ADDRESS)-1:
                         (`COLUMN_ADDRESS + `ROW_ADDRESS)]== `BANK_ADDRESS'h1))
        ext_mode_reg  <=  af_addr [`ROW_ADDRESS-1:0];
   end

   //to initialize memory
   always @ (posedge clk0) begin
      if ((rst_r1)|| (init_state[17] /*INIT_DEEP_MEMORY_ST*/))
        init_memory <= 1'b1;
      else if (init_count_cp == 4'hF)
        init_memory <= 1'b0;
      else
        init_memory <= init_memory;
   end

   //*****************************************************************
   // Various delay counters
   //*****************************************************************

   // mrd count
   always @ (posedge clk0) begin
      if (rst_r1)
        mrd_count <= 1'b0;
      else if (state[1] /*LOAD_MODE*/)
        mrd_count <= `MRD_COUNT_VALUE;
      else if (mrd_count != 1'b0)
        mrd_count <= 1'b0;
      else
        mrd_count <= 1'b0;
   end

   // rp count
   always @ (posedge clk0) begin
      if (rst_r1)
        rp_count[2:0] <= 3'b000;
      else if (state[3] /*PRECHARGE*/)
        rp_count[2:0] <= `RP_COUNT_VALUE;
      else if (rp_count[2:0] != 3'b000)
        rp_count[2:0] <= rp_count[2:0] - 1;
      else
        rp_count[2:0] <= 3'b000;
   end

   // rfc count
   always @ ( posedge clk0) begin
      if (rst_r1)
        rfc_count <= 'b0;
      else if (state[5] /*AUTO_REFRESH*/)
        rfc_count <= `RFC_COUNT_VALUE;
      else if (rfc_count != 8'b0)
        rfc_count <= rfc_count - 1;
      else
        rfc_count <= 'b0;
   end

   // rcd count - 20ns
   always @ ( posedge clk0) begin
      if (rst_r1)
        rcd_count[2:0] <= 3'b000;
      else if (state[7] /*ACTIVE*/)
        rcd_count[2:0] <= `RCD_COUNT_VALUE - additive_latency_value[2:0] - 1;
      else if (rcd_count[2:0] != 3'b000)
        rcd_count[2:0] <= rcd_count[2:0] - 1;
      else
        rcd_count[2:0] <=  3'b000;
   end

   // ras count - active to precharge
   always @ ( posedge clk0) begin
      if (rst_r1)
        ras_count <= 'b0;
      else if (state[7] /*ACTIVE*/)
        ras_count <= `RAS_COUNT_VALUE;
      else if (ras_count[4:1] == 4'b0) begin
         if (ras_count[0] != 1'b0)
           ras_count[0] <= 1'b0;
      end
      else
        ras_count <= ras_count - 1;
   end

   //AL+BL/2+TRTP-2
   // rtp count - read to precharge
   always @ ( posedge clk0) begin
      if (rst_r1)
        rtp_count[3:0] <= 4'b0000;
      else if (state[9]  /*FIRST_READ*/ || state[10] /*BURST_READ*/)
        rtp_count[3:0] <= (`TRTP_COUNT_VALUE + burst_cnt +
                           additive_latency_value -2'd2) ;
      else if (rtp_count[3:1] == 3'b000) begin
         if (rtp_count[0] != 1'b0)
           rtp_count[0] <= 1'b0;
      end
      else
        rtp_count[3:0] <= rtp_count[3:0] - 1;
   end

   // WL+BL/2+TWR
   // wtp count - write to precharge
   always @ ( posedge clk0) begin
      if (rst_r1)
        wtp_count[3:0] <= 4'b0000;
      else if (state[12] /*FIRST_WRITE*/ || state[13] /*BURST_WRITE*/ )
        wtp_count[3:0] <= (`TWR_COUNT_VALUE + burst_cnt +
                           cas_latency_value + additive_latency_value -2'd3);
      else if (wtp_count[3:1] == 3'b000) begin
         if (wtp_count[0] != 1'b0)
           wtp_count[0] <= 1'b0;
      end
      else
        wtp_count[3:0] <= wtp_count[3:0] - 1;
   end

   // write to read counter
   // write to read includes : write latency + burst time + tWTR

   always @ (posedge clk0) begin
      if (rst_r1)
        wr_to_rd_count[3:0] <= 4'b0000;
      else if (state[12] /*FIRST_WRITE*/ || state[13] /*BURST_WRITE*/)
        wr_to_rd_count[3:0] <= (`TWTR_COUNT_VALUE + burst_cnt +
                                additive_latency_value + cas_latency_value
                                - 2'd1);
      else if (wr_to_rd_count[3:0] != 4'b0000)
        wr_to_rd_count[3:0] <= wr_to_rd_count[3:0] - 1;
      else
        wr_to_rd_count[3:0] <= 4'b0000;
   end

   // read to write counter
   always @ (posedge clk0) begin
      if (rst_r1)
        rd_to_wr_count[3:0] <= 4'b0000;
      else if ((state[9] /*FIRST_READ*/) || (state[10] /*BURST_READ*/))
        rd_to_wr_count[3:0] <= (cas_latency_value + additive_latency_value
                                + burst_cnt - 2'd2);
      else if (rd_to_wr_count[3:0] != 4'b0000)
        rd_to_wr_count[3:0] <= rd_to_wr_count[3:0] - 1;
      else
        rd_to_wr_count[3:0] <= 4'b0000;
   end

   // auto refresh interval counter in clk0 domain
   always @ (posedge clk0) begin
      if (rst_r1)
        refi_count <= `MAX_REF_WIDTH'h000;
      else if (refi_count == `MAX_REF_CNT )
        refi_count <= `MAX_REF_WIDTH'h000;
      else
        refi_count <= refi_count + 1;
   end

   assign ref_flag = ((refi_count == `MAX_REF_CNT) && (done_200us == 1'b1)) ?
                     1'b1 : 1'b0;

   //***************************************************************************
   // Initial delay after power-on
   //***************************************************************************

   //200us counter for cke
   always @ (posedge clk0) begin
      if (rst_r1 )
        `ifdef simulation
           cke_200us_cnt <= 5'b00001;
        `else
           cke_200us_cnt <= 5'b11011;
        `endif
      else if (refi_count ==  `MAX_REF_CNT)
        cke_200us_cnt  <=  cke_200us_cnt - 1;
      else
        cke_200us_cnt  <= cke_200us_cnt;
   end

   // refresh detect
   always @ (posedge clk0) begin
      if (rst_r1) begin
         ref_flag_0   <= 1'b0;
         ref_flag_0_r <= 1'b0;
         done_200us <= 1'b0;
      end
      else begin
         ref_flag_0   <= ref_flag;
         ref_flag_0_r <= ref_flag_0;

         if (done_200us == 1'b0)
           done_200us <= (cke_200us_cnt == 5'b00000);
      end
   end

   //refresh flag detect
   //auto_ref high indicates auto_refresh requirement
   //auto_ref is held high until auto refresh command is issued.

   always @(posedge clk0) begin
      if (rst_r1)
        auto_ref <= 1'b0;
      else if (ref_flag_0 == 1'b1 && ref_flag_0_r == 1'b0)
        auto_ref <= 1'b1;
      else if (state[5] /*AUTO_REFRESH*/)
        auto_ref <= 1'b0;
      else
        auto_ref <= auto_ref;
   end

   // 200 clocks counter - count value : C8
   // required for initialization

   always @ (posedge clk0) begin
      if (rst_r1)
        count_200_cycle[7:0] <= 8'h00;
      else if (init_state[7] /*INIT_COUNT_200*/)
        count_200_cycle[7:0] <= 8'hC8;
      else if (count_200_cycle[7:0] != 8'h00)
        count_200_cycle[7:0] <= count_200_cycle[7:0] - 1;
      else
        count_200_cycle[7:0] <= 8'h00;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        count_200cycle_done_r <= 1'b0;
      else if (init_memory && (count_200_cycle == 8'h00))
        count_200cycle_done_r <= 1'b1;
      else
        count_200cycle_done_r <= 1'b0;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        init_done_int <= 1'b0;
      else if ((init_count_cp == 4'hD) && (count_200cycle_done_r == 1'b1) &&
               (`PHY_MODE == 1'b0)) begin
        init_done_int <= 1'b1;
      // Precharge fix for pattern read
      // 2.1: Main controller state machine should start after
      // initialization state machine completed.
      end else if ((`PHY_MODE == 1'b1) && (comp_done_r) &&
               (init_state_r2[0])) begin
        init_done_int <= 1'b1;
      end else
        init_done_int <= init_done_int;
   end

   //synthesis translate_off
   always @ (posedge init_done_int)
      $display ("Calibration completed at time %t", $time);
   //synthesis translate_on

   assign ctrl_init_done      = init_done_int;

   always @ (posedge clk0)
     init_done <= init_done_int;

   assign burst_cnt           = (burst_length_value == 3'b010) ? 3'b010 :
          (burst_length_value == 3'b011) ? 3'b100 : 3'b000;

   always @ (posedge clk0) begin
      if ((rst_r1)|| (init_state[17] /*INIT_DEEP_MEMORY_ST*/))
        init_count[3:0] <= 4'b0000;
      else if (init_memory ) begin
         if (init_state[1]/*INIT_LOAD_MODE*/|| init_state[3]/*INIT_PRECHARGE*/||
             init_state[5] /*INIT_AUTO_REFRESH*/ ||
             init_state[9] /*INIT_DUMMY_READ_CYCLES*/ ||
             init_state[7] /*INIT_COUNT_200*/ ||
             init_state[17] /*INIT_DEEP_MEMORY_ST*/ ||
             init_state[18] /*INIT_PATTERN_WRITE*/ ||
             init_state[12] /* Added INIT_DUMMY_WRITE*/)
           init_count[3:0] <= init_count[3:0] + 1;
         else if(init_count == 4'hF )
           init_count[3:0] <= 4'h0;
         else
           init_count[3:0] <= init_count[3:0];
      end
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      if ((rst_r1)|| (init_state[17] /*INIT_DEEP_MEMORY_ST*/))
        init_count_cp[3:0] <= 4'b0000;
      else if (init_memory  ) begin
         if (init_state[1]/*INIT_LOAD_MODE*/|| init_state[3]/*INIT_PRECHARGE*/||
             init_state[5] /*INIT_AUTO_REFRESH*/ ||
             init_state[9] /*INIT_DUMMY_READ_CYCLES*/ ||
             init_state[7] /*INIT_COUNT_200*/ ||
             init_state[17] /*INIT_DEEP_MEMORY_ST*/ ||
             init_state[18] /*INIT_PATTERN_WRITE*/ ||
             init_state[12] /* Added INIT_DUMMY_WRITE*/)
           init_count_cp[3:0] <= init_count_cp[3:0] + 1;
         else if(init_count_cp == 4'hF )
           init_count_cp[3:0] <= 4'h0;
         else
           init_count_cp[3:0] <= init_count_cp[3:0];
      end
   end // always @ (posedge clk0)

   //*****************************************************************
   // handle deep memory configuration:
   //   During initialization: Repeat initialization sequence once for each
   //   chip select.
   //   Once initialization complete, assert only last chip for calibration.
   //*****************************************************************

   always @ (posedge clk0 ) begin
      if (rst_r1)
        chip_cnt <= 2'b00;
      else if ( init_state[17] /*INIT_DEEP_MEMORY_ST*/)
        chip_cnt <= chip_cnt + 2'b01;
      else
        chip_cnt <= chip_cnt;
   end

   always @ (posedge clk0 ) begin
      if (rst_r1 || (state[3] /*PRECHARGE*/ ))
        auto_cnt <= 3'b000;
      else if ( state[5] /*AUTO_REFRESH */&& init_memory == 1'b0)
        auto_cnt <= auto_cnt + 3'b001;
      else
        auto_cnt <= auto_cnt;
   end

   //Precharge fix for deep memory
   always @ (posedge clk0 ) begin
      if (rst_r1 || (state[5] /*AUTO_REFRESH*/ ))
        pre_cnt <= 3'b000;
      else if (state[3]/*PRECHARGE*/ && init_memory == 1'b0 &&
               (auto_ref == 1'b1 || ref_r))
        pre_cnt <= pre_cnt + 3'b001;
      else
        pre_cnt <= pre_cnt;
   end

   // write burst count
   always @ (posedge clk0) begin
      if (rst_r1)
        wrburst_cnt[2:0] <= 3'b000;
      else if (state[12] /*FIRST_WRITE*/ || state[13] /*BURST_WRITE*/ ||
               init_state[18] /*INIT_PATTERN_WRITE*/ ||
               init_state[12] /* Added INIT_DUMMY_WRITE*/ )
        wrburst_cnt[2:0] <= burst_cnt[2:0];
      else if (wrburst_cnt[2:0] != 3'b000)
        wrburst_cnt[2:0] <= wrburst_cnt[2:0] - 1;
      else
        wrburst_cnt[2:0] <= 3'b000;
   end

   // read burst count for state machine
   always @ (posedge clk0) begin
      if (rst_r1)
        read_burst_cnt[2:0] <= 3'b000;
      else if (state[9] /*FIRST_READ*/ || state[10] /*BURST_READ*/)
        read_burst_cnt[2:0] <= burst_cnt[2:0];
      else if (read_burst_cnt[2:0] != 3'b000)
        read_burst_cnt[2:0] <= read_burst_cnt[2:0] - 1;
      else
        read_burst_cnt[2:0] <= 3'b000;
   end

   // count to generate write enable to the data path
   always @ (posedge clk0) begin
      if (rst_r1)
        ctrl_wren_cnt[2:0] <= 3'b000;
      else if (wdf_rden_r || dummy_write_state_r)
        ctrl_wren_cnt[2:0] <= burst_cnt[2:0];
      else if (ctrl_wren_cnt[2:0] != 3'b000)
        ctrl_wren_cnt[2:0] <= ctrl_wren_cnt[2:0] -1;
      else
        ctrl_wren_cnt[2:0] <= 3'b000;
   end

   //write enable to data path
   always @ (ctrl_wren_cnt) begin
      if (ctrl_wren_cnt[2:0] != 3'b000)
        ctrl_write_en <= 1'b1;
      else
        ctrl_write_en <= 1'b0;
   end

   // 3-state enable for the data I/O generated such that to enable
   // write data output one-half clock cycle before
   // the first data word, and disable the write data
   // one-half clock cycle after the last data word

   //write enable to data path
   always @ (posedge clk0) begin
      ctrl_write_en_r1 <= ctrl_write_en;
      ctrl_write_en_r2 <= ctrl_write_en_r1;
      ctrl_write_en_r3 <= ctrl_write_en_r2;
      ctrl_write_en_r4 <= ctrl_write_en_r3;
      ctrl_write_en_r5 <= ctrl_write_en_r4;
      ctrl_write_en_r6 <= ctrl_write_en_r5;
   end // always @ (posedge clk0)

   assign ctrl_wren_r1 = ((additive_latency_value + cas_latency_value +
                           registered_dimm + ecc_value - 1'b1) == 4'b0010) ?
                         ctrl_write_en : ctrl_wren_r1_i;

   //write enable to data path
   always @ (posedge clk0) begin
      case(additive_latency_value + cas_latency_value +
           registered_dimm + ecc_value - 1'b1)
        4'b0011: ctrl_wren_r1_i <= ctrl_write_en;
        4'b0100: ctrl_wren_r1_i <= ctrl_write_en_r1;
        4'b0101: ctrl_wren_r1_i <= ctrl_write_en_r2;
        4'b0110: ctrl_wren_r1_i <= ctrl_write_en_r3;
        4'b0111: ctrl_wren_r1_i <= ctrl_write_en_r4;
        4'b1000: ctrl_wren_r1_i <= ctrl_write_en_r5;
        4'b1001: ctrl_wren_r1_i <= ctrl_write_en_r6;
        default: ctrl_wren_r1_i <= 1'b0;
      endcase
   end // always @ (posedge clk0)

   // DQS enable to data path
   always @ (state or init_state) begin
      if ((state[12] /*FIRST_WRITE*/) || (init_state[18] /*INIT_PATTERN_WRITE*/)
          || (init_state[12] /* Add INIT_DUMMY_WRITE*/))
        dqs_reset <= 1'b1;
      else
        dqs_reset <= 1'b0;
   end

   always @ (posedge clk0) begin
      if (rst_r1) begin
         ctrl_dqs_rst_r1 <= 1'b0;
         dqs_reset_r1 <= 1'b0;
         dqs_reset_r2 <= 1'b0;
         dqs_reset_r3 <= 1'b0;
         dqs_reset_r4 <= 1'b0;
         dqs_reset_r5 <= 1'b0;
         dqs_reset_r6 <= 1'b0;
      end
      else begin
         dqs_reset_r1 <= dqs_reset;
         dqs_reset_r2 <= dqs_reset_r1;
         dqs_reset_r3 <= dqs_reset_r2;
         dqs_reset_r4 <= dqs_reset_r3;
         dqs_reset_r5 <= dqs_reset_r4;
         dqs_reset_r6 <= dqs_reset_r5;
         case(additive_latency_value + cas_latency_value +
              registered_dimm  + ecc_value)
           4'b0011: ctrl_dqs_rst_r1 <= dqs_reset;
           4'b0100: ctrl_dqs_rst_r1 <= dqs_reset_r1;
           4'b0101: ctrl_dqs_rst_r1 <= dqs_reset_r2;
           4'b0110: ctrl_dqs_rst_r1 <= dqs_reset_r3;
           4'b0111: ctrl_dqs_rst_r1 <= dqs_reset_r4;
           4'b1000: ctrl_dqs_rst_r1 <= dqs_reset_r5;
           4'b1001: ctrl_dqs_rst_r1 <= dqs_reset_r6;
           default: ctrl_dqs_rst_r1 <= 1'b0;
         endcase // case(additive_latency_value + cas_latency_value )
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   always @ (state or init_state or wrburst_cnt) begin
      if ((state[12] /*FIRST_WRITE*/) || (state[13] /*BURST_WRITE*/) ||
          (init_state[18] /*INIT_PATTERN_WRITE*/) ||
          (init_state[12] /* Add INIT_DUMMY_WRITE*/) || (wrburst_cnt != 3'b000))
        dqs_en = 1'b1;
      else
        dqs_en = 1'b0;
   end

   always @ (posedge clk0) begin
      if (rst_r1) begin
         ctrl_dqs_en_r1 <= 1'b0;
         dqs_en_r1 <= 1'b0;
         dqs_en_r2 <= 1'b0;
         dqs_en_r3 <= 1'b0;
         dqs_en_r4 <= 1'b0;
         dqs_en_r5 <= 1'b0;
         dqs_en_r6 <= 1'b0;
      end
      else begin
         dqs_en_r1 <= dqs_en;
         dqs_en_r2 <= dqs_en_r1;
         dqs_en_r3 <= dqs_en_r2;
         dqs_en_r4 <= dqs_en_r3;
         dqs_en_r5 <= dqs_en_r4;
         dqs_en_r6 <= dqs_en_r5;
         case(additive_latency_value + cas_latency_value  +
              registered_dimm  + ecc_value)
           4'b0011: ctrl_dqs_en_r1 <= dqs_en;
           4'b0100: ctrl_dqs_en_r1 <= dqs_en_r1;
           4'b0101: ctrl_dqs_en_r1 <= dqs_en_r2;
           4'b0110: ctrl_dqs_en_r1 <= dqs_en_r3;
           4'b0111: ctrl_dqs_en_r1 <= dqs_en_r4;
           4'b1000: ctrl_dqs_en_r1 <= dqs_en_r5;
           4'b1001: ctrl_dqs_en_r1 <= dqs_en_r6;
           default:ctrl_dqs_en_r1 <= 1'b0;
         endcase
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      odt_en_single <= dqs_en | dqs_en_r1 | dqs_en_r2 |
                       dqs_en_r3 | dqs_en_r4 | dqs_en_r5;
   end

   // cas count
   always @ (posedge clk0) begin
      if (rst_r1)
        cas_count[2:0] <= 3'b000;
      else if (init_state[16] /*INIT_DUMMY_FIRST_READ*/)
        cas_count[2:0] <= cas_latency_value[2:0] + `REGISTERED;
      else if (cas_count[2:0] != 3'b000)
        cas_count[2:0] <= cas_count[2:0] - 1;
      else
        cas_count[2:0] <= 3'b000;
   end

   //dummy_read enable
   always @ (posedge clk0) begin
      if (rst_r1)
        dummy_read_en <= 1'b0;
      else if (init_state[14] /*INIT_DUMMY_READ*/)
        dummy_read_en <= 1'b1;
      else if (phy_dly_slct_done == 1'b1)
        dummy_read_en <= 1'b0;
      else
        dummy_read_en <= dummy_read_en;
   end

   // ctrl_dummyread_start signal generation to the data path module
   always @ (posedge clk0) begin
      if (rst_r1)
        ctrl_dummyread_start_r1 <= 1'b0;
      else if ((dummy_read_en == 1'b1) && (cas_count == 3'b000))
        ctrl_dummyread_start_r1 <= 1'b1;
      else if (phy_dly_slct_done == 1'b1)
        ctrl_dummyread_start_r1 <= 1'b0;
      else
        ctrl_dummyread_start_r1 <= ctrl_dummyread_start_r1;
   end

   // register ctrl_dummyread_start signal
   // To account ECC and Aditive latency, it is registered.
   // Counter cas_count considers CAS Latency and RDIMM.
   always @ (posedge clk0) begin
      if (rst_r1) begin
         ctrl_dummyread_start_r2 <= 1'b0;
         ctrl_dummyread_start_r3 <= 1'b0;
         ctrl_dummyread_start_r4 <= 1'b0;
         ctrl_dummyread_start_r5 <= 1'b0;
         ctrl_dummyread_start_r6 <= 1'b0;
         ctrl_dummyread_start_r7 <= 1'b0;
         ctrl_dummyread_start_r8 <= 1'b0;
         ctrl_dummyread_start_r9 <= 1'b0;
         ctrl_dummyread_start    <= 1'b0;
      end
      else begin
         ctrl_dummyread_start_r2 <= ctrl_dummyread_start_r1;
         ctrl_dummyread_start_r3 <= ctrl_dummyread_start_r2;
         ctrl_dummyread_start_r4 <= ctrl_dummyread_start_r3;
         ctrl_dummyread_start_r5 <= ctrl_dummyread_start_r4;
         ctrl_dummyread_start_r6 <= ctrl_dummyread_start_r5;
         ctrl_dummyread_start_r7 <= ctrl_dummyread_start_r6;
         ctrl_dummyread_start_r8 <= ctrl_dummyread_start_r7;
         ctrl_dummyread_start_r9 <= ctrl_dummyread_start_r8;
         ctrl_dummyread_start    <= ctrl_dummyread_start_r9;
      end
   end // always @ (posedge clk0)

   // read_wait/write_wait to idle count
   // the state machine waits for 15 clock cycles in the write wait state for
   // any wr/rd commands to be issued. If no commands are issued in 15 clock
   // cycles, the statemachine enters the idle state and stays in the
   // idle state until an auto refresh is required.

   always @ (posedge clk0) begin
      if (rst_r1)
        idle_cnt[3:0] <= 4'b0000;
      else if (state[9] /*FIRST_READ*/ || state[12] /*FIRST_WRITE*/ ||
               state[10] /*BURST_READ*/ ||  state[13] /*BURST_WRITE*/)
        idle_cnt[3:0] <= 4'b1111 ;
      else if (idle_cnt[3:0] != 4'b0000)
        idle_cnt[3:0] <= idle_cnt[3:0] - 1;
      else
        idle_cnt[3:0] <= 4'b0000;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        cas_check_count[3:0] <= 4'b0000;
      else if ((state_r2[9] /*FIRST_READ*/) ||
               (init_state_r2[20] /*INIT_PATTERN_READ*/))
        cas_check_count[3:0] <= (cas_latency_value - 1);
      else if (cas_check_count[3:0] != 4'b0000)
        cas_check_count[3:0] <= cas_check_count[3:0] - 1;
      else
        cas_check_count[3:0] <= 4'b0000;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        rdburst_cnt <= 4'b0000;
      else if(state_r3[10] /*BURST_READ*/) begin
         if(burst_cnt[2])
           rdburst_cnt <= (({burst_cnt[2:0],1'b0}) -
                           (4'd7 - cas_latency_value));
         else
           rdburst_cnt <= (({burst_cnt[2:0],1'b0}) -
                           (4'd5 - cas_latency_value));
      end
      else if ((cas_check_count == 4'b0010))
        rdburst_cnt <= {1'b0, burst_cnt};
      else if (rdburst_cnt != 4'b0000)
        rdburst_cnt <= rdburst_cnt - 1'b1;
      else
        rdburst_cnt <= 4'b0000;
   end // always @ (posedge clk0)

   //read enable to data path
   always @ (rdburst_cnt) begin
      if (rdburst_cnt == 4'b0000)
        ctrl_read_en = 1'b0;
      else
        ctrl_read_en = 1'b1;
   end

   always @ (posedge clk0) begin
      if (rst_r1) begin
         ctrl_read_en_r  <= 1'b0;
         ctrl_read_en_r1 <= 1'b0;
         ctrl_read_en_r2 <= 1'b0;
         ctrl_read_en_r3 <= 1'b0;
         ctrl_read_en_r4 <= 1'b0;
      end
      else begin
         ctrl_read_en_r  <= ctrl_read_en;
         ctrl_read_en_r1 <= ctrl_read_en_r;
         ctrl_read_en_r2 <= ctrl_read_en_r1;
         ctrl_read_en_r3 <= ctrl_read_en_r2;
         ctrl_read_en_r4 <= ctrl_read_en_r3;
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      if (rst_r1)
        ctrl_rden_r1  <= 1'b0;
      else begin
         case(additive_latency_value + ecc_value + registered_dimm)
           4'b0000: ctrl_rden_r1  <= ctrl_read_en;
           4'b0001: ctrl_rden_r1  <= ctrl_read_en_r;
           4'b0010: ctrl_rden_r1  <= ctrl_read_en_r1;
           4'b0011: ctrl_rden_r1  <= ctrl_read_en_r2;
           4'b0100: ctrl_rden_r1  <= ctrl_read_en_r3;
           default:ctrl_rden_r1 <= 1'b0;
         endcase // case(additive_latency_value + ecc_value + registered_dimm)
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   // write address FIFO read enable signals

   assign af_rden = (state[12] /*FIRST_WRITE*/ || state[9] /*FIRST_READ*/ ||
                     state[13] /*BURST_WRITE*/ || state[10] /*BURST_READ*/ ||
                     ((state[2] /*MODE_REGISTER_WAIT*/) & lmr_r & !mrd_count) ||
                     ((state[3] /*PRECHARGE*/ )&& pre_r) ||
                     ((state[5] /*AUTO_REFRESH*/) && ref_r) ||
                     ((state[7] /*ACTIVE*/)&& act_r));

   // write data fifo read enable
   always @ (posedge clk0) begin
      if (rst_r1)
        wdf_rden_r  <= 1'b0;
      else if ((state[12] /*FIRST_WRITE*/) || (state[13] /*BURST_WRITE*/) ||
               (init_state[18] /*INIT_PATTERN_WRITE*/) ||
               (init_state[12]/*INIT_DUMMY_WRITE*/))
        wdf_rden_r  <= 1'b1;
      else
        wdf_rden_r  <= 1'b0;
   end

   always @ (posedge clk0) begin
      if (rst_r1) begin
         wdf_rden_r2 <= 1'b0;
         wdf_rden_r3 <= 1'b0;
         wdf_rden_r4 <= 1'b0;
      end
      else begin
         wdf_rden_r2 <= wdf_rden_r;
         wdf_rden_r3 <= wdf_rden_r2;
         wdf_rden_r4 <= wdf_rden_r3;
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   // Read enable to the data fifo

   always @ (burst_cnt or wdf_rden_r or wdf_rden_r2 or
             wdf_rden_r3 or wdf_rden_r4) begin
      if (burst_cnt == 3'b010)
        ctrl_wdf_read_en = (wdf_rden_r | wdf_rden_r2) ;
      else if (burst_cnt == 3'b100)
        ctrl_wdf_read_en = (wdf_rden_r | wdf_rden_r2 |
                             wdf_rden_r3 | wdf_rden_r4);
      else
        ctrl_wdf_read_en = 1'b0;
   end

   always @ (posedge clk0) begin
      if (rst_r1) begin
         ctrl_wdf_rden_int   <= 1'b0;
         ctrl_wdf_read_en_r1 <= 1'b0;
         ctrl_wdf_read_en_r2 <= 1'b0;
         ctrl_wdf_read_en_r3 <= 1'b0;
         ctrl_wdf_read_en_r4 <= 1'b0;
         ctrl_wdf_read_en_r5 <= 1'b0;
         ctrl_wdf_read_en_r6 <= 1'b0;
      end
      else begin
         ctrl_wdf_read_en_r1 <= ctrl_wdf_read_en;
         ctrl_wdf_read_en_r2 <= ctrl_wdf_read_en_r1;
         ctrl_wdf_read_en_r3 <= ctrl_wdf_read_en_r2;
         ctrl_wdf_read_en_r4 <= ctrl_wdf_read_en_r3;
         ctrl_wdf_read_en_r5 <= ctrl_wdf_read_en_r4;
         ctrl_wdf_read_en_r6 <= ctrl_wdf_read_en_r5;
         case(additive_latency_value + cas_latency_value + registered_dimm)
           4'b0011: ctrl_wdf_rden_int <= ctrl_wdf_read_en;
           4'b0100: ctrl_wdf_rden_int <= ctrl_wdf_read_en_r1;
           4'b0101: ctrl_wdf_rden_int <= ctrl_wdf_read_en_r2;
           4'b0110: ctrl_wdf_rden_int <= ctrl_wdf_read_en_r3;
           4'b0111: ctrl_wdf_rden_int <= ctrl_wdf_read_en_r4;
           4'b1000: ctrl_wdf_rden_int <= ctrl_wdf_read_en_r5;
           4'b1001: ctrl_wdf_rden_int <= ctrl_wdf_read_en_r6;
           default: ctrl_wdf_rden_int <= 1'b0;
         endcase
         // case(additive_latency_value + cas_latency_value + registered_dimm)
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   always @(posedge clk0) begin
      if(rst_r1)
        count6 <= 7'b0000000;
      else if(init_state[4] /*INIT_PRECHARGE_WAIT*/ ||
              init_state[2] /*INIT_MODE_REGISTER_WAIT*/ ||
              init_state[6] /*INIT_AUTO_REFRESH_WAIT*/ ||
              init_state[19] /*INIT_PATTERN_WRITE_READ*/ ||
              init_state[13] /*INIT_DUMMY_WRITE_READ*/ ||
              init_state[21] /*INIT_PATTERN_READ_WAIT*/ ||
              init_state[15] /*INIT_DUMMY_READ_WAIT*/ ||
              init_state[11] /*INIT_DUMMY_ACTIVE_WAIT*/ )
        count6 <= count6 + 1;
      else
        count6 <= 7'b0000000;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        init_state <= INIT_IDLE;
      else
        init_state <= init_next_state;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        state <= IDLE;
      else
        state <= next_state;
   end

   assign dummy_write_state = (init_state[18] /*INIT_PATTERN_WRITE*/ |
                               init_state[12]/*INIT_DUMMY_WRITE*/);

   always @(posedge clk0) begin
      if(rst_r1)
        dummy_write_state_r <= 1'b0;
      else
        dummy_write_state_r <= dummy_write_state;
   end

   //***************************************************************************
   // Initialization state machine
   //***************************************************************************

   always @ (*) begin

      init_next_state = init_state;

      case (init_state)

        INIT_IDLE : begin
           if (init_memory && done_200us == 1'b1) begin
              case (init_count ) // synthesis parallel_case full_case

                4'h0 : init_next_state = INIT_COUNT_200;

                4'h1 : begin
                   if (count_200cycle_done_r)
                     init_next_state = INIT_PRECHARGE;
                   else
                     init_next_state = INIT_IDLE;
                end

                4'h2 : init_next_state = INIT_LOAD_MODE; //emr(2)

                4'h3 : init_next_state = INIT_LOAD_MODE; //emr(3);

                4'h4 : init_next_state = INIT_LOAD_MODE; //emr;

                4'h5 : init_next_state = INIT_LOAD_MODE; //lmr;

                4'h6 : init_next_state = INIT_PRECHARGE;

                4'h7 : init_next_state = INIT_AUTO_REFRESH;

                4'h8 : init_next_state = INIT_AUTO_REFRESH;

                4'h9 : init_next_state = INIT_LOAD_MODE; // LM

                4'hA : init_next_state = INIT_LOAD_MODE;  // EMR OCD DEFAULT

                4'hB : init_next_state = INIT_LOAD_MODE; //EMR OCD EXIT

                4'hC : init_next_state = INIT_COUNT_200;

                4'hD :  begin
                   if( (chip_cnt < `CS_WIDTH-1))
                     init_next_state = INIT_DEEP_MEMORY_ST;
                   else  if (`PHY_MODE  && count_200cycle_done_r)
                     init_next_state = INIT_DUMMY_READ_CYCLES;
                   else
                     init_next_state = INIT_IDLE;
                end

                4'hE :  begin
                   if (phy_dly_slct_done)
                     init_next_state = INIT_PRECHARGE;
                   else
                     init_next_state = INIT_IDLE;
                end

                4'hF :  begin
                   if (comp_done_r)
                     init_next_state = INIT_IDLE;
                end

                default: init_next_state = INIT_IDLE;

              endcase // case(init_count)

           end
        end // case: INIT_IDLE

        INIT_DEEP_MEMORY_ST     : init_next_state = INIT_IDLE;

        INIT_COUNT_200          : init_next_state = INIT_COUNT_200_WAIT;

        INIT_COUNT_200_WAIT     : begin
           if (count_200cycle_done_r)
             init_next_state = INIT_IDLE;
           else
             init_next_state = INIT_COUNT_200_WAIT;
        end

        INIT_DUMMY_READ_CYCLES  : init_next_state = INIT_DUMMY_ACTIVE;

        INIT_DUMMY_ACTIVE       : init_next_state = INIT_DUMMY_ACTIVE_WAIT;

        INIT_DUMMY_ACTIVE_WAIT  : begin
           if (count6 == CNTNEXT)
             init_next_state = INIT_DUMMY_WRITE;
           else
             init_next_state = INIT_DUMMY_ACTIVE_WAIT;
        end

        INIT_DUMMY_WRITE        : begin
           init_next_state = INIT_DUMMY_WRITE_READ;
        end

        INIT_DUMMY_WRITE_READ   : begin
           if(count6 == CNTNEXT)
             init_next_state = INIT_DUMMY_FIRST_READ;
           else
             init_next_state = INIT_DUMMY_WRITE_READ;
        end

        INIT_DUMMY_FIRST_READ   : init_next_state = INIT_DUMMY_READ_WAIT;

        INIT_DUMMY_READ         : init_next_state = INIT_DUMMY_READ_WAIT;

        INIT_DUMMY_READ_WAIT    : begin
           if (phy_dly_slct_done) begin
              if (count6 == CNTNEXT)
                init_next_state = INIT_PATTERN_WRITE;
              else
                init_next_state = INIT_DUMMY_READ_WAIT;
           end
           else
             init_next_state = INIT_DUMMY_READ;
        end

        INIT_PRECHARGE          : init_next_state = INIT_PRECHARGE_WAIT;

        INIT_PRECHARGE_WAIT     : begin
           if (count6 == CNTNEXT)
             init_next_state = INIT_IDLE;
           else
             init_next_state = INIT_PRECHARGE_WAIT;
        end // case: INIT_PRECHARGE_WAIT

        INIT_LOAD_MODE          : init_next_state = INIT_MODE_REGISTER_WAIT;

        INIT_MODE_REGISTER_WAIT : begin
           if (count6 == CNTNEXT)
             init_next_state = INIT_IDLE;
           else
             init_next_state = INIT_MODE_REGISTER_WAIT;
        end

        INIT_AUTO_REFRESH       : init_next_state = INIT_AUTO_REFRESH_WAIT;

        INIT_AUTO_REFRESH_WAIT  : begin
           if (count6 == CNTNEXT)
             init_next_state = INIT_IDLE;
           else
             init_next_state = INIT_AUTO_REFRESH_WAIT;
        end

        INIT_PATTERN_WRITE      : init_next_state = INIT_PATTERN_WRITE_READ;

        INIT_PATTERN_WRITE_READ : begin
           if (count6 == CNTNEXT)
             init_next_state = INIT_PATTERN_READ;
           else
             init_next_state = INIT_PATTERN_WRITE_READ;
        end

        INIT_PATTERN_READ       : init_next_state = INIT_PATTERN_READ_WAIT;

        INIT_PATTERN_READ_WAIT  : begin
           // Precharge fix for pattern read
           if(comp_done_r)
             init_next_state = INIT_PRECHARGE;
           // Controller issues a second pattern calibration read
           // if the first one does not result in a successful calibration
           else if (!cal_first_loop)
             init_next_state = INIT_PATTERN_READ;
           else
             init_next_state = INIT_PATTERN_READ_WAIT;
        end

        default: init_next_state = INIT_IDLE;

      endcase // case(state)
   end // always @ (...

   //***************************************************************************
   // main control state machine
   //***************************************************************************

   always @ (*) begin

      next_state = state;
      case (state)

        IDLE                    : begin
           if ((conflict_detect_r || lmr_pre_ref_act_cmd_r || auto_ref) &&
               ras_count == 5'b0 && init_done_int)   // if (init_memory)
             next_state = PRECHARGE;
           else if ((wr_r  || rd_r  ) && (ras_count == 5'b0))
             next_state = ACTIVE;
        end // case: IDLE

        PRECHARGE               : next_state = PRECHARGE_WAIT;

        // Precharge fix for deep memory
        PRECHARGE_WAIT          : begin
           if (rp_count == 3'b000) begin
              if (auto_ref || ref_r) begin
                 if ( pre_cnt < `CS_WIDTH && init_memory == 1'b0)
                   next_state = PRECHARGE;
                 else
                   next_state = AUTO_REFRESH;
              end
              else if (lmr_r)
                next_state = LOAD_MODE;
              else if (conflict_detect_r || act_r)
                next_state = ACTIVE;
              else
                next_state = IDLE;
           end else begin
              next_state = PRECHARGE_WAIT;
           end // else: !if(rp_count == 2'b01)
        end // case: `precharge_wait

        LOAD_MODE               : next_state = MODE_REGISTER_WAIT;

        MODE_REGISTER_WAIT      : begin
           if (mrd_count == 1'b0)
             next_state = IDLE;
           else
             next_state = MODE_REGISTER_WAIT;
        end

        AUTO_REFRESH            : next_state = AUTO_REFRESH_WAIT;

        AUTO_REFRESH_WAIT       : begin
           if ( auto_cnt < `CS_WIDTH && rfc_count == 8'b00000001 &&
                init_memory == 1'b0)
             next_state = AUTO_REFRESH;
           else if ((rfc_count == 8'b00000001) && (conflict_detect_r))
             next_state = ACTIVE;
           else if (rfc_count == 8'b00000001)
             next_state = IDLE;
           else
             next_state = AUTO_REFRESH_WAIT;
        end

        ACTIVE                  : next_state = ACTIVE_WAIT;

        ACTIVE_WAIT             : begin
        // first active or when new row is opened
           if (rcd_count == 3'b000) begin
              if(wr)
                next_state = FIRST_WRITE;
              else if (rd)
                next_state = FIRST_READ;
              else
                next_state = IDLE;
           end
           else
             next_state = ACTIVE_WAIT;
        end // case: ACTIVE_WAIT

        FIRST_WRITE             : next_state = WRITE_WAIT;

        BURST_WRITE             : next_state = WRITE_WAIT;

        WRITE_WAIT              : begin
           if ((conflict_detect & (~conflict_resolved_r))|| auto_ref)  begin
              if ((wtp_count == 4'b0000) && (ras_count == 5'b0))
                next_state = PRECHARGE;
              else
                next_state = WRITE_WAIT;
           end
           else if (rd)
             next_state = WRITE_READ;
           else if ((wr) && (wrburst_cnt == 3'b010))
             next_state = BURST_WRITE;
           // added to improve the efficiency
           else if((wr) && (wrburst_cnt == 3'b000))
             next_state = FIRST_WRITE;
           else if (idle_cnt == 4'b0000)
             next_state = PRECHARGE;
           else
             next_state = WRITE_WAIT;
        end // case: WRITE_WAIT

        WRITE_READ              : begin
           if (wr_to_rd_count == 4'b0000)
             next_state = FIRST_READ;
           else
             next_state = WRITE_READ;
        end

        FIRST_READ              : next_state = READ_WAIT;

        BURST_READ              : next_state = READ_WAIT;

        READ_WAIT               : begin
           if ((conflict_detect & (~conflict_resolved_r)) || auto_ref) begin
              if(rtp_count == 4'b0000 && ras_count == 5'b0)
                next_state = PRECHARGE;
              else
                next_state = READ_WAIT;
           end
           else if (wr)
             next_state = READ_WRITE;
           else if ((rd) && (read_burst_cnt <= 3'b010)) begin
              if(af_empty_r)
                next_state = FIRST_READ;
              else
                next_state = BURST_READ;
           end
           else if (idle_cnt == 4'b0000)
             next_state = PRECHARGE;
           else
             next_state = READ_WAIT;
        end // case: READ_WAIT

        READ_WRITE              : begin
           if (rd_to_wr_count == 4'b0000)
             next_state = FIRST_WRITE;
           else
             next_state = READ_WRITE;
        end

        default: next_state = INIT_IDLE;

      endcase // case(state)
   end // always @ (...

   //register command outputs
   always @ (posedge clk0) begin
      state_r2 <= state;
      state_r3 <= state_r2;
      init_state_r2 <= init_state;
   end

  //***************************************************************************
  // Memory control/address
  //***************************************************************************

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_ras_r <= 1'b1;
      else if (state[1] /*LOAD_MODE*/ || state[3] /*PRECHARGE*/ ||
               state[7] /*ACTIVE*/ || state[5] /*AUTO_REFRESH*/ ||
               init_state[1]/*INIT_LOAD_MODE*/|| init_state[3]/*INIT_PRECHARGE*/
               || init_state[5] /*INIT_AUTO_REFRESH*/ ||
               init_state[10] /*INIT_DUMMY_ACTIVE*/ )
        ddr2_ras_r <= 1'b0;
      else
        ddr2_ras_r <= 1'b1;
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_cas_r <= 1'b1;
      else if (state[1] /*LOAD_MODE*/ || state[12] /*FIRST_WRITE*/ ||
               state[13] /*BURST_WRITE*/ || state[9] /*FIRST_READ*/ ||
               state[10]/*BURST_READ*/ || state[5] /*AUTO_REFRESH*/
               || init_state[16]/*INIT_DUMMY_FIRST_READ*/
               || init_state[1] /*INIT_LOAD_MODE*/ ||
               init_state[5] /*INIT_AUTO_REFRESH*/
               || init_state[14] /*INIT_DUMMY_READ*/ ||
               init_state[20] /*INIT_PATTERN_READ*/ ||
               init_state[18] /*INIT_PATTERN_WRITE*/ ||
               init_state[12] /*INIT_DUMMT_WRITE*/)
        ddr2_cas_r <= 1'b0;
      else
        ddr2_cas_r <= 1'b1;
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_we_r <= 1'b1;
      else if (state[1] /*LOAD_MODE*/ || state[3] /*PRECHARGE*/ ||
               state[12] /*FIRST_WRITE*/ || state[13] /*BURST_WRITE*/ ||
               init_state[18] /*INIT_PATTERN_WRITE*/ ||
               init_state[12] /*INIT_DUMMY_WRITE*/ ||
               init_state[1] /*INIT_LOAD_MODE*/ ||
               init_state[3] /*INIT_PRECHARGE*/)
        ddr2_we_r <= 1'b0;
      else
        ddr2_we_r <= 1'b1;
   end

   //register commands to the memory
   always @ (posedge clk0) begin
      if (rst_r1) begin
         ddr2_ras_r2 <= 1'b1;
         ddr2_cas_r2 <= 1'b1;
         ddr2_we_r2  <= 1'b1;
      end
      else begin
         ddr2_ras_r2 <= ddr2_ras_r;
         ddr2_cas_r2 <= ddr2_cas_r;
         ddr2_we_r2  <= ddr2_we_r;
      end
   end

   //register commands to the memory
   always @ (posedge clk0) begin
      if (rst_r1) begin
         ddr2_ras_r3 <= 1'b1;
         ddr2_cas_r3 <= 1'b1;
         ddr2_we_r3  <= 1'b1;
      end
      else begin
         ddr2_ras_r3 <= ddr2_ras_r2;
         ddr2_cas_r3 <= ddr2_cas_r2;
         ddr2_we_r3  <= ddr2_we_r2;
      end // else: !if(rst_r1)
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      if (rst_r1)
        row_addr_r[`ROW_ADDRESS-1:0] <= {`ROW_ADDRESS{1'b0}};
      else
        row_addr_r[`ROW_ADDRESS-1:0] <=
          af_addr[(`ROW_ADDRESS + `COLUMN_ADDRESS)-1 :`COLUMN_ADDRESS];
   end

   // chip enable generation logic

   always @(posedge clk0) begin
      if (rst_r1)
        ddr2_cs_r[`CS_WIDTH-1 : 0] <=  `CS_WIDTH'h0;
      else begin
         if (af_addr_r[`CHIP_ADDRESS + `BANK_ADDRESS +`ROW_ADDRESS +
                       `COLUMN_ADDRESS-1 : `BANK_ADDRESS +`ROW_ADDRESS +
                       `COLUMN_ADDRESS]  == `CHIP_ADDRESS'h0)
           ddr2_cs_r[`CS_WIDTH-1 : 0] <= `CS_WIDTH'hE;
         else if (af_addr_r[`CHIP_ADDRESS + `BANK_ADDRESS +`ROW_ADDRESS +
                            `COLUMN_ADDRESS-1 : `BANK_ADDRESS +`ROW_ADDRESS +
                            `COLUMN_ADDRESS] == `CHIP_ADDRESS'h1)
           ddr2_cs_r[`CS_WIDTH-1 : 0] <= `CS_WIDTH'hD;
         else if (af_addr_r[`CHIP_ADDRESS + `BANK_ADDRESS +`ROW_ADDRESS +
                            `COLUMN_ADDRESS-1 : `BANK_ADDRESS +`ROW_ADDRESS +
                            `COLUMN_ADDRESS] == `CHIP_ADDRESS'h2)
           ddr2_cs_r[`CS_WIDTH-1 : 0] <= `CS_WIDTH'hB;
         else if (af_addr_r[`CHIP_ADDRESS + `BANK_ADDRESS +`ROW_ADDRESS +
                            `COLUMN_ADDRESS-1 : `BANK_ADDRESS +`ROW_ADDRESS +
                            `COLUMN_ADDRESS] == `CHIP_ADDRESS'h3)
           ddr2_cs_r[`CS_WIDTH-1 : 0] <= `CS_WIDTH'h7;
         else
           ddr2_cs_r[`CS_WIDTH-1 : 0] <= `CS_WIDTH'hF;
      end // else: !if(rst_r1)
   end // always@ (posedge clk0)

   // Memory address during init
   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_address_init_r <= {`ROW_ADDRESS{1'b0}};
      else begin
         if (init_state_r2[3] /*INIT_PRECHARGE*/) begin
           // A10 = 1 for precharge all
           ddr2_address_init_r     <= {`ROW_ADDRESS{1'b0}};
           ddr2_address_init_r[10] <= 1'b1;
         end
         else if ( init_state_r2[1] /*INIT_LOAD_MODE*/ && init_count_cp == 4'h5)
           // A0 == 0 for DLL enable
           ddr2_address_init_r <= ext_mode_reg;
         else if ( init_state_r2[1] /*INIT_LOAD_MODE*/ &&
                   init_count_cp == 4'h6) begin
           // A8 == 1 for DLL reset
           ddr2_address_init_r    <= load_mode_reg;
           ddr2_address_init_r[8] <= 1'b1;
         end
         else if (init_state_r2[1] /*INIT_LOAD_MODE*/ && init_count_cp ==4'hA)
           ddr2_address_init_r <= load_mode_reg;
         else if (init_state_r2[1] /*INIT_LOAD_MODE*/ &&
                  init_count_cp ==4'hB) begin
           // OCD DEFAULT
           ddr2_address_init_r      <= ext_mode_reg;
           ddr2_address_init_r[9:7] <= 3'b111;
         end
         else if (init_state_r2[1] /*INIT_LOAD_MODE*/ && init_count_cp ==4'hC)
           // OCD EXIT
           ddr2_address_init_r <= ext_mode_reg;
         else if(init_state_r2[10] /*INIT_DUMMY_ACTIVE*/)
           ddr2_address_init_r <= row_addr_r;
         else
           ddr2_address_init_r <= {`ROW_ADDRESS{1'b0}};
      end
   end // always @ (posedge clk0)

  // turn off auto-precharge when issuing commands (A10 = 0)
  // mapping the col add for linear addressing.
  generate
    if (COL_WIDTH == ROW_WIDTH-1) begin: gen_ddr_addr_col_0
      assign ddr_addr_col = {af_addr_r1[COL_WIDTH-1:10], 1'b0,
                             af_addr_r1[9:0]};
    end else begin
      if (COL_WIDTH > 10) begin: gen_ddr_addr_col_1
        assign ddr_addr_col = {{(ROW_WIDTH-COL_WIDTH-1){1'b0}},
                               af_addr_r1[COL_WIDTH-1:10], 1'b0,
                               af_addr_r1[9:0]};
      end else begin: gen_ddr_addr_col_2
        assign ddr_addr_col = {{(ROW_WIDTH-COL_WIDTH-1){1'b0}}, 1'b0,
                               af_addr_r1[COL_WIDTH-1:0]};
      end
    end
  endgenerate

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_address_r1 <= {`ROW_ADDRESS{1'b0}};
      else if ((state_r2[7] /*ACTIVE*/))  // if (init_memory)
        ddr2_address_r1 <= row_addr_r;
      else if (state_r2[12] /*FIRST_WRITE*/ || state_r2[13] /*BURST_WRITE*/ ||
               state_r2[9] /*FIRST_READ*/ || state_r2[10] /*BURST_READ*/)
        ddr2_address_r1 <=  ddr_addr_col;
      else if (state_r2[3] /*PRECHARGE*/) begin
           ddr2_address_r1     <= {`ROW_ADDRESS{1'b0}};
           ddr2_address_r1[10] <= 1'b1;
      end
      else if (state_r2[1] /*LOAD_MODE*/)
        ddr2_address_r1 <= af_addr_r1[`ROW_ADDRESS-1:0];
      else
        ddr2_address_r1 <= {`ROW_ADDRESS{1'b0}};
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_address_r2 <= {`ROW_ADDRESS{1'b0}};
      else begin
         if(init_memory)
           ddr2_address_r2 <= ddr2_address_init_r;
         else
           ddr2_address_r2 <= ddr2_address_r1;
      end
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_ba_r1    <= `BANK_ADDRESS'h0;
      else if (init_memory == 1'b1 &&
               init_state_r2[1] == 1'b1 /*INIT_LOAD_MODE*/) begin
         if (init_count_cp == 4'h3)
           ddr2_ba_r1 <= `BANK_ADDRESS'h2; //emr2
         else if (init_count_cp == 4'h4)
           ddr2_ba_r1 <= `BANK_ADDRESS'h3; //emr3
         else if (init_count_cp == 4'h5 || init_count_cp == 4'hB ||
                  init_count_cp == 4'hC)
           ddr2_ba_r1 <= `BANK_ADDRESS'h1; //emr
         else
           ddr2_ba_r1[`BANK_ADDRESS-1:0] <= 2'b00;
      end
      else if ((state_r2[7] /*ACTIVE*/)||
               (init_state_r2[10] /*INIT_DUMMY_ACTIVE*/) ||
               (state_r2[1]/*LOAD_MODE*/) ||((state_r2[3]/*PRECHARGE*/) & pre_r)
               || (init_state_r2[1] /*INIT_LOAD_MODE*/) ||
               (init_state_r2[3] /*INIT_PRECHARGE*/))
        ddr2_ba_r1 <= af_addr_r[(`BANK_ADDRESS+`ROW_ADDRESS+`COLUMN_ADDRESS)-1:
                                (`COLUMN_ADDRESS + `ROW_ADDRESS)];
      else
        ddr2_ba_r1 <= ddr2_ba_r1[`BANK_ADDRESS-1:0];
   end // always @ (posedge clk0)

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_ba_r2[`BANK_ADDRESS-1:0] <= `BANK_ADDRESS'h0;
      else
        ddr2_ba_r2[`BANK_ADDRESS-1:0] <=  ddr2_ba_r1;
   end

   // Chip select logic is modified and then two flops are generated.
   //  One will go to out and other for odt logic.

   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hF;
      else if (init_memory == 1'b1 ) begin
         if (chip_cnt == 2'h0)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hE;
         else if (chip_cnt == 2'h1)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hD;
         else if (chip_cnt == 2'h2)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hB;
         else if (chip_cnt == 2'h3)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'h7;
         else
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hF;
      end
      //Precharge fix for deep memory
      else if ((state_r2[3] /*PRECHARGE*/ )) begin
         if (pre_cnt == 3'h1)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hE;
         else if (pre_cnt == 3'h2)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hD;
         else if (pre_cnt == 3'h3)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hB;
         else if (pre_cnt == 3'h4)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'h7;
         else if (pre_cnt == 3'h0)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= ddr2_cs_r1[`CS_WIDTH-1:0];
         else
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hF;
      end
      else if ((state_r2[5] /*AUTO_REFRESH*/ )) begin
         if (auto_cnt == 3'h1)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hE;
         else if (auto_cnt == 3'h2)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hD;
         else if (auto_cnt == 3'h3)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hB;
         else if (auto_cnt == 3'h4)
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'h7;
         else
           ddr2_cs_r1[`CS_WIDTH-1:0] <= `CS_WIDTH'hF;
      end
      else if ((state_r2[7] /*ACTIVE*/ ) ||
               (init_state_r2[10] /*INIT_DUMMY_ACTIVE*/) ||
               (state_r2[1]/*LOAD_MODE*/) || (state_r2[4] /*PRECHARGE_WAIT*/) ||
               (init_state_r2[1] /*INIT_LOAD_MODE*/) ||
               (init_state_r2[4] /*INIT_PRECHARGE_WAIT*/))
        ddr2_cs_r1[`CS_WIDTH-1:0] <= ddr2_cs_r[`CS_WIDTH-1:0];
      else
        ddr2_cs_r1[`CS_WIDTH-1:0] <= ddr2_cs_r1[`CS_WIDTH-1:0];
   end // always @ (posedge clk0)

   // synthesis attribute equivalent_register_removal of ddr2_cs_r_odt is "no";
   always @ (posedge clk0) begin
      if(rst_r1) begin
         ddr2_cs_r_out <= `CS_WIDTH'hF;
         ddr2_cs_r_odt <= `CS_WIDTH'hF;
      end
      else begin
         ddr2_cs_r_out <= ddr2_cs_r1;
         ddr2_cs_r_odt <= ddr2_cs_r1;
      end
   end

   always @ (posedge clk0) begin
      if(rst_r1) begin
         ddr2_cs_r_odt_r1 <= `CS_WIDTH'hF;
         ddr2_cs_r_odt_r2 <= `CS_WIDTH'hF;
      end
      else begin
         ddr2_cs_r_odt_r1 <= ddr2_cs_r_odt;
         ddr2_cs_r_odt_r2 <= ddr2_cs_r_odt_r1;
      end
   end

   always @ (posedge clk0) begin
      if (rst_r1)
        conflict_resolved_r <= 1'b0;
      else begin
         if ((state[4] /*PRECHARGE_WAIT*/) & conflict_detect_r)
           conflict_resolved_r  <= 1'b1;
         else if(af_rden)
           conflict_resolved_r  <= 1'b0;
      end
   end

   // synthesis attribute equivalent_register_removal of ddr2_cke_r is "no";
   always @ (posedge clk0) begin
      if (rst_r1)
        ddr2_cke_r <= `CKE_WIDTH'h0;
      else begin
         if(done_200us == 1'b1)
           ddr2_cke_r <= `CKE_WIDTH'hF;
      end
   end

   // odt
   // synthesis attribute max_fanout of odt_en_cnt is 1
   always @ (posedge clk0) begin
      if (rst_r1)
        odt_en_cnt <= 4'b0000;
      else if(((state[12] /*FIRST_WRITE*/) ||
               (init_state[12] /*INIT_DUMMY_WRITE*/) ||
               (init_state[18] /*INIT_PATTERN_WRITE*/)) && odt_enable)
        odt_en_cnt <= ((additive_latency_value + cas_latency_value)-2);
      else if(((state[9] /*FIRST_READ*/) ||
               (init_state[14] /*INIT_DUMMY_READ*/) ||
               (init_state[20] /*INIT_PATTERN_READ*/)) && odt_enable)
        odt_en_cnt <= ((additive_latency_value + cas_latency_value)-1);
      else if(odt_en_cnt != 4'b0000)
        odt_en_cnt <= odt_en_cnt - 1'b1;
      else
        odt_en_cnt <= 4'b0000;
   end

   // synthesis attribute max_fanout of odt_cnt is 1
   always @ (posedge clk0) begin
      if (rst_r1)
        odt_cnt <= 4'b0000;
      else if(((state[12] /*FIRST_WRITE*/) || (state[13] /*BURST_WRITE*/)  ||
               (init_state[12] /*INIT_DUMMY_WRITE*/) ||
               (init_state[18] /*INIT_PATTERN_WRITE*/)) && odt_enable)
        odt_cnt <= (additive_latency_value + cas_latency_value +
                    burst_cnt + registered_dimm);
      else if(((state[9] /*FIRST_READ*/) || (state[10] /*BURST_READ*/) ||
              (init_state[14] /*INIT_DUMMY_READ*/) ||
               (init_state[20] /*INIT_PATTERN_READ*/)) && odt_enable)
        odt_cnt <= ((additive_latency_value + cas_latency_value +
                     burst_cnt + registered_dimm) + 1);
      else if(odt_cnt != 4'b0000)
        odt_cnt <= odt_cnt - 1'b1;
      else
        odt_cnt <= 4'b0000;
   end

   // odt_en logic is made combinational to add a flop to the ctrl_odt logic
   // synthesis attribute max_fanout of odt_en is 1

   always @ (*) begin
      if((odt_en_cnt == 4'b0001) ||
         (odt_cnt > 4'b0010 && odt_en_cnt <= 4'b0001))
        odt_en  = `CS_WIDTH'hF;
      else
        odt_en = `CS_WIDTH'h0;
   end

   // added for deep designs
   
   
   
   
   always @ (posedge clk0) begin
      if (rst_r1)
           ctrl_odt  <= `CS_WIDTH'h0;
      else begin
         case (`CS_WIDTH)
           1: begin
              // ODT is only enabled on writes is disabled on read operations.
              if (ddr2_cs_r_odt_r2 ==`CS_WIDTH'h0 && odt_en_single == 1'b1)
                ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 1);
              else
                ctrl_odt <= `CS_WIDTH'h0;
           end

           2: begin
              if (`SINGLE_RANK) begin
                // Two single Rank DIMMs or components poupulated in
                // two different slots - Memory Componet sequence as
                // Component 0 is CS0 and Component 1 is CS1.
                // ODT is enabled for component 1 when writing into 0 and
                // enabled for component 0 when writing into component 1.
                // During read operations, ODT is enabled for component 1
                // when reading from 0 and enabled for component 0 when
                // reading from component 1.
                if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h2)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 10);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h1)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 01);
                else
                  ctrl_odt <= `CS_WIDTH'h0;
              end else if (`DUAL_RANK) begin
                // One Dual Rank DIMM is poupulated in single slot - Rank1 is
                // referred as CS0 and Rank2 is referres as CS1.
                // ODT is enabled for CS0 when writing into CS0 or CS1.
                // ODT is disabled on read operations.
                if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h2 &&
                    odt_en_single == 1'b1)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 01);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h1 &&
                         odt_en_single == 1'b1)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 01);
                else
                  ctrl_odt <= `CS_WIDTH'h0;
              end
           end

           3: begin
              if (`SINGLE_RANK) begin
                // Three single Rank DIMMs or components poupulated in
                // three different slots - Memory Component sequence as
                // Component 0 is CS0, Component 1 is CS1, Component 2 is CS2.
                // During write operations, ODT is enabled for component 2
                // when writing into 0 or 1 and enabled for component 1
                // when writing into component 2. During read operations,
                // ODT is enabled for component 2 when reading from 0 or 1 and
                // enabled for component 1 for reading from component 2.
                if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h6)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 100);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h5)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 100);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h3)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 010);
                else
                  ctrl_odt <= `CS_WIDTH'h0;
//              end else if (`DUAL_RANK) begin
                // One Dual Rank DIMM is poupulated in slot1 and
                // single Rank DIMM is populated in slot2 (2R/R) - Rank1 and
                // Rank2 of slot1 are referred as CS0 and CS1 respectively.
                // Rank1 of slot2 is referred as CS2 and Rank2 is unpopulated.
                // ODT is enabled for CS0 when writing into CS2 and
                // enabled for CS2 when writing into CS0 or CS1.
                // ODT is enabled for CS0 when reading from CS2 and
                // enabled for CS2 when reading from CS0 or CS1.
			    // 2R/R configuration is not supported by MIG, 
			    // ODT logic can be enabled by uncommenting the following logic.
//                if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h6)
//                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 100);
//                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h5)
//                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 100);
//                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h3)
//                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 001);
//                else
//                  ctrl_odt <= `CS_WIDTH'h0;
              end
           end

           4: begin
              if (`SINGLE_RANK) begin
                // Four single Rank DIMMs or components poupulated in
                // four different slots - Memory Component sequence as
                // Component 0 is CS0, Component 1 is CS1,
                // Component 2 is CS2 and Component 3 is CS3.
                // During write operations, ODT is enabled for component 3
                // when writing into 0 or 1 or 2 and enabled for component 2
                // when writing into component 3. During read operations,
                // ODT is enabled for component 3 when reading from 0 or 1 or 2
                // and enabled for component 2 for reading from component 3.
                if (ddr2_cs_r_odt_r2 == `CS_WIDTH'hE)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 1000);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'hD)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 1000);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'hB)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 1000);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h7)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 0100);
                else
                  ctrl_odt <= `CS_WIDTH'h0;
              end else if (`DUAL_RANK) begin
                // Two Dual Rank DIMMs are poupulated in slot1 and slot2 -
                // Rank1 and Rank2 of slot1 are referred as CS0 and CS1.
                // Rank1 and Rank2 of slot2 are referred as CS2 and CS3.
                // ODT is enabled for CS0 when writing into CS2 or CS3 and
                // enabled for CS2 when writing into CS0 or CS1.
                // ODT is enabled for CS0 when reading from CS2 or CS3 and
                // enabled for CS2 when reading from CS0 or CS1.
                if (ddr2_cs_r_odt_r2 == `CS_WIDTH'hE)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 0100);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'hD)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 0100);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'hB)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 0001);
                else if (ddr2_cs_r_odt_r2 == `CS_WIDTH'h7)
                  ctrl_odt <= (odt_en[`CS_WIDTH-1 : 0] & 0001);
                else
                  ctrl_odt <= `CS_WIDTH'h0;
              end
           end

         endcase // case
      end // else: !if(rst_r1)
   end

   assign ctrl_ddr2_address = ddr2_address_r2[`ROW_ADDRESS-1:0];
   assign ctrl_ddr2_ba      = ddr2_ba_r2[`BANK_ADDRESS-1:0];
   assign ctrl_ddr2_ras_l   = ddr2_ras_r3;
   assign ctrl_ddr2_cas_l   = ddr2_cas_r3;
   assign ctrl_ddr2_we_l    = ddr2_we_r3;
   assign ctrl_ddr2_odt     = ctrl_odt;
   assign ctrl_ddr2_cs_l    = ddr2_cs_r_out;

   assign ctrl_dqs_rst      = ctrl_dqs_rst_r1;
   assign ctrl_dqs_en       = ctrl_dqs_en_r1;
   assign ctrl_wren         = ctrl_wren_r1;
   assign ctrl_rden         = ctrl_rden_r1;
   assign ctrl_dummy_wr_sel = (ctrl_dummy_write == 1'b1) ? ctrl_wdf_rden_int
                              : 1'b0;

   assign ctrl_ddr2_cke  = ddr2_cke_r;


endmodule // ddr2_controller_0
