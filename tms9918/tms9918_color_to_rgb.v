module tms9918_color_to_rgb(input[0:3] color,
			    output reg [0:(red_bits-1)] red,
			    output reg [0:(green_bits-1)] green,
			    output reg [0:(blue_bits-1)] blue);

   parameter red_bits = 8;
   parameter green_bits = red_bits;
   parameter blue_bits = red_bits;

   localparam max_red = (1 << red_bits) - 1;
   localparam max_green = (1 << green_bits) - 1;
   localparam max_blue = (1 << blue_bits) - 1;
   
task automatic yprpb_to_rgb(input integer y,
			    input integer pr,
			    input integer pb,
			    output reg [0:(red_bits-1)]	  red,
			    output reg [0:(green_bits-1)] green,
			    output reg [0:(blue_bits-1)]  blue);

   integer r;
   integer g;
   integer b;
   begin
      r = y + pr - 0_4700;
      b = y + pb - 0_4700;
      g = (y*1_7000 - r*0_5100 - b*0_1900 + 0_5000) / 1_0000;
      if (r > 1_0000)
	r = 1_0000;
      if (g > 1_0000)
	g = 1_0000;
      if (b > 1_0000)
	b = 1_0000;
      r = (max_red * r + 0_5000) / 1_0000;
      g = (max_green * g + 0_5000) / 1_0000;
      b = (max_blue * b + 0_5000) / 1_0000;
      red = r[(red_bits-1):0];
      green = g[(green_bits-1):0];
      blue = b[(blue_bits-1):0];
   end
endtask

always @(color) begin
   red = 0;
   green = 0;
   blue = 0;
   case (color)
     4'h0: ;
     4'h1: yprpb_to_rgb(0_0000, 0_4700, 0_4700, red, green, blue);
     4'h2: yprpb_to_rgb(0_5400, 0_0700, 0_2000, red, green, blue);
     4'h3: yprpb_to_rgb(0_6700, 0_1700, 0_2700, red, green, blue);
     4'h4: yprpb_to_rgb(0_4000, 0_4000, 1_0000, red, green, blue);
     4'h5: yprpb_to_rgb(0_5300, 0_4300, 0_9300, red, green, blue);
     4'h6: yprpb_to_rgb(0_4700, 0_8300, 0_3000, red, green, blue);
     4'h7: yprpb_to_rgb(0_7300, 0_0000, 0_7000, red, green, blue);
     4'h8: yprpb_to_rgb(0_5300, 0_9300, 0_2700, red, green, blue);
     4'h9: yprpb_to_rgb(0_6700, 0_9300, 0_2700, red, green, blue);
     4'hA: yprpb_to_rgb(0_7300, 0_5700, 0_0700, red, green, blue);
     4'hB: yprpb_to_rgb(0_8000, 0_5700, 0_1700, red, green, blue);
     4'hC: yprpb_to_rgb(0_4700, 0_1300, 0_2300, red, green, blue);
     4'hD: yprpb_to_rgb(0_5300, 0_7300, 0_6700, red, green, blue);
     4'hE: yprpb_to_rgb(0_8000, 0_4700, 0_4700, red, green, blue);
     4'hF: yprpb_to_rgb(1_0000, 0_4700, 0_4700, red, green, blue);
   endcase // case (color)
end

endmodule
