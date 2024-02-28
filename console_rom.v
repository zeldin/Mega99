module console_rom(input             clk,
		   input	     cs,
		   input [0:14]	     a,
		   output reg [0:15] q);

   reg [0:7] romh[0:4095];
   reg [0:7] roml[0:4095];
   
   initial begin
      $readmemh("994a_rom_hb.hex", romh);
      $readmemh("994a_rom_lb.hex", roml);
   end

   always @(posedge clk)
     if (cs)
       q <= { romh[a[3:14]], roml[a[3:14]] };

endmodule // console_rom
