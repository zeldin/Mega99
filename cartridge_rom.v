module cartridge_rom(input             clk,
		     input	       cs,
		     input	       we,
		     input [3:15]      a,
		     output reg [0:7]  q,

		     // CROM access wishbone slave
		     input [0:17]      wb_adr_i,
		     input [0:7]       wb_dat_i,
		     output [0:7]      wb_dat_o,
		     input	       wb_we_i,
		     input [0:0]       wb_sel_i,
		     input	       wb_stb_i,
		     output reg	       wb_ack_o,
		     input	       wb_cyc_i);

   reg [0:7] crom[0:16383];
   reg	     banked = 1'b0;
   reg	     bank = 1'b0;

   wire [0:13] readaddr;

   assign wb_dat_o = q;
   assign readaddr = ((cs && !we) ? { bank & banked, a[3:15] } :
		      wb_adr_i[4:17]);

   always @(posedge clk) begin

      // Read port
      if ((cs && !we) || (wb_cyc_i && wb_stb_i && !wb_we_i))
	q <= crom[readaddr];

      // Write port
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && wb_sel_i[0] &&
	  !wb_adr_i[0])
	crom[wb_adr_i[4:17]] <= wb_dat_i;

      // Control port
      if (cs && we)
	bank <= a[14];
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && wb_sel_i[0] &&
	  wb_adr_i[0]) begin
	 banked <= wb_dat_i[7];
	 bank <= wb_dat_i[3];
      end

      // Wishbone handshake
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o && (wb_we_i || !cs || we);

   end

endmodule // cartridge_rom
