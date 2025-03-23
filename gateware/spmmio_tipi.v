module spmmio_tipi(input             clk,
		   input	     reset,
		   input	     clk_3mhz_en,
		   input [0:3]	     adr,
		   input	     cs,
		   input [0:3]	     sel,
		   input	     we,
		   input [0:31]	     d,
		   output reg [0:31] q,

		   input	     enable,
		   output reg	     tclk,
		   output reg	     rt,
		   output reg	     le,
		   input	     treset,
		   output reg	     dout,
		   input	     din,
		   output reg	     dc);

   reg	     parity;
   reg [0:8] shift_in;
   reg [0:7] shift_out;
   reg	     reset_level;
   reg	     reset_changed;

   reg [0:7] tc;
   reg [0:7] td;
   reg [0:7] rc;
   reg [0:7] rd;

   reg [0:7] tc_hold;
   reg	     rc_update;

   always @(posedge clk) begin
      if (reset || !enable) begin
	 tclk <= 1'b0;
	 rt <= 1'b1;
	 le <= 1'b1;
	 dout <= 1'b0;
	 dc <= 1'b1;
	 parity <= 1'b0;
	 reset_level <= 1'b0;
	 reset_changed <= 1'b0;
      end
      if (reset) begin
	 tc <= 8'h00;
	 td <= 8'h00;
	 rc <= 8'h00;
	 rd <= 8'h00;
	 tc_hold <= 8'h00;
	 rc_update <= 1'b0;
      end else begin
	 if (enable && treset != reset_level) begin
	    reset_level <= treset;
	    reset_changed <= 1'b1;
	 end
	 if (enable && clk_3mhz_en) begin
	    if (tclk) begin
	       le <= 1'b0;
	       if (rt) begin
		  parity <= parity ^ din;
		  if (le) begin
		     parity <= 1'b0;
		     shift_in <= 9'h1;
		  end else if (!shift_in[0])
		    shift_in <= { shift_in[1:8], din };
		  else if (din == parity) begin
		     if (dc) begin
			tc <= tc_hold;
			td <= shift_in[1:8];
		     end else
		       tc_hold <= shift_in[1:8];
		     dc <= ~dc;
		     if (!dc) begin
			rt <= 1'b0;
			parity <= 1'b0;
			dout <= rd[0];
			shift_out <= { rd[1:7], 1'b1 };
			// If RC is not updated after this point, we can
			// send it without fear of RD being wrong
			rc_update <= 1'b0;
		     end else
		       le <= 1'b1;
		  end else
		    // Retry
		    le <= 1'b1;
	       end else if (le) begin
		  dc <= ~dc;
		  if (rc_update || !dc) begin
		     // If RC has changed after RD was sent last, postpone
		     // sending it until RD has been sent again
		     dc <= 1'b1;
		     rt <= 1'b1;
		     le <= 1'b1;
		  end else begin
		     parity <= 1'b0;
		     dout <= rc[0];
		     shift_out <= { rc[1:7], 1'b1 };
		  end
	       end else begin
		  parity <= parity ^ dout;
		  if (shift_out == 8'h80) begin
		     if (din == parity ^ dout)
			le <= 1'b1;
		     else if (!dc && rc_update) begin
			// RC has been updated, skip retry until
			// after RD has been sent
			dc <= 1'b1;
			rt <= 1'b1;
			le <= 1'b1;
		     end else begin
			// Retry
			parity <= 1'b0;
			if (dc) begin
			   dout <= rd[0];
			   shift_out <= { rd[1:7], 1'b1 };
			end else begin
			   dout <= rc[0];
			   shift_out <= { rc[1:7], 1'b1 };
			end
		     end
		  end else begin
		     dout <= shift_out[0];
		     shift_out <= { shift_out[1:7], 1'b0 };
		  end
	       end
	    end // if (tclk)
	    tclk <= ~tclk;
	 end // if (enable && clk_3mhz_en)

	 if (cs && we) begin
	    if (sel[0])
	      case (adr)
		4'h0: begin
		   if ((d[2] == reset_level && d[2] == treset) || !enable)
		     reset_changed <= 1'b0;
		end
	      endcase // case (adr)
	    if (sel[2])
	      case (adr)
		4'h1: begin
		   if (d[16:23] != rc)
		     rc_update <= 1'b1;
		   rc <= d[16:23];
		end
	      endcase // case (adr)
	    if (sel[3])
	      case (adr)
		4'h1: rd <= d[24:31];
	      endcase // case (adr)
	 end
      end // else: !if(reset)
   end // always @ (posedge clk)

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[0] <= enable;
	   q[1] <= reset_changed;
	   q[2] <= reset_level;
	   q[16:23] <= tc;
	   q[24:31] <= td;
	end
	4'h1: begin
	   q[16:23] <= rc;
	   q[24:31] <= rd;
	end
      endcase // case (adr)
   end // always @ (*)

endmodule // spmmio_tipi
