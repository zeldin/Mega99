module max10_reset_button(input  clk,
			  output rx,
			  input	 tx,
			  output sync,
			  output reset_button);

   parameter CLK_SHIFT = 1;
   parameter PERIOD = 80;
   parameter DEBOUNCE = 2;
   
   reg [7+CLK_SHIFT:0] div_counter = 0;

   wire [7:0] cnt;
   assign cnt = div_counter[7+CLK_SHIFT:CLK_SHIFT];

   reg clkout = 1'b0;
   assign rx = 1'b0;
   assign sync = clkout;

   reg one_flag = 1'b0;
   reg zero_flag = 1'b0;
   reg rb_bit = 1'b0;
   reg [DEBOUNCE-1:0] rb_debounce = 0;   
   assign reset_button = &rb_debounce;

   always @(posedge clk) begin
      div_counter <= div_counter + 1;
      if (&div_counter[CLK_SHIFT-1:0]) begin
	 clkout <= cnt[0] & ~cnt[7];
	 if (cnt[0]) begin
	    if (tx)
	      one_flag <= 1'b0;
	    else
	      zero_flag <= 1'b0;
	 end
	 if (cnt == 8'h61)
	   rb_bit <= tx;
	 if (cnt == 8'h80) begin
	    rb_debounce[DEBOUNCE-1:1] <= rb_debounce[DEBOUNCE-2:0];
	    if (zero_flag && !one_flag)
	      rb_debounce[0] <= 1'b0;
	    else if (one_flag && !zero_flag)
	      rb_debounce[0] <= 1'b1;
	    else
	      rb_debounce[0] <= ~rb_bit;
	    zero_flag <= 1'b1;
	    one_flag <= 1'b1;
	 end
	 if (cnt == 2*PERIOD-1)
	   div_counter <= 0;
      end
   end

endmodule // max10_reset_button
