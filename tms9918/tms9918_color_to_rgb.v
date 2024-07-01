module tms9918_color_to_rgb
  #(parameter red_bits = 8,
    parameter green_bits = red_bits,
    parameter blue_bits = red_bits)
   (input[0:3] color,
    output reg [0:(red_bits-1)]	  red,
    output reg [0:(green_bits-1)] green,
    output reg [0:(blue_bits-1)]  blue);

   localparam max_red = (1 << red_bits) - 1;
   localparam max_green = (1 << green_bits) - 1;
   localparam max_blue = (1 << blue_bits) - 1;
   
task automatic yprpb_to_rgb(input real y,
			    input real pr,
			    input real pb,
			    output reg [0:(red_bits-1)]	  red,
			    output reg [0:(green_bits-1)] green,
			    output reg [0:(blue_bits-1)]  blue);

   real r;
   real g;
   real b;
   begin
      r = y + pr - 0.47;
      b = y + pb - 0.47;
      g = y*1.70 - r*0.51 - b*0.19;
      if (r > 1.0)
	r = 1.0;
      if (g > 1.0)
	g = 1.0;
      if (b > 1.0)
	b = 1.0;
      red = max_red * r;
      green = max_green * g;
      blue = max_blue * b;
   end
endtask

always @(color) begin
   red = 0;
   green = 0;
   blue = 0;
   case (color)
     4'h0: ;
     4'h1: yprpb_to_rgb(0.00, 0.47, 0.47, red, green, blue);
     4'h2: yprpb_to_rgb(0.54, 0.07, 0.20, red, green, blue);
     4'h3: yprpb_to_rgb(0.67, 0.17, 0.27, red, green, blue);
     4'h4: yprpb_to_rgb(0.40, 0.40, 1.00, red, green, blue);
     4'h5: yprpb_to_rgb(0.53, 0.43, 0.93, red, green, blue);
     4'h6: yprpb_to_rgb(0.47, 0.83, 0.30, red, green, blue);
     4'h7: yprpb_to_rgb(0.73, 0.00, 0.70, red, green, blue);
     4'h8: yprpb_to_rgb(0.53, 0.93, 0.27, red, green, blue);
     4'h9: yprpb_to_rgb(0.67, 0.93, 0.27, red, green, blue);
     4'hA: yprpb_to_rgb(0.73, 0.57, 0.07, red, green, blue);
     4'hB: yprpb_to_rgb(0.80, 0.57, 0.17, red, green, blue);
     4'hC: yprpb_to_rgb(0.47, 0.13, 0.23, red, green, blue);
     4'hD: yprpb_to_rgb(0.53, 0.73, 0.67, red, green, blue);
     4'hE: yprpb_to_rgb(0.80, 0.47, 0.47, red, green, blue);
     4'hF: yprpb_to_rgb(1.00, 0.47, 0.47, red, green, blue);
   endcase // case (color)
end

endmodule
