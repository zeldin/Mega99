module spmmio_keyboard(input             clk,
		       input		 reset,

		       input [0:2]	 adr,
		       input		 cs,
		       input [0:3]	 sel,
		       input		 we,
		       input [0:31]	 d,
		       output reg [0:31] q,

		       input		 keypress,
		       input             isup,
		       input [0:6]	 keycode,
		       input [0:3]	 shift_state,
		       output reg	 keyboard_block,
		       output reg [0:47] synth_key_state,
		       output reg	 synth_keys_enabled);

   parameter fifo_depth = 8;
   parameter keyboard_model = 0;

   wire [0:(fifo_depth-1)] entry_inuse;
   wire [0:11]		   input_data;
   wire			   fifo_isup;
   wire [0:6]		   fifo_keycode;
   wire [0:3]		   fifo_shift_state;
   wire			   fifo_valid;
   wire			   read_strobe;

   assign input_data = { isup, shift_state, keycode };

   assign read_strobe = (cs && !we && adr == 3'h0);

   genvar i;
   generate
      for (i=0; i<fifo_depth; i=i+1) begin : ENTRY
	 reg [0:11]  data;
	 wire [0:11] prev_data;
	 reg	     inuse;
	 wire	     prev_inuse;
	 wire	     next_inuse;
	 assign entry_inuse[i] = inuse;
	 if (i == 0) begin
	    assign prev_data = input_data;
	    assign prev_inuse = keypress;
	 end else begin
	    assign prev_data = ENTRY[i-1].data;
	    assign prev_inuse = ENTRY[i-1].inuse;
	    assign ENTRY[i-1].next_inuse = inuse;
	 end
	 if (i == fifo_depth-1) begin
	    assign fifo_valid = inuse;
	    assign fifo_isup = data[0];
	    assign fifo_shift_state = data[1:4];
	    assign fifo_keycode = data[5:11];
	    assign next_inuse = !read_strobe;
	 end
	 always @(posedge clk) begin

	    if (read_strobe || (keypress & !inuse))
	      data <= (prev_inuse ? prev_data : input_data);

	    if (reset)
	      inuse <= 1'b0;
	    else begin
	       if (keypress && !read_strobe)
		 inuse <= next_inuse;
	       if (read_strobe && !keypress)
		 inuse <= prev_inuse;
	    end
	 end
      end // block: ENTRY
   endgenerate

   always @(posedge clk)
     if (reset) begin
	keyboard_block <= 1'b0;
	synth_key_state <= 48'd0;
	synth_keys_enabled <= 1'b0;
     end else begin
	if (cs && we && sel[0] && adr == 3'h1)
	  keyboard_block <= d[7];
	if (cs && we && adr == 3'h2) begin
	   synth_keys_enabled <= 1'b0;
	   if (sel[0])
	     synth_key_state[16:23] <= d[0:7];
	   if (sel[1])
	     synth_key_state[24:31] <= d[8:15];
	   if (sel[2])
	     synth_key_state[32:39] <= d[16:23];
	   if (sel[3])
	     synth_key_state[40:47] <= d[24:31];
	end
	if (cs && we && adr == 3'h1 && sel[2:3] != 2'b00) begin
	   if (sel[2])
	     synth_key_state[0:7] <= d[16:23];
	   if (sel[3])
	     synth_key_state[8:15] <= d[24:31];
	   synth_keys_enabled <=
	     |{ (sel[2]? d[16:23] : synth_key_state[0:7]),
		(sel[3]? d[24:31] : synth_key_state[8:15]),
		synth_key_state[16:47] };
	end
     end

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	3'h0: begin
	   q[0] <= fifo_valid;
	   q[1:3] <= keyboard_model;
	   q[4:7] <= fifo_shift_state;
	   q[8] <= fifo_isup;
	   q[9:15] <= fifo_keycode;
	end
	3'h1: begin
	   q[7] <= keyboard_block;
	   q[16:31] <= synth_key_state[0:15];
	end
	3'h2: q <= synth_key_state[16:47];
	default: ;
      endcase // case (adr)
   end

endmodule // spmmio_keyboard
