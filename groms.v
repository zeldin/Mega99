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

   localparam NUM_GROMS = 4;

   assign wb_dat_o = 8'h00;
   assign wb_ack_o = wb_cyc_i && wb_stb_i && wb_we_i;

   reg [0:2]  grom_id;
   reg [0:12] addr;
   reg	      addr_write;
   reg [0:7]  grom_page0_byte;
   reg [0:7]  grom_page1_byte;
   reg [0:7]  grom_page2_byte;
   reg [0:2]  grom_page_active;

   assign gready = 1'b1;
   assign debug_grom_addr = { grom_id, addr };

   wire	       do_prefetch;
   wire [0:2]  prefetch_grom_id;
   wire [0:12] prefetch_addr;
   wire [0:13] prefetch_page_addr;

   assign do_prefetch = ((gs && m && !mo) || (gs && !m && mo && addr_write));
   assign prefetch_grom_id = (mo ? addr[5:7] : grom_id);
   assign prefetch_addr = (mo ? { addr[8:12], d } : addr );
   assign prefetch_page_addr = { prefetch_grom_id, prefetch_addr[2:12] };

   reg [0:7] grom_page0[0:(2048*NUM_GROMS-1)];
   reg [0:7] grom_page1[0:(2048*NUM_GROMS-1)];
   reg [0:7] grom_page2[0:(2048*NUM_GROMS-1)];

   initial begin
      addr_write <= 1'b0;
      grom_page_active <= 3'b000;
   end

   always @(posedge clk) begin

      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] &&
	  wb_adr_i[3:4] != 2'b11)
	case (wb_adr_i[3:4])
	  2'b00: grom_page0[{wb_adr_i[0:2], wb_adr_i[5:15]}] <= wb_dat_i;
	  2'b01: grom_page1[{wb_adr_i[0:2], wb_adr_i[5:15]}] <= wb_dat_i;
	  2'b10: grom_page2[{wb_adr_i[0:2], wb_adr_i[5:15]}] <= wb_dat_i;
	  default: ;
	endcase // case (wb_adr_i[3:4])

      if (do_prefetch) begin
	 grom_page0_byte <= grom_page0[prefetch_page_addr];
	 grom_page1_byte <= grom_page1[prefetch_page_addr];
	 grom_page2_byte <= grom_page2[prefetch_page_addr];
	 if (prefetch_grom_id < NUM_GROMS)
	   grom_page_active <= { prefetch_addr[0:1] == 2'b00,
				 prefetch_addr[1] == 1'b1,
				 prefetch_addr[0] == 1'b1 };
	 else
	   grom_page_active <= 3'b000;
      end

      if (gs && m) begin
	 // read data / addr
	 addr_write <= 1'b0;
	 if (mo) begin
	    q <= { grom_id, addr[0:4] };
	    { grom_id, addr[0:4] } <= addr[5:12];
	 end else begin
	    q <= (grom_page_active[0] ? grom_page0_byte : 8'h00) |
		 (grom_page_active[1] ? grom_page1_byte : 8'h00) |
		 (grom_page_active[2] ? grom_page2_byte : 8'h00);
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
