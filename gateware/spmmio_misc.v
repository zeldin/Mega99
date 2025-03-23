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
		   output reg [0:6]  sw_enable,
		   output reg [0:3]  sw_dip,
		   output [0:23]     led1_rgb,
		   output [0:23]     led2_rgb,
		   output [0:23]     led3_rgb,
		   output [0:23]     led4_rgb,
		   input	     cpu_turbo,
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

   reg [0:4]   icap_reg = 5'b00111;
   wire [0:31] icap_value;
   wire	       icap_busy;
   reg	       icap_trigger;

   assign status_led_rgb = { {8{led_red}}, {8{led_green}}, {8{1'b0}} };

   assign rgb_enable_flags = { cpu_turbo, drive_activity };

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
	4'h1: begin
	   q[0:7] <= { sw_dip, 4'b0000 };
	   q[8:15] <= { sw_enable, 1'b0 };
	   q[16:23] <= 8'hff;
	   q[24:31] <= { sw_reset, 3'b111 };
	end
	4'h2: q[8:31] <= led1_rgb_value;
	4'h3: q[8:31] <= led2_rgb_value;
	4'h4: q[8:31] <= led3_rgb_value;
	4'h5: q[8:31] <= led4_rgb_value;
	4'h6: q <= icap_value;
	4'h7: begin
	   q[0] <= icap_busy;
	   q[27:31] <= icap_reg;
	end
	default: ;
      endcase // case (adr)
   end

   always @(posedge clk) begin

      icap_trigger <= 1'b0;

      if (reset) begin
	 led_red <= 1'b0;
	 led_green <= 1'b0;
	 led1_rgb_enable <= 4'b0000;
	 led2_rgb_enable <= 4'b0000;
	 led3_rgb_enable <= 4'b0000;
	 led4_rgb_enable <= 4'b0000;
	 sw_reset <= 5'b11111;
	 sw_enable <= 7'b0000000;
	 sw_dip <= 4'b0000;
      end else if (cs && we) begin
	 if (sel[0])
	   case (adr)
	     4'h0: begin
		led1_rgb_enable <= d[0:3];
		led2_rgb_enable <= d[4:7];
	     end
	     4'h1: sw_dip <= d[0:3];
	   endcase // case (adr)
	 if (sel[1])
	   case (adr)
	     4'h0: begin
		led3_rgb_enable <= d[8:11];
		led4_rgb_enable <= d[12:15];
	     end
	     4'h1: sw_enable <= d[8:14];
	     4'h2: led1_rgb_value[0:7] <= d[8:15];
	     4'h3: led2_rgb_value[0:7] <= d[8:15];
	     4'h4: led3_rgb_value[0:7] <= d[8:15];
	     4'h5: led4_rgb_value[0:7] <= d[8:15];
	   endcase // case (adr)
	 if (sel[2])
	   case (adr)
	     4'h2: led1_rgb_value[8:15] <= d[16:23];
	     4'h3: led2_rgb_value[8:15] <= d[16:23];
	     4'h4: led3_rgb_value[8:15] <= d[16:23];
	     4'h5: led4_rgb_value[8:15] <= d[16:23];
	   endcase // case (adr)
	 if (sel[3])
	   case (adr)
	     4'h0: begin
		led_red <= d[30];
		led_green <= d[31];
	     end
	     4'h1: sw_reset <= d[24:28];
	     4'h2: led1_rgb_value[16:23] <= d[24:31];
	     4'h3: led2_rgb_value[16:23] <= d[24:31];
	     4'h4: led3_rgb_value[16:23] <= d[24:31];
	     4'h5: led4_rgb_value[16:23] <= d[24:31];
	     4'h7: begin
		icap_reg <= d[27:31];
		icap_trigger <= 1'b1;
	     end
	   endcase // case (adr)
      end // if (cs && we)
   end // always @ (posedge clk)

   icap_wrapper icap(.clk(clk), .reg_num(icap_reg), .reg_value(icap_value),
		       .trigger_read(icap_trigger), .busy(icap_busy));

endmodule // spmmio_misc
