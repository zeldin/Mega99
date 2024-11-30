module scratchpad_ram(input             clk,
		      input		enable_1k,
		      input		cs,
		      input		we,
		      input [0:14]	a,
		      input [0:15]	d,
		      output reg [0:15]	q);

   reg [0:15] ram[0:511];
   wire [0:8] ram_addr;

   assign ram_addr = ( enable_1k ? a[6:14] : { 2'b11, a[8:14] } );

   always @(posedge clk) begin
      if (cs && !we)
	q <= ram[ram_addr];
      if (cs && we)
	ram[ram_addr] <= d;
   end

endmodule // scratchpad_ram
