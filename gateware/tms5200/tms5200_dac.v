module tms5200_dac(input                     clk,
		   input		     clk_en,
		   input		     t11,
		   input		     io,
		   output [0:(audio_bits-1)] audioout);

   /* Note: audioout is signed, unlike the internal D/A input in the 5200 */
   
   parameter audio_bits = 8;

   reg [13:4]  yl;
   reg	       shifting;
   reg [7:0]   clamped;
   wire [0:35] expanded;

   assign expanded = { clamped, {4{ clamped[6:0] }} };
   assign audioout = expanded[0:(audio_bits-1)];
   
   always @(posedge clk)
     if (clk_en)
       if (t11) begin
	  shifting <= 1'b1;
	  yl <= 10'h3ff;
       end else if (shifting) begin
	  shifting <= yl[4];
	  yl <= { io, yl[13:5] };
       end else begin
	  if (yl[13:11] == 3'b000 || yl[13:11] == 3'b111)
	    clamped <= { yl[13], yl[10:4] };
	  else
	    clamped <= { yl[13], {7{ ~yl[13] }} };
       end

endmodule // tms5200_dac
