module cartridge_rom(input             clk,
		     input	       cs,
		     input	       we,
		     input [3:15]      a,
		     input [0:7]       d,
		     output reg [0:7]  q,

		     // CROM access wishbone slave
		     input [0:21]      wb_adr_i,
		     input [0:7]       wb_dat_i,
		     output [0:7]      wb_dat_o,
		     input	       wb_we_i,
		     input [0:0]       wb_sel_i,
		     input	       wb_stb_i,
		     output reg	       wb_ack_o,
		     input	       wb_cyc_i);

   parameter BANKS = 64;

   reg [0:7] crom[0:8192*BANKS-1];
   reg	     mm = 1'b0;
   reg	     mbx = 1'b0;
   reg	     invbank = 1'b0;
   reg [0:7] bank = 8'h00;
   reg [0:7] bank_mask = 8'h00;
   reg [0:3] bank_mask_width = 4'd0;

   wire	     cpu_array_read;
   wire	     cpu_array_write;
   wire	     wb_control;
   wire	     wb_array_read;
   wire	     wb_array_write;

   wire [0:20] readaddr;
   wire [0:20] writeaddr;
   reg [0:7]   regq;

   generate
      if (BANKS < 3 || BANKS > 256)
	initial $fatal("BANKS must be between 3 and 256");
   endgenerate

   assign cpu_array_read = cs && !we;
   assign cpu_array_write = cs && we && ((mm && a[3]) || (mbx && a[3:5] == 3'b011));
   assign wb_control = !wb_adr_i[0];
   assign wb_array_read = wb_cyc_i && wb_stb_i && !wb_we_i && !wb_control;
   assign wb_array_write = wb_cyc_i && wb_stb_i && wb_we_i && !wb_control && wb_sel_i[0];

   assign wb_dat_o = (wb_control ? regq : q);
   assign readaddr = (cpu_array_read ? ( !mbx ? { bank, a[3:15] } :
					 { 6'h00,
					   ( a[3]? { 1'b0, bank[6:7] } :
					     { &(a[4:5]), 2'b00 } ),
					   a[4:15] } ) :
		      wb_adr_i[1:21] );
   assign writeaddr = (cpu_array_write ? ( mbx ? { 8'h02, 3'b011, a[6:15] } :
					   { 8'h00, 1'b1, a[4:15] } ) :
		       wb_adr_i[1:21] );

   always @(*)
     case (wb_adr_i[20:21])
       2'b00: regq = { bank_mask_width, invbank, mbx, mm, 1'b0 };
       2'b01: regq = bank;
       2'b10: regq = BANKS - 1;
       default: regq = 8'h00;
     endcase // case (wb_adr_i[20:21])

   always @(posedge clk) begin

      // Read port
      if (cpu_array_read || wb_array_read)
	q <= crom[readaddr];

      // Write port
      if (cpu_array_write || wb_array_write)
	crom[writeaddr] <= (cpu_array_write ? d : wb_dat_i);

      // Control port
      if (cs && we) begin
	 if (!mbx)
	   bank <= (a[7:14] ^ {8{invbank}}) & bank_mask;
	 else if (a[3:14] == 12'b0_1111_1111_111)
	   bank <= d & bank_mask;
      end
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_control && wb_sel_i[0])
	case (wb_adr_i[20:21])
	  2'b00: begin
	     mm <= wb_dat_i[6];
	     mbx <= wb_dat_i[5];
	     invbank <= wb_dat_i[4];
	     bank_mask_width <= wb_dat_i[0:3];
	     case (wb_dat_i[0:3])
	       4'd1: bank_mask <= 8'h01;
	       4'd2: bank_mask <= 8'h03;
	       4'd3: bank_mask <= 8'h07;
	       4'd4: bank_mask <= 8'h0f;
	       4'd5: bank_mask <= 8'h1f;
	       4'd6: bank_mask <= 8'h3f;
	       4'd7: bank_mask <= 8'h7f;
	       4'd8: bank_mask <= 8'hff;
	       default: bank_mask <= 8'h00;
	     endcase // case (wb_dat_i[0:3])
	     bank <= 8'h00;
	  end // case: 2'b00
	  2'b01:
	    bank <= wb_dat_i & bank_mask;
	endcase // case (wb_adr_i[20:21])

      // Wishbone handshake
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o;
      if (cpu_array_read && wb_array_read)
	wb_ack_o <= 1'b0;
      if (cpu_array_write && wb_array_write)
	wb_ack_o <= 1'b0;

   end

endmodule // cartridge_rom
