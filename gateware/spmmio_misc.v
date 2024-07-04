module spmmio_misc(input             clk,
		   input	     reset,

		   input [0:3]	     adr,
		   input	     cs,
		   input [0:3]	     sel,
		   input	     we,
		   input [0:31]	     d,
		   output reg [0:31] q,

		   output reg	     led_red,
		   output reg	     led_green,
		   output reg [0:4]  sw_reset);


   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[30] <= led_red;
	   q[31] <= led_green;
	end
	4'h1: q[24:31] <= { sw_reset, 3'b111 };
	default: ;
      endcase // case (adr)
   end

   always @(posedge clk)
     if (reset) begin
	led_red <= 1'b0;
	led_green <= 1'b0;
	sw_reset <= 5'b11111;
     end else if (cs && we && sel[3])
       case (adr)
	 4'h0: begin
	    led_red <= d[30];
	    led_green <= d[31];
	 end
	 4'h1: sw_reset <= d[24:28];
       endcase // case (adr)

endmodule // spmmio_misc
