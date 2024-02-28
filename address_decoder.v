module address_decoder(input        memen,
		       input	    we,
		       input	    dbin,
		       input [0:14] a,
		       input	    a15,
		       output reg   romen,
		       output reg   mbe,
		       output reg   romg,
		       output reg   mb,
		       output reg   sound_sel,
		       output reg   vdp_csr,
		       output reg   vdp_csw,
		       output reg   sbe,
		       output reg   gs,
		       output	    ramblk,
		       output reg   memex);

   assign ramblk = (a[3:5] == 3'b000); // U507
   
   // U504
   always @(*) begin
      romen = 1'b0;
      mbe = 1'b0;
      romg = 1'b0;
      mb = 1'b0;
      memex = 1'b0;
      if (memen) // G2A
	case (a[0:2])
	  3'b000: romen = 1'b1; // >0000 - >1FFF
	  3'b001: memex = 1'b1; // >2000 - >3FFF (not decoded by U504)	  
	  3'b010: mbe = 1'b1;   // >4000 - >5FFF
	  3'b011: romg = 1'b1;  // >6000 - >7FFF
	  3'b100: mb = 1'b1;    // >8000 - >9FFF
	  3'b101: memex = 1'b1; // >A000 - >BFFF (not decoded by U504)	  
	  3'b110: memex = 1'b1; // >C000 - >DFFF (not decoded by U504)	  
	  3'b111: memex = 1'b1; // >E000 - >FFFF (not decoded by U504)	  
	endcase // case (a[0:2])
   end // always @ (*)

   // U505
   always @(*) begin
      sound_sel = 1'b0;
      vdp_csr = 1'b0;
      vdp_csw = 1'b0;
      sbe = 1'b0;
      gs = 1'b0;
      if (a[5] == 1'b0 || !dbin) // G1
	if (mb) // G2A
	  if (a15 == 1'b0) // G2B
	    case (a[3:5])
	      3'b000: ;                  // >8000 - >83FF
	      3'b001: sound_sel <= 1'b1; // >8400 - >87FF
	      3'b010: vdp_csr <= 1'b1;   // >8800 - >8BFF
	      3'b011: vdp_csw <= we;     // >8C00 - >8FFF
	      3'b100: sbe = 1'b1;        // >9000 - >93FF
	      3'b101: sbe = 1'b1;        // >9400 - >97FF
	      3'b110: gs = 1'b1;         // >9800 - >9BFF
	      3'b111: gs = 1'b1;         // >9C00 - >9FFF
	    endcase // case (a[3:5])
   end

endmodule // address_decoder
