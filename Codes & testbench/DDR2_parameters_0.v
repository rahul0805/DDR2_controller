`timescale 1ns/1ps

// The reset polarity is set to active low by default. 
// You can change this by editing the parameter RESET_ACTIVE_LOW.
// Please do not change any of the other parameters directly by editing the RTL. 
// All other changes should be done through the GUI.

`define   DATA_WIDTH                               32
`define   DATA_STROBE_WIDTH                        4
`define   DATA_MASK_WIDTH                          4
`define   CLK_WIDTH                                2
`define   FIFO_16                                  2
`define   ECC_CNTRL_BITS                           0
`define   CS_WIDTH                                 1
`define   ODT_WIDTH                                1
`define   CKE_WIDTH                                1
`define   ROW_ADDRESS                              13
`define   MEMORY_WIDTH                             8
`define   REGISTERED                               0
`define   SINGLE_RANK                              1
`define   DUAL_RANK                                0
`define   DATABITSPERSTROBE                        8
`define   RESET_PORT                               0
`define   ECC_ENABLE                               0
`define   ECC_WIDTH                                0
`define   DQ_WIDTH                                 32
`define   DM_WIDTH                                 4
`define   DQS_WIDTH                                4
`define   MASK_ENABLE                              0
`define   USE_DM_PORT                              0
`define   COLUMN_ADDRESS                           10
`define   BANK_ADDRESS                             2
`define   DEBUG_EN                                 0
`define   CLK_TYPE                                 "SINGLE_ENDED"
`define   DQ_BITS                                  5
`define   LOAD_MODE_REGISTER                       13'b0011001000011
`define   EXT_LOAD_MODE_REGISTER                   13'b0000000001000
`define   CHIP_ADDRESS                             1
`define   RESET_ACTIVE_LOW                         1'b1
`define   TBY4TAPVALUE                   14
`define   RCD_COUNT_VALUE                          3'b011
`define   RAS_COUNT_VALUE                          5'b01001
`define   MRD_COUNT_VALUE                          1'b1
`define   RP_COUNT_VALUE                           3'b011
`define   RFC_COUNT_VALUE                          8'b00011001
`define   TRTP_COUNT_VALUE                         3'b001
`define   TWR_COUNT_VALUE                          3'b100
`define   TWTR_COUNT_VALUE                         3'b001
`define   MAX_REF_WIDTH                            11
`define   MAX_REF_CNT                              11'b11101010001
`define   PHY_MODE                                 1'b1
