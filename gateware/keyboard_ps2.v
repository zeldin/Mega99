module keyboard_ps2(input             clk,
		    input	      reset,
		    input [0:7]	      scancode,
		    input	      trigger,

		    output reg [0:47] key_state,
		    output reg	      alpha_state,
		    output reg	      turbo_state);

   reg [0:8] pending;
   reg	     upflag;
   reg [0:1] shift;
   
   always @(posedge clk)
     if (reset) begin
	key_state <= 48'd0;
	alpha_state <= 1'b0;
	turbo_state <= 1'b0;
	pending[0] <= 1'b0;
	upflag <= 1'b0;
	shift <= 2'b00;
     end else begin
	if (pending[0]) begin
	   case (pending[2:8])
	     7'h11: key_state[4] <= pending[1];
	    /* 7'h12 */ 7'h61: begin
		shift[0] <= pending[1];
		if (pending[1]) key_state[5] <= 1'b1;
		else if (!shift[1]) key_state[5] <= 1'b0;
	     end
	     7'h14: key_state[6] <= pending[1];
	     7'h15: key_state[46] <= pending[1];
	     7'h16: key_state[44] <= pending[1];
	     7'h1a: key_state[47] <= pending[1];
	     7'h1b: key_state[13] <= pending[1];
	     7'h1c: key_state[45] <= pending[1];
	     7'h1d: key_state[14] <= pending[1];
	     7'h1e: key_state[12] <= pending[1];
	     7'h21: key_state[23] <= pending[1];
	     7'h22: key_state[15] <= pending[1];
	     7'h23: key_state[21] <= pending[1];
	     7'h24: key_state[22] <= pending[1];
	     7'h25: key_state[28] <= pending[1];
	     7'h26: key_state[20] <= pending[1];
	     7'h29: key_state[1] <= pending[1];
	     7'h2a: key_state[31] <= pending[1];
	     7'h2b: key_state[29] <= pending[1];
	     7'h2c: key_state[38] <= pending[1];
	     7'h2d: key_state[30] <= pending[1];
	     7'h2e: key_state[36] <= pending[1];
	     7'h31: key_state[32] <= pending[1];
	     7'h32: key_state[39] <= pending[1];
	     7'h33: key_state[33] <= pending[1];
	     7'h34: key_state[37] <= pending[1];
	     7'h35: key_state[34] <= pending[1];
	     7'h36: key_state[35] <= pending[1];
	     7'h3a: key_state[24] <= pending[1];
	     7'h3b: key_state[25] <= pending[1];
	     7'h3c: key_state[26] <= pending[1];
	     7'h3d: key_state[27] <= pending[1];
	     7'h3e: key_state[19] <= pending[1];
	     7'h41: key_state[16] <= pending[1];
	     7'h42: key_state[17] <= pending[1];
	     7'h43: key_state[18] <= pending[1];
	     7'h44: key_state[10] <= pending[1];
	     7'h45: key_state[43] <= pending[1];
	     7'h46: key_state[11] <= pending[1];
	     7'h49: key_state[8] <= pending[1];
	     7'h4b: key_state[9] <= pending[1];
	     7'h4c: key_state[41] <= pending[1];
	     7'h4d: key_state[42] <= pending[1];
	     7'h4e: key_state[0] <= pending[1];
	     7'h54: key_state[40] <= pending[1];
	     7'h58: if (pending[1]) alpha_state <= ~alpha_state;
	     7'h59: begin
		shift[1] <= pending[1];
		if (pending[1]) key_state[5] <= 1'b1;
		else if (!shift[0]) key_state[5] <= 1'b0;
	     end
	     7'h5a: key_state[2] <= pending[1];
	     7'h77: if (pending[1]) turbo_state <= ~turbo_state;
	     default: ;
	   endcase // case (pending[2:8])
	   pending[0] <= 1'b0;
	end
	if (trigger) begin
	   if (!scancode[0]) begin
	      pending <= { 1'b1, ~upflag, scancode[1:7] };
	      upflag <= 1'b0;
	   end else begin
	      upflag <= 1'b0;
	      case (scancode)
		8'hf0: upflag <= 1'b1;
		default: ;
	      endcase // case (scancode)
	   end
	end // if (trigger)
     end // else: !if(reset)

endmodule // keyboard_ps2
