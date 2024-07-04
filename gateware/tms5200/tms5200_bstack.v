module tms5200_bstack(input	    clk,
		      input	    clk_en,
		      input	    shift_en,
		      input [13:0]  bin,
		      output [13:0] bout);

   genvar i;
   generate
      for (i=0; i<14; i=i+1) begin : BITSTACK
	 reg [0:8] stack;
	 assign bout[i] = stack[8];
	 always @(posedge clk)
	   if (clk_en && shift_en)
	     stack <= { bin[i], stack[0:7] };
      end
   endgenerate

endmodule // tms5200_bstack
