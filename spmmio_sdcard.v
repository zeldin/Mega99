module spmmio_sdcard(input             clk,
		     input	       reset,

		     input [0:3]       adr,
		     input	       cs,
		     input [0:3]       sel,
		     input	       we,
		     input [0:31]      d,
		     output reg [0:31] q,

		     output	       sdcard_cs,
		     input	       sdcard_cd,
		     input	       sdcard_wp,
		     output	       sdcard_sck,
		     input	       sdcard_miso,
		     output	       sdcard_mosi);

   assign sdcard_cs = 1'b0;
   assign sdcard_sck = 1'b0;
   assign sdcard_mosi = 1'b0;

   reg cd_sync0;
   reg cd_sync1;
   reg cd_sync2;
   reg wp_sync;
   reg miso_sync;
   reg inserted;
   reg removed;

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[28] <= inserted;
	   q[29] <= removed;
	   q[30] <= wp_sync;
	   q[31] <= cd_sync2;
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
      end else begin
	 if (cd_sync1 && !cd_sync2)
	   inserted <= 1'b1;
	 else if (cd_sync2 && !cd_sync1)
	   removed <= 1'b1;

	 if (cs && we && sel[3])
	   case (adr)
	     4'h0: begin
		if (d[28])
		  inserted <= 1'b0;
		if (d[29])
		  removed <= 1'b0;
	     end
	   endcase // case (adr)
      end
   end

endmodule // spmmio_sdcard
