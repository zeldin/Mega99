module groms(input	      clk,	// Enabled cycles should give
	     input	      grclk_en,	// 447.443125 kHz
	     input	      m,
	     input	      gs,
	     input	      mo,
	     input [0:7]      d,
	     output reg [0:7] q,
	     output	      gready,
	     input [0:3]      grom_set,

	     output reg [0:3] prefetch_grom_set,
	     output [0:15]    prefetch_grom_addr,
	     output reg	      do_prefetch,
	     input	      prefetch_complete,
	     input [0:7]      prefetch_data);

   reg [0:2]  grom_id;
   reg [0:12] addr;
   reg	      addr_write;
   reg [0:7]  grom_out_byte;
   reg	      grom_byte_update;

   assign gready = ~grom_byte_update;
   assign prefetch_grom_addr = { grom_id, addr };

   initial begin
      addr_write <= 1'b0;
      do_prefetch <= 1'b0;
      grom_byte_update <= 1'b0;
      grom_out_byte <= 8'h00;
   end

   always @(posedge clk) begin

      if (do_prefetch) begin
	 if (prefetch_complete) begin
	    addr <= addr + 13'h1;
	    do_prefetch <= 1'b0;
	 end
      end else if (grom_byte_update) begin
	 grom_out_byte <= prefetch_data;
	 grom_byte_update <= 1'b0;
      end else begin
	 if (gs && m) begin
	    // read data / addr
	    addr_write <= 1'b0;
	    if (mo) begin
	       q <= { grom_id, addr[0:4] };
	       { grom_id, addr[0:4] } <= addr[5:12];
	    end else begin
	       q <= grom_out_byte;
	       grom_byte_update <= 1'b1;
	       prefetch_grom_set <= grom_set;
	       do_prefetch <= 1'b1;
	    end
	 end // if (gs && m)
	 else if (gs && !m) begin
	    // write data / addr
	    if (mo) begin
	       grom_id <= addr[5:7];
	       addr <= { addr[8:12], d };
	       if (addr_write) begin
		  grom_byte_update <= 1'b1;
		  prefetch_grom_set <= grom_set;
		  do_prefetch <= 1'b1;
	       end
	       addr_write <= ~addr_write;
	    end
	 end // if (gs && !m)
      end // else: !if(grom_byte_update)
   end // always @ (posedge clk)

endmodule // groms
