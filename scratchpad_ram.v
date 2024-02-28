module scratchpad_ram(input             clk,
		      input		cs,
		      input		we,
		      input [0:14]	a,
		      input [0:15]	d,
		      output reg [0:15]	q);

   reg [0:15] ram[0:127];

   always @(posedge clk) begin
      if (cs && !we)
	q <= ram[a[8:14]];
      if (cs && we)
	ram[a[8:14]] <= d;
   end

endmodule // scratchpad_ram
