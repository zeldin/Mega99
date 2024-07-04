module cartridge_rom(input             clk,
		     input	       cs,
		     input	       we,
		     input [3:15]      a,
		     input [0:7]       d,
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
   reg	     mm = 1'b0;
   reg	     banked = 1'b0;
   reg	     bank = 1'b0;

   wire	     cpu_array_read;
   wire	     cpu_array_write;
   wire	     wb_control;
   wire	     wb_array_read;
   wire	     wb_array_write;

   wire [0:13] readaddr;
   wire [0:13] writeaddr;

   assign cpu_array_read = cs && !we;
   assign cpu_array_write = cs && we && mm && a[3];
   assign wb_control = wb_adr_i[0];
   assign wb_array_read = wb_cyc_i && wb_stb_i && !wb_we_i && !wb_control;
   assign wb_array_write = wb_cyc_i && wb_stb_i && wb_we_i && !wb_control && wb_sel_i[0];

   assign wb_dat_o = (wb_control ? { 3'b000, bank, 2'b00, mm, banked } : q);
   assign readaddr = (cpu_array_read ? { bank, a[3:15] } :
		      wb_adr_i[4:17]);
   assign writeaddr = (cpu_array_write ? { 2'b01, a[4:15] } :
		       wb_adr_i[4:17]);

   always @(posedge clk) begin

      // Read port
      if (cpu_array_read || wb_array_read)
	q <= crom[readaddr];

      // Write port
      if (cpu_array_write || wb_array_write)
	crom[writeaddr] <= (cpu_array_write ? d : wb_dat_i);

      // Control port
      if (cs && we && banked)
	bank <= a[14];
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_control && wb_sel_i[0]) begin
	 banked <= wb_dat_i[7];
	 mm <= wb_dat_i[6];
	 bank <= wb_dat_i[3];
	 if (!wb_dat_i[7])
	   bank <= 1'b0;
      end

      // Wishbone handshake
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o;
      if (cpu_array_read && wb_array_read)
	wb_ack_o <= 1'b0;
      if (cpu_array_write && wb_array_write)
	wb_ack_o <= 1'b0;

   end

endmodule // cartridge_rom
