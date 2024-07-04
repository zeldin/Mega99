module tms5200_pram(input        clk,
		    input	 clk_en,
		    input	 load_ram,
		    input [5:0]	 in,
		    input [4:1]	 pc,
		    output [5:0] cr);

   localparam [0:35] widths = { 3'd4, 3'd6, 3'd5, 3'd5, 3'd4, 3'd4,
				3'd4, 3'd4, 3'd4, 3'd3, 3'd3, 3'd3 };

   wire [5:0] rd [0:11];
   assign cr = (pc < 4'd12 ? rd[pc] : 6'd0);

   genvar i;
   generate
      for (i=0; i<12; i=i+1) begin : ENTRY
	 localparam [0:2] width = widths[i*3 +: 3];
	 reg [width-1:0]  d = 0;
	 if (width == 6)
	   assign rd[i] = d;
	 else
	   assign rd[i] = { {(6-width){1'b0}}, d };
	 always @(posedge clk)
	   if (clk_en && load_ram && pc == i)
	     d <= in[(width-1):0];
      end
   endgenerate
   
endmodule // tms5200_pram
