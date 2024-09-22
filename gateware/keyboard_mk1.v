module keyboard_mk1(input             clk,
		    input	      reset,
		    input [0:6]	      scancode,
		    input	      trigger,
		    input	      pressed,

		    output reg [0:47] key_state,
		    output reg	      alpha_state,
		    output reg	      turbo_state,

		    output reg	      keypress,
		    output reg [0:6]  keycode,
		    output reg [0:3]  shift_state,
		    input	      keyboard_block);

   reg [0:79] pressed_state;
   reg	      repeat_enable;
   reg [0:9]  repeat_dly;
   reg [0:1]  shift;

   always @(posedge clk)
     if (reset) begin
	key_state <= 48'd0;
	alpha_state <= 1'b0;
	turbo_state <= 1'b0;
	keypress <= 1'b0;
	keycode <= 7'd0;
	shift_state <= 4'b0000;
	pressed_state <= 80'd0;
	repeat_enable <= 1'b0;
	shift <= 2'b00;
     end else if (trigger) begin
	keypress <= 1'b0;
	case (scancode)
	  7'h0f: shift_state[3] <= pressed;
	  7'h34: shift_state[2] <= pressed;
	  7'h3d: shift_state[1] <= pressed;
	  7'h3a: shift_state[0] <= pressed;
	  7'h48: alpha_state <= pressed;
	endcase // case (scancode)
	if (pressed) begin
	   if (repeat_enable && keycode == scancode && (|repeat_dly))
	     repeat_dly <= repeat_dly - 10'd1;
	   if (!pressed_state[0]) begin
	      keycode <= scancode;
	      repeat_enable <= 1'b1;
	      if (scancode == 7'h40)
		turbo_state <= ~turbo_state;
	   end
	   if (!pressed_state[0] || (repeat_enable && keycode == scancode && !(|repeat_dly))) begin
	      keypress <= 1'b1;
	      repeat_dly <= (pressed_state[0] ? 10'd255 : 10'd1023);
	   end
	end else if (repeat_enable && keycode == scancode) // if (pressed)
	  repeat_enable <= 1'b0;
	pressed_state <= { pressed_state[1:79], pressed };

	if (!(pressed && keyboard_block)) begin
	   case (scancode)
	     7'h08: key_state[20] <= pressed;
	     7'h09: key_state[14] <= pressed;
	     7'h0a: key_state[45] <= pressed;
	     7'h0b: key_state[28] <= pressed;
	     7'h0c: key_state[47] <= pressed;
	     7'h0d: key_state[13] <= pressed;
	     7'h0e: key_state[22] <= pressed;
	     7'h0f: begin
		shift[0] <= pressed;
		if (pressed) key_state[5] <= 1'b1;
		else if (!shift[1]) key_state[5] <= 1'b0;
	     end
	     7'h10: key_state[36] <= pressed;
	     7'h11: key_state[30] <= pressed;
	     7'h12: key_state[21] <= pressed;
	     7'h13: key_state[35] <= pressed;
	     7'h14: key_state[23] <= pressed;
	     7'h15: key_state[29] <= pressed;
	     7'h16: key_state[38] <= pressed;
	     7'h17: key_state[15] <= pressed;
	     7'h18: key_state[27] <= pressed;
	     7'h19: key_state[34] <= pressed;
	     7'h1a: key_state[37] <= pressed;
	     7'h1b: key_state[19] <= pressed;
	     7'h1c: key_state[39] <= pressed;
	     7'h1d: key_state[33] <= pressed;
	     7'h1e: key_state[26] <= pressed;
	     7'h1f: key_state[31] <= pressed;
	     7'h20: key_state[11] <= pressed;
	     7'h21: key_state[18] <= pressed;
	     7'h22: key_state[25] <= pressed;
	     7'h23: key_state[43] <= pressed;
	     7'h24: key_state[24] <= pressed;
	     7'h25: key_state[17] <= pressed;
	     7'h26: key_state[10] <= pressed;
	     7'h27: key_state[32] <= pressed;
	     7'h28: key_state[0] <= pressed;
	     7'h29: key_state[42] <= pressed;
	     7'h2a: key_state[9] <= pressed;
	     7'h2c: key_state[8] <= pressed;
	     7'h2d: key_state[41] <= pressed;
	     7'h2e: key_state[40] <= pressed;
	     7'h2f: key_state[16] <= pressed;
	     7'h34: begin
		shift[1] <= pressed;
		if (pressed) key_state[5] <= 1'b1;
		else if (!shift[0]) key_state[5] <= 1'b0;
	     end
	     7'h38: key_state[44] <= pressed;
	     7'h3a: key_state[6] <= pressed;
	     7'h3b: key_state[12] <= pressed;
	     7'h3c: key_state[1] <= pressed;
	     7'h3d: key_state[4] <= pressed;
	     7'h3e: key_state[46] <= pressed;
	     7'h4d: key_state[2] <= pressed;
	   endcase // case (scancode)
	end

     end else // if (trigger)
       keypress <= 1'b0;

endmodule // keyboard_mk1
