module console_rom(input             clk,
		   input	     cs,
		   input [0:14]	     a,
		   output reg [0:15] q,

		   // ROM access wishbone slave
		   input [0:15]	     wb_adr_i,
		   input [0:7]	     wb_dat_i,
		   output [0:7]	     wb_dat_o,
		   input	     wb_we_i,
		   input [0:0]	     wb_sel_i,
		   input	     wb_stb_i,
		   output reg	     wb_ack_o,
		   input	     wb_cyc_i);

   reg [0:7] romh[0:4095];
   reg [0:7] roml[0:4095];

   wire [0:11] readaddr;

   assign wb_dat_o = (wb_adr_i[3] == 1'b0 ? q[0:7] : q[8:15]);

   assign readaddr = (cs ? a[3:14] : wb_adr_i[4:15]);

   initial begin
      $readmemh("994a_rom_hb.hex", romh);
      $readmemh("994a_rom_lb.hex", roml);
   end

   always @(posedge clk) begin

      // Read port
      if (cs || (wb_cyc_i && wb_stb_i && !wb_we_i))
	q <= { romh[readaddr], roml[readaddr] };

      // Write port
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && wb_sel_i[0]) begin
	 if (wb_adr_i[3] == 1'b0)
	   romh[wb_adr_i[4:15]] <= wb_dat_i;
	 else
	   roml[wb_adr_i[4:15]] <= wb_dat_i;
      end

      // Wishbone handshake
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o && (wb_we_i || !cs);

   end

endmodule // console_rom
