module multiplexer(input         clk,
		   input	 clk_en,
		   input	 start,
		   input	 memen,
		   input	 sysrdy,
		   output	 memen8,
		   output	 ready,
		   output	 a15,
		   output [0:15] d,
		   input [0:15]	 q,
		   input [0:7]	 d8,
		   output [0:7]	 q8);

   reg [0:2] shift_reg;
   reg [0:7] odd_latch;
   reg	     odd_live;
   reg	     odd_complete;

   assign a15 = ~shift_reg[2];
   assign memen8 = memen & !(a15 && odd_complete);
   assign ready = sysrdy && !(start && a15);
   assign q8 = (a15 ? q[8:15] : q[0:7]);
   assign d = { d8, odd_latch };

   always @(posedge clk) begin
      if (odd_live)
	odd_latch <= d8;
      if (!start) begin
	 odd_complete <= 1'b0;
	 odd_live <= 1'b0;
      end else if (sysrdy && !odd_complete) begin
	 odd_complete <= 1'b1;
	 odd_live <= 1'b1;
      end else
	odd_live <= 1'b0;
   end // always @ (posedge clk)

   // U613
   always @(posedge clk)
     if (!start)
       shift_reg <= 3'b000;
     else if (clk_en && (sysrdy || (odd_complete && a15)))
       shift_reg <= { ~shift_reg[2], shift_reg[0:1] };

endmodule // multiplexer
