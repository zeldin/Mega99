module spmmio_misc(input             clk,
		   input	     reset,

		   input [0:3]	     adr,
		   input	     cs,
		   input [0:3]	     sel,
		   input	     we,
		   input [0:31]	     d,
		   output reg [0:31] q,

		   output reg	     led_red,
		   output reg	     led_green);


   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[30] <= led_red;
	   q[31] <= led_green;
	end
      endcase // case (adr)
   end

   always @(posedge clk)
     if (reset) begin
	led_red <= 1'b0;
	led_green <= 1'b0;
     end else if (cs && we && sel[3])
       case (adr)
	 4'h0: begin
	    led_red <= d[30];
	    led_green <= d[31];
	 end
       endcase // case (adr)

endmodule // spmmio_misc
