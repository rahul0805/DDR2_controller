`timescale 1ns/1ps

module DDR2_idelay_ctrl
  (
   input        clk200,
   input        reset,
   output       rdy_status
   );

localparam IDELAYCTRL_NUM = 2;

wire [IDELAYCTRL_NUM-1 : 0] rdy_status_i;

genvar bnk_i;
generate
for(bnk_i=0; bnk_i<IDELAYCTRL_NUM; bnk_i=bnk_i+1)begin : IDELAYCTRL_INST
   IDELAYCTRL u_idelayctrl
     (
      .RDY     (rdy_status_i[bnk_i]),
      .REFCLK  (clk200),
      .RST     (reset)
      );
end
endgenerate

assign rdy_status = &rdy_status_i;

endmodule
