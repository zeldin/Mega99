module peb_ram32k(input            clk,
		  input		   reset,

		  input [0:15]	   a,
		  input [0:7]	   d,
		  output reg [0:7] q,
		  output	   q_select,
		  input		   memen,
		  input		   we,
		  output	   ready);

   wire [14:0] addr;

   assign q_select = (a[0:1] == 2'b11 || a[1:2] == 2'b01);
   assign ready = 1'b1;

   assign addr = { a[1], a[0]&a[2], a[3:15] };

   reg [0:7] mem [0:32767];

   always @(posedge clk)
     if (memen && q_select) begin
	if (we)
	  mem[addr] <= d;
	else
	  q <= mem[addr];
     end

endmodule // peb_ram32k
