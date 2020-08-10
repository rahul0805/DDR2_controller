`timescale 1ns/1ps
`include "../rtl/DDR2_parameters_0.v"

module DDR2_ram_d_0
  (
   input                       a0,
   input                       a1,
   input                       a2,
   input                       a3,
   input                       dpra0,
   input                       dpra1,
   input                       dpra2,
   input                       dpra3,
   input                       wclk,
   input                       we,
   input [`MEMORY_WIDTH-1:0]   d,

   output [`MEMORY_WIDTH-1:0]  dpo
   );


  genvar ram16_i;
  generate
    for (ram16_i = 0; ram16_i < `MEMORY_WIDTH;
         ram16_i = ram16_i + 1) begin: gen_ram16
      RAM16X1D u_ram16x1d
        (
         .D            (d[ram16_i]),
         .WE           (we),
         .WCLK         (wclk),
         .A0           (a0),
         .A1           (a1),
         .A2           (a2),
         .A3           (a3),
         .DPRA0        (dpra0),
         .DPRA1        (dpra1),
         .DPRA2        (dpra2),
         .DPRA3        (dpra3),
         .SPO          (),
         .DPO          (dpo[ram16_i])
         );
    end
  endgenerate

endmodule
