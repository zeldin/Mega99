module cartridge_rom(input             clk,
		     input	       cs,
		     input	       we,
		     input [3:15]      a,
		     input [0:7]       d,
		     output reg [0:7]  q,

		     // CROM access wishbone slave
		     input [0:20]      wb_adr_i,
		     input [0:7]       wb_dat_i,
		     output [0:7]      wb_dat_o,
		     input	       wb_we_i,
		     input [0:0]       wb_sel_i,
		     input	       wb_stb_i,
		     output reg	       wb_ack_o,
		     input	       wb_cyc_i);

   reg [0:7] crom[0:17408];
   reg	     mm = 1'b0;
   reg	     mbx = 1'b0;
   reg	     banked = 1'b0;
   reg [0:1] bank = 2'b00;

   wire	     cpu_array_read;
   wire	     cpu_array_write;
   wire	     wb_control;
   wire	     wb_array_read;
   wire	     wb_array_write;

   wire [0:14] readaddr;
   wire [0:14] writeaddr;

   assign cpu_array_read = cs && !we;
   assign cpu_array_write = cs && we && ((mm && a[3]) || (mbx && a[3:5] == 3'b011));
   assign wb_control = !wb_adr_i[0];
   assign wb_array_read = wb_cyc_i && wb_stb_i && !wb_we_i && !wb_control;
   assign wb_array_write = wb_cyc_i && wb_stb_i && wb_we_i && !wb_control && wb_sel_i[0];

   assign wb_dat_o = (wb_control ? { 2'b00, bank, 1'b0, mbx, mm, banked } : q);
   assign readaddr = (cpu_array_read ? ( mbx ? { (a[3]? { 1'b0, bank[0:1] } :
						  { &(a[4:5]), 2'b00 } ),
						 (a[3:5] == 3'b011 ? 2'b00 :
						  a[4:5]), a[6:15] } :
					 { 1'b0, bank[1], a[3:15] } ) :
		      wb_adr_i[20 -: 15]);
   assign writeaddr = (cpu_array_write ? ( mbx ? { 5'b10000, a[6:15] } :
					   { 3'b001, a[4:15] } ) :
		       wb_adr_i[20 -: 15]);

   always @(posedge clk) begin

      // Read port
      if (cpu_array_read || wb_array_read)
	q <= crom[readaddr];

      // Write port
      if (cpu_array_write || wb_array_write)
	crom[writeaddr] <= (cpu_array_write ? d : wb_dat_i);

      // Control port
      if (cs && we && banked)
	bank[1] <= a[14];
      if (cs && we && mbx && a[3:14] == 12'b0_1111_1111_111)
	bank[0:1] <= d[6:7];
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_control && wb_sel_i[0]) begin
	 banked <= wb_dat_i[7];
	 mm <= wb_dat_i[6];
	 mbx <= wb_dat_i[5];
	 bank <= wb_dat_i[2:3];
	 if (wb_dat_i[5])
	   ;
	 else if(wb_dat_i[7])
	   bank[0] <= 1'b0;
	 else
	   bank <= 2'b00;
      end

      // Wishbone handshake
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o;
      if (cpu_array_read && wb_array_read)
	wb_ack_o <= 1'b0;
      if (cpu_array_write && wb_array_write)
	wb_ack_o <= 1'b0;

   end

endmodule // cartridge_rom
