module tms9918_scandoubler(input        clk,
			   input	clk_en_in,
			   input	clk_en_out,

			   input	sync_h_in,
			   input	cburst_in,
			   input [0:3]	color_in,

			   output	sync_h_out,
			   output	cburst_out,
			   output [0:3]	color_out);

   reg [0:5] buffer [0:1023];
   reg [0:8] in_pos;
   reg [0:8] out_pos;
   reg [0:8] line_width;
   reg	     flip;
   
   wire [0:5] stashed_pixel;
   reg  [0:5] recalled_pixel;
   reg	      last_sync_h;

   assign stashed_pixel = { color_in, sync_h_in, cburst_in };
   
   assign color_out = recalled_pixel[0:3];
   assign sync_h_out = recalled_pixel[4];
   assign cburst_out = recalled_pixel[5];

   always @(posedge clk) begin

      if (clk_en_in && sync_h_in && !last_sync_h) begin
	 line_width <= in_pos;
	 flip = ~flip;
	 in_pos = 9'd0;
	 out_pos = 9'd0;
      end

      if (clk_en_out) begin
	 if (out_pos == line_width)
	   out_pos = 9'd0;
	 recalled_pixel <= buffer[{~flip, out_pos}];
	 out_pos = out_pos + 9'd1;
      end

      if (clk_en_in) begin
	 buffer[{flip, in_pos}] <= stashed_pixel;
	 in_pos = in_pos + 9'd1;
	 last_sync_h = sync_h_in;
      end

   end // always @ (posedge clk)

endmodule // tms9918_scandoubler
