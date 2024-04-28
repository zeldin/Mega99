module spmmio_sdcard(input             clk,
		     input	       reset,

		     input [0:3]       adr,
		     input	       cs,
		     input [0:3]       sel,
		     input	       we,
		     input [0:31]      d,
		     output reg [0:31] q,

		     output reg	       sdcard_cs,
		     input	       sdcard_cd,
		     input	       sdcard_wp,
		     output reg	       sdcard_sck,
		     input	       sdcard_miso,
		     output	       sdcard_mosi);


   reg cd_sync0;
   reg cd_sync1;
   reg cd_sync2;
   reg wp_sync;
   reg miso_sync;
   reg inserted;
   reg removed;
   reg busy;
   reg wait_r;
   reg [0:7] sr_in;
   reg [0:7] sr_out;
   reg [0:2] bitcnt;
   reg [0:7] cyclecnt;
   reg [0:7] divider;
   
   assign sdcard_mosi = sr_out[0];
   
   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[16:23] <= divider;
	   q[28] <= inserted;
	   q[29] <= removed;
	   q[30] <= wp_sync;
	   q[31] <= cd_sync2;
	end
	4'h1: begin
	   q[19] <= sdcard_cs;
	   q[22] <= wait_r;
	   q[23] <= busy;
	   q[24:31] <= sr_in;
	end
      endcase // case (adr)
   end

   always @(posedge clk) begin
      cd_sync2 <= cd_sync1;
      cd_sync1 <= cd_sync0;
      cd_sync0 <= sdcard_cd;
      wp_sync <= sdcard_wp;
      miso_sync <= sdcard_miso;

      if (reset) begin
	 inserted <= 1'b0;
	 removed <= 1'b0;
	 busy <= 1'b0;
	 wait_r <= 1'b0;
	 sdcard_cs <= 1'b0;
	 sdcard_sck <= 1'b0;
	 sr_in <= 8'h00;
	 sr_out <= 8'h00;
	 bitcnt <= 3'd0;
	 cyclecnt <= 8'h00;
	 divider <= 8'hff;
      end else begin
	 if (cd_sync1 && !cd_sync2)
	   inserted <= 1'b1;
	 else if (cd_sync2 && !cd_sync1)
	   removed <= 1'b1;

	 if (busy) begin
	    if (cyclecnt == divider) begin
	       cyclecnt <= 8'h00;
	       if (sdcard_sck) begin
		  sr_in <= { sr_in[1:7], miso_sync };
		  sr_out <= { sr_out[1:7], 1'b0 };
		  if (bitcnt == 3'd7)
		    busy <= 1'b0;
		  else if (wait_r && bitcnt == 3'd0 && miso_sync)
		    ; // wait for the first 0
		  else
		     bitcnt <= bitcnt + 3'd1;
		  sdcard_sck <= 1'b0;
	       end else
		 sdcard_sck <= 1'b1;
	    end else
	      cyclecnt <= cyclecnt + 8'h01;
	 end
	 
	 if (cs && we && sel[2])
	   case (adr)
	     4'h0: divider <= d[16:23];
	     4'h1: begin
		sdcard_cs <= d[19];
		wait_r <= d[22];
		busy <= d[23];
		sdcard_sck <= 1'b0;
		bitcnt <= 3'd0;
		cyclecnt <= 8'h00;
	     end
	   endcase // case (adr)

	 if (cs && we && sel[3])
	   case (adr)
	     4'h0: begin
		if (d[28])
		  inserted <= 1'b0;
		if (d[29])
		  removed <= 1'b0;
	     end
	     4'h1: sr_out <= d[24:31];
	   endcase // case (adr)
      end
   end

endmodule // spmmio_sdcard
