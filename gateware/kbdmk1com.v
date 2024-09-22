module kbdmk1com(input        clk,
		 output	reg   kb_ck,
		 output       kb_do,
		 input	      kb_di,
		 input [0:23] led1_rgb,
		 input [0:23] led2_rgb,
		 input [0:23] led3_rgb,
		 input [0:23] led4_rgb,
		 output [0:6] kbd_scancode,
		 output	reg   kbd_keypress,
		 output	reg   kbd_strobe);

   parameter clk_divider = 175;

   reg [0:8]  bit_cnt = 0;
   reg [0:96] led_output;
   reg [0:7]  delay_cnt = 0;
   reg	      tick;

   assign kb_do = led_output[0];
   assign kbd_scancode = bit_cnt[1:7];

   always @(posedge clk)
     if (tick) begin
	tick <= 1'b0;
	delay_cnt <= 0;
	kb_ck <= bit_cnt[0] | ~bit_cnt[8];
	kbd_strobe <= 1'b0;
	if (!bit_cnt[0] && !bit_cnt[8]) begin
	   kbd_keypress <= ~kb_di;
	   if (kbd_scancode < 80)
	     kbd_strobe <= 1;
	end
	if (bit_cnt[8]) begin
	   if (|(bit_cnt[1:2]))
	     led_output <= { led_output[1:96], 1'b0 };
	   else
	     led_output <= { 1'b0, // vvv  blue is transmitted first  vvv
			     led1_rgb[16:23], led1_rgb[8:15], led1_rgb[0:7],
			     led2_rgb[16:23], led2_rgb[8:15], led2_rgb[0:7],
			     led3_rgb[16:23], led3_rgb[8:15], led3_rgb[0:7],
			     led4_rgb[16:23], led4_rgb[8:15], led4_rgb[0:7] };
	end
	if (bit_cnt == 9'd281)
	  bit_cnt <= 0;
	else
	  bit_cnt <= bit_cnt + 1;
     end else begin // if (tick)
	kbd_strobe <= 1'b0;
	tick <= (delay_cnt == (clk_divider-2));
	delay_cnt <= delay_cnt + 1;
     end // else: !if(tick)

endmodule // kbdmk1com
