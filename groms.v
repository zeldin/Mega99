module groms(input            clk,      // Enabled cycles should give
	     input	      grclk_en, // 447.443125 kHz
	     input	      m,
	     input	      gs,
	     input	      mo,
	     input [0:7]      d,
	     output reg [0:7] q,
	     output	      gready,
	     input [0:3]      grom_set,

	     output [0:15]    debug_grom_addr);

   reg [0:2]  grom_id;
   reg [0:12] addr;
   reg	      addr_write;
   reg [0:7]  grom_byte;

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
      grom_byte <= 8'h00;
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

      if (do_prefetch)
	case (prefetch_grom_id)
	  3'b000: grom_byte <= grom0[prefetch_addr];
	  3'b001: grom_byte <= grom1[prefetch_addr];
	  3'b010: grom_byte <= grom2[prefetch_addr];
	  3'b011: grom_byte <= grom3[prefetch_addr];
/*
	  3'b100: grom_byte <= grom4[prefetch_addr];
	  3'b101: grom_byte <= grom5[prefetch_addr];
	  3'b110: grom_byte <= grom6[prefetch_addr];
	  3'b111: grom_byte <= grom7[prefetch_addr];
*/
 	  default: grom_byte <= 8'h00;
	endcase // case (prefetch_grom_id)

      if (gs && m) begin
	 // read data / addr
	 addr_write <= 1'b0;
	 if (mo) begin
	    q <= { grom_id, addr[0:4] };
	    { grom_id, addr[0:4] } <= addr[5:12];
	 end else begin
	    q <= grom_byte;
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
