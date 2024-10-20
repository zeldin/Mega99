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
		   output reg [0:4]  sw_reset,
		   output [0:23]     led1_rgb,
		   output [0:23]     led2_rgb,
		   output [0:23]     led3_rgb,
		   output [0:23]     led4_rgb,
		   input [1:3]	     drive_activity);

   reg [0:23] led1_rgb_value;
   reg [0:23] led2_rgb_value;
   reg [0:23] led3_rgb_value;
   reg [0:23] led4_rgb_value;
   reg [0:3]  led1_rgb_enable;
   reg [0:3]  led2_rgb_enable;
   reg [0:3]  led3_rgb_enable;
   reg [0:3]  led4_rgb_enable;
   wire [0:23] led1_rgb_default;
   wire [0:23] led2_rgb_default;
   wire [0:23] led3_rgb_default;
   wire [0:23] led4_rgb_default;
   wire [0:23] status_led_rgb;
   wire [0:3]  rgb_enable_flags;

   assign status_led_rgb = { {8{led_red}}, {8{led_green}}, {8{1'b0}} };

   assign rgb_enable_flags = { 1'b1, drive_activity };

   assign led1_rgb_default = status_led_rgb;
   assign led2_rgb_default = status_led_rgb;
   assign led3_rgb_default = 0;
   assign led4_rgb_default = 0;

   assign led1_rgb = ((|(led1_rgb_enable & rgb_enable_flags))?
		      led1_rgb_value : led1_rgb_default);
   assign led2_rgb = ((|(led2_rgb_enable & rgb_enable_flags))?
		      led2_rgb_value : led2_rgb_default);
   assign led3_rgb = ((|(led3_rgb_enable & rgb_enable_flags))?
		      led3_rgb_value : led3_rgb_default);
   assign led4_rgb = ((|(led4_rgb_enable & rgb_enable_flags))?
		      led4_rgb_value : led4_rgb_default);

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[0:3] <= led1_rgb_enable;
	   q[4:7] <= led2_rgb_enable;
	   q[8:11] <= led3_rgb_enable;
	   q[12:15] <= led4_rgb_enable;
	   q[30] <= led_red;
	   q[31] <= led_green;
	end
	4'h1: q[24:31] <= { sw_reset, 3'b111 };
	4'h2: q[8:31] <= led1_rgb_value;
	4'h3: q[8:31] <= led2_rgb_value;
	4'h4: q[8:31] <= led3_rgb_value;
	4'h5: q[8:31] <= led4_rgb_value;
	default: ;
      endcase // case (adr)
   end

   always @(posedge clk)
     if (reset) begin
	led_red <= 1'b0;
	led_green <= 1'b0;
	led1_rgb_enable <= 4'b0000;
	led2_rgb_enable <= 4'b0000;
	led3_rgb_enable <= 4'b0000;
	led4_rgb_enable <= 4'b0000;
	sw_reset <= 5'b11111;
     end else if (cs && we && sel[3])
       case (adr)
	 4'h0: begin
	    led1_rgb_enable <= d[0:3];
	    led2_rgb_enable <= d[4:7];
	    led3_rgb_enable <= d[8:11];
	    led4_rgb_enable <= d[12:15];
	    led_red <= d[30];
	    led_green <= d[31];
	 end
	 4'h1: sw_reset <= d[24:28];
	 4'h2: led1_rgb_value <= d[8:31];
	 4'h3: led2_rgb_value <= d[8:31];
	 4'h4: led3_rgb_value <= d[8:31];
	 4'h5: led4_rgb_value <= d[8:31];
       endcase // case (adr)

endmodule // spmmio_misc
