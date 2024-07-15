module spmmio_keyboard(input             clk,
		       input		 reset,

		       input [0:2]	 adr,
		       input		 cs,
		       input [0:3]	 sel,
		       input		 we,
		       input [0:31]	 d,
		       output reg [0:31] q,

		       input		 keypress,
		       input [0:6]	 keycode,
		       input [0:3]	 shift_state);

   parameter fifo_depth = 8;

   wire [0:(fifo_depth-1)] entry_inuse;
   wire [0:10]		   input_data;
   wire [0:6]		   fifo_keycode;
   wire [0:3]		   fifo_shift_state;
   wire			   fifo_valid;
   wire			   read_strobe;

   assign input_data = { shift_state, keycode };

   assign read_strobe = (cs && !we && adr == 3'h0);

   genvar i;
   generate
      for (i=0; i<fifo_depth; i=i+1) begin : ENTRY
	 reg [0:10]  data;
	 wire [0:10] prev_data;
	 reg	    inuse;
	 wire	    prev_inuse;
	 wire	    next_inuse;
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
	    assign fifo_shift_state = data[0:3];
	    assign fifo_keycode = data[4:10];
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

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	3'h0: begin
	   q[0] <= fifo_valid;
	   q[4:7] <= fifo_shift_state;
	   q[9:15] <= fifo_keycode;
	end
	default: ;
      endcase // case (adr)
   end

endmodule // spmmio_keyboard
