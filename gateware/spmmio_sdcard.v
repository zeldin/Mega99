module spmmio_sdcard(input             clk,
		     input	       reset,

		     input [0:3]       adr,
		     input	       cs,
		     input [0:3]       sel,
		     input	       we,
		     input [0:31]      d,
		     output reg [0:31] q,

		     output reg        sdcard_select,
		     output reg	       sdcard_cs,
		     input [0:1]       sdcard_cd,
		     input [0:1]       sdcard_wp,
		     output reg	       sdcard_sck,
		     input	       sdcard_miso,
		     output	       sdcard_mosi);

   parameter num_sdcard = 1;

   wire crc7_x;
   wire crc16_x;

   reg [0:1] cd_sync0;
   reg [0:1] cd_sync1;
   reg [0:1] cd_sync2;
   reg [0:1] wp_sync;
   reg miso_sync;
   reg [0:1] inserted;
   reg [0:1] removed;
   reg busy;
   reg wait_r;
   reg [0:7] sr_in;
   reg [0:7] sr_out;
   reg [0:2] bitcnt;
   reg [0:7] cyclecnt;
   reg [0:7] divider;
   reg [0:6] crc7;
   reg [0:15] crc16;
   reg	      crc16_is_mosi;
   
   assign sdcard_mosi = sr_out[0];
   assign crc7_x = crc7[0] ^ sdcard_mosi;
   assign crc16_x = crc16[0] ^ (crc16_is_mosi ? sdcard_mosi : miso_sync);

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[0:7] <= divider;
	   q[8] <= inserted[0];
	   q[9] <= removed[0];
	   q[10] <= wp_sync[0];
	   q[11] <= cd_sync2[0];
	   q[12] <= inserted[1];
	   q[13] <= removed[1];
	   q[14] <= wp_sync[1];
	   q[15] <= cd_sync2[1];
	   q[19] <= sdcard_cs;
	   q[22] <= wait_r;
	   q[23] <= busy;
	   q[24:31] <= sr_in;
	end
	4'h1: begin
	   q[0:7] <= { crc7, 1'b1 };
	   q[8:11] <= num_sdcard;
	   q[15] <= sdcard_select;
	   q[16:31] <= crc16;
	end
	default: ;
      endcase // case (adr)
   end

   always @(posedge clk) begin
      cd_sync2 <= cd_sync1;
      cd_sync1 <= cd_sync0;
      cd_sync0 <= sdcard_cd;
      wp_sync <= sdcard_wp;
      miso_sync <= sdcard_miso;

      if (reset) begin
	 inserted <= 2'b00;
	 removed <= 2'b00;
	 busy <= 1'b0;
	 wait_r <= 1'b0;
	 sdcard_select <= 1'b0;
	 sdcard_cs <= 1'b0;
	 sdcard_sck <= 1'b0;
	 sr_in <= 8'h00;
	 sr_out <= 8'h00;
	 bitcnt <= 3'd0;
	 cyclecnt <= 8'h00;
	 divider <= 8'hff;
	 crc7 <= 7'd0;
	 crc16 <= 16'h0000;
	 crc16_is_mosi <= 1'b0;
      end else begin
	 if (cd_sync1[0] && !cd_sync2[0])
	   inserted[0] <= 1'b1;
	 else if (cd_sync2[0] && !cd_sync1[0])
	   removed[0] <= 1'b1;
	 if (cd_sync1[1] && !cd_sync2[1])
	   inserted[1] <= 1'b1;
	 else if (cd_sync2[1] && !cd_sync1[1])
	   removed[1] <= 1'b1;

	 if (busy) begin
	    if (cyclecnt == divider) begin
	       cyclecnt <= 8'h00;
	       if (sdcard_sck) begin
		  crc7 <= { crc7[1:6], 1'b0 } ^
			  { 3'b000, crc7_x, 2'b00, crc7_x };
		  crc16 <= { crc16[1:15], 1'b0 } ^
			   { 3'b000, crc16_x, 6'b000000,
			     crc16_x, 4'b0000, crc16_x };
		  sr_in <= { sr_in[1:7], miso_sync };
		  sr_out <= { sr_out[1:7], 1'b1 };
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

	 if (cs && we && sel[0])
	   case (adr)
	     4'h0: divider <= d[0:7];
	   endcase // case (adr)

	 if (cs && we && sel[1])
	   case (adr)
	     4'h0: begin
		if (d[8])
		  inserted[0] <= 1'b0;
		if (d[9])
		  removed[0] <= 1'b0;
		if (d[12])
		  inserted[1] <= 1'b0;
		if (d[13])
		  removed[1] <= 1'b0;
	     end
	     4'h1: if (num_sdcard > 1) sdcard_select <= d[15];
	   endcase // case (adr)
	 
	 if (cs && we && sel[2])
	   case (adr)
	     4'h0: begin
		if (!sdcard_cs)
		  crc7 <= 7'd0;
		sdcard_cs <= d[19];
		wait_r <= d[22];
		busy <= d[23];
		sdcard_sck <= 1'b0;
		bitcnt <= 3'd0;
		cyclecnt <= 8'h00;
	     end
	     4'h1: crc16[0:7] <= 8'h00;
	   endcase // case (adr)

	 if (cs && we && sel[3])
	   case (adr)
	     4'h0: sr_out <= d[24:31];
	     4'h1: begin
		crc16[8:15] <= 8'h00;
		crc16_is_mosi <= d[31];
	     end
	   endcase // case (adr)
      end
   end

endmodule // spmmio_sdcard
