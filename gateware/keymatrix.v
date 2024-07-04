module keymatrix(input [2:5]    p_out,
		 output [3:6]	int_in,
		 output [12:15]	p_in,

		 input [0:47]	key_state,
		 input		alpha_state,
		 input [0:4]	joy1,
		 input [0:4]	joy2);

   wire	      alpha;
   wire [0:2] column;
   reg  [0:7] row;

   assign alpha = ~p_out[5];
   assign column = { p_out[4], p_out[3], p_out[2] };
   assign int_in[3:6] = ~{ row[0], row[1], row[2], row[3] };
   assign p_in[12:15] = ~{ row[7], row[6], row[5], row[4] };

   always @(*)
     if (alpha)
       row = { 4'b0000, alpha_state, 3'b000 };
     else
       case (column)
	 3'b000: row = key_state[0:7];
	 3'b001: row = key_state[8:15];
	 3'b010: row = key_state[16:23];
	 3'b011: row = key_state[24:31];
	 3'b100: row = key_state[32:39];
	 3'b101: row = key_state[40:47];
	 3'b110: row = { joy1, 3'b000 };
	 3'b111: row = { joy2, 3'b000 };
       endcase // case (column)
   
endmodule // keymatrix
