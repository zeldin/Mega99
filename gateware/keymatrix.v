module keymatrix(input clk,

		 input [2:5]	p_out,
		 output [3:6]	int_in,
		 output [12:15]	p_in,

		 input [0:47]	key_state,
		 input		alpha_state,
		 input [0:4]	joy1,
		 input [0:4]	joy2,

		 input [0:47]	synth_key_state,
		 input		synth_keys_enabled);

   wire [0:47] key_state_int;
   wire	       alpha;
   wire [0:2]  column;
   reg  [0:7]  row;
   reg	       synth_keys_active;
   reg	       synth_keys_valid;
   wire	       column0;
   reg	       old_column0;

   assign key_state_int = ( synth_keys_active ?
			    ( synth_keys_valid ? synth_key_state :
			      ( !synth_keys_enabled ? 48'd0 :
				{ synth_key_state[0] & synth_key_state[4],
				  3'b000, synth_key_state[4:6], 41'd0 } ) )
			    : key_state );

   assign alpha = ~p_out[5];
   assign column = { p_out[4], p_out[3], p_out[2] };
   assign int_in[3:6] = ~{ row[0], row[1], row[2], row[3] };
   assign p_in[12:15] = ~{ row[7], row[6], row[5], row[4] };
   assign column0 = (column == 3'd0);

   always @(posedge clk) begin
      if (!synth_keys_enabled)
	synth_keys_valid <= 1'b0;
      if (column0)
	synth_keys_active <= synth_keys_enabled;
      if (column0 && !old_column0 &&
	  synth_keys_active && synth_keys_enabled)
	synth_keys_valid <= 1'b1;
      old_column0 <= column0;
   end

   always @(*)
     if (alpha)
       row = { 4'b0000, alpha_state, 3'b000 };
     else
       case (column)
	 3'b000: row = key_state_int[0:7];
	 3'b001: row = key_state_int[8:15];
	 3'b010: row = key_state_int[16:23];
	 3'b011: row = key_state_int[24:31];
	 3'b100: row = key_state_int[32:39];
	 3'b101: row = key_state_int[40:47];
	 3'b110: row = { joy1, 3'b000 };
	 3'b111: row = { joy2, 3'b000 };
       endcase // case (column)
   
endmodule // keymatrix
