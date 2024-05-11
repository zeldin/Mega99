module groms(input            clk,      // Enabled cycles should give
	     input	      grclk_en, // 447.443125 kHz
	     input	      m,
	     input	      gs,
	     input	      mo,
	     input [0:7]      d,
	     output reg [0:7] q,
	     output	      gready,
	     input [0:3]      grom_set,

	     output [0:15]    debug_grom_addr,

	     // GROM access wishbone slave
	     input [0:15]     wb_adr_i,
	     input [0:7]      wb_dat_i,
	     output [0:7]     wb_dat_o,
	     input	      wb_we_i,
	     input [0:0]      wb_sel_i,
	     input	      wb_stb_i,
	     output           wb_ack_o,
	     input	      wb_cyc_i);

   assign wb_dat_o = 8'h00;
   assign wb_ack_o = wb_cyc_i && wb_stb_i && wb_we_i;

   reg [0:2]  grom_id;
   reg [0:12] addr;
   reg	      addr_write;
   reg [0:7]  grom_byte0;
   reg [0:7]  grom_byte1;
   reg [0:7]  grom_byte2;
   reg [0:7]  grom_byte3;
   reg [0:7]  grom_byte4;
   reg [0:7]  grom_byte5;
   reg [0:7]  grom_byte6;
   reg [0:7]  grom_byte7;
   reg	      grom_valid0;
   reg	      grom_valid1;
   reg	      grom_valid2;
   reg	      grom_valid3;
   reg	      grom_valid4;
   reg	      grom_valid5;
   reg	      grom_valid6;
   reg	      grom_valid7;

   assign gready = 1'b1;
   assign debug_grom_addr = { grom_id, addr };

   wire	       do_prefetch;
   wire [0:2]  prefetch_grom_id;
   wire [0:12] prefetch_addr;

   assign do_prefetch = ((gs && m && !mo) || (gs && !m && mo && addr_write));
   assign prefetch_grom_id = (mo ? addr[5:7] : grom_id);
   assign prefetch_addr = (mo ? { addr[8:12], d } : addr );

   reg [0:7] grom0[0:6143];
   reg [0:7] grom1[0:6143];
   reg [0:7] grom2[0:6143];
   reg [0:7] grom3[0:6143];
/*
   reg [0:7] grom4[0:6143];
   reg [0:7] grom5[0:6143];
   reg [0:7] grom6[0:6143];
   reg [0:7] grom7[0:6143];
*/
 
   initial begin
      addr_write <= 1'b0;
      grom_byte4 <= 8'hff;
      grom_byte5 <= 8'hff;
      grom_byte6 <= 8'hff;
      grom_byte7 <= 8'hff;
      grom_valid0 <= 1'b0;
      grom_valid1 <= 1'b0;
      grom_valid2 <= 1'b0;
      grom_valid3 <= 1'b0;
      grom_valid4 <= 1'b0;
      grom_valid5 <= 1'b0;
      grom_valid6 <= 1'b0;
      grom_valid7 <= 1'b0;
      $readmemh("994a_grom0.hex", grom0);
      $readmemh("994a_grom1.hex", grom1);
      $readmemh("994a_grom2.hex", grom2);
      $readmemh("phm3032g.hex", grom3);
/*
      $readmemh("phm3042g0.hex", grom3);
      $readmemh("phm3042g1.hex", grom4);
      $readmemh("phm3042g2.hex", grom5);
      $readmemh("phm3042g3.hex", grom6);
      $readmemh("phm3042g4.hex", grom7);
*/
    end

   always @(posedge clk) begin

      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] &&
	  wb_adr_i[3:4] != 2'b11)
	case (wb_adr_i[0:2])
	  3'b000: grom0[wb_adr_i[3:15]] <= wb_dat_i;
	  3'b001: grom1[wb_adr_i[3:15]] <= wb_dat_i;
	  3'b010: grom2[wb_adr_i[3:15]] <= wb_dat_i;
	  3'b011: grom3[wb_adr_i[3:15]] <= wb_dat_i;
	  default: ;
	endcase // case (wb_adr_i[0:2])

      if (do_prefetch) begin
	 grom_valid0 <= 1'b0;
	 grom_valid1 <= 1'b0;
	 grom_valid2 <= 1'b0;
	 grom_valid3 <= 1'b0;
	 grom_valid4 <= 1'b0;
	 grom_valid5 <= 1'b0;
	 grom_valid6 <= 1'b0;
	 grom_valid7 <= 1'b0;
	 case (prefetch_grom_id)
	   3'b000: begin
	      grom_byte0 <= grom0[prefetch_addr];
	      grom_valid0 <= 1'b1;
	   end
	   3'b001: begin
	      grom_byte1 <= grom1[prefetch_addr];
	      grom_valid1 <= 1'b1;
	   end
	   3'b010: begin
	      grom_byte2 <= grom2[prefetch_addr];
	      grom_valid2 <= 1'b1;
	   end
	   3'b011: begin
	      grom_byte3 <= grom3[prefetch_addr];
	      grom_valid3 <= 1'b1;
	   end
/*
	   3'b100: begin
	      grom_byte4 <= grom4[prefetch_addr];
	      grom_valid4 <= 1'b1;
	   end
	   3'b101: begin
	      grom_byte5 <= grom5[prefetch_addr];
	      grom_valid5 <= 1'b1;
	   end
	   3'b110: begin
	      grom_byte6 <= grom6[prefetch_addr];
	      grom_valid6 <= 1'b1;
	   end
	   3'b111: begin
	      grom_byte7 <= grom7[prefetch_addr];
	      grom_valid7 <= 1'b1;
	   end
*/
	 endcase // case (prefetch_grom_id)
      end

      if (gs && m) begin
	 // read data / addr
	 addr_write <= 1'b0;
	 if (mo) begin
	    q <= { grom_id, addr[0:4] };
	    { grom_id, addr[0:4] } <= addr[5:12];
	 end else begin
	    q <= (grom_valid0 ? grom_byte0 : 8'hff) &
		 (grom_valid1 ? grom_byte1 : 8'hff) &
		 (grom_valid2 ? grom_byte2 : 8'hff) &
		 (grom_valid3 ? grom_byte3 : 8'hff) &
		 (grom_valid4 ? grom_byte4 : 8'hff) &
		 (grom_valid5 ? grom_byte5 : 8'hff) &
		 (grom_valid6 ? grom_byte6 : 8'hff) &
		 (grom_valid7 ? grom_byte7 : 8'hff);
	    addr <= addr + 13'h1;
	 end
      end // if (gs && m)
      if (gs && !m) begin
	 // write data / addr
	 if (mo) begin
	    grom_id <= addr[5:7];
	    if (addr_write)
	      addr <= { addr[8:12], d } + 13'h1;
	    else
	      addr <= { addr[8:12], d };
	    addr_write <= ~addr_write;
	 end
      end // if (gs && !m)
   end // always @ (posedge clk)

endmodule // groms
