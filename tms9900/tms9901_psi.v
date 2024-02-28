module tms9901_psi(input reset,
		   input	     clk, // Enabled cycles should give
		   input	     clk_en, // main CPU clock, 3.579545 MHz

		   input	     cruout,
		   output reg        cruin,
		   input	     cruclk,
		   input [0:4]	     s,
		   input	     ce,

		   input [1:6]	     int_in,
		   input [0:15]	     p_in,
		   output reg [0:15] p_out,
		   output reg [0:15] p_dir,

		   output reg	     intreq,
		   output reg [0:3]  ic);

   reg [1:15] interrupt_mask;
   reg [1:15] interrupt_latch;
   
   reg	      control_bit;
   reg	      timer_run;
   reg	      timer_int;
   reg [14:1] clock_reg;
   reg [14:1] read_reg;
   reg [14:1] decrementer;
   reg [0:5]  prediv;
   
   wire [0:15] p_pin;
   assign p_pin = (p_out & p_dir) | (p_in & ~p_dir);

   wire [1:15] int_pin;
   genvar int_id;
   generate
      for (int_id = 15; int_id >= 1; int_id = int_id - 1) begin : INTERRUPT
	 localparam [0:3] my_id = int_id[3:0];
	 wire [0:3] encoder;
	 if (int_id <= 6)
	   assign int_pin[int_id] = int_in[int_id];
	 else
	   assign int_pin[int_id] = p_pin[22-int_id];
	 if (int_id == 15)
	   assign encoder = 4'b1111;
	 else
	   assign encoder = ((interrupt_mask[int_id] & ~interrupt_latch[int_id])?
			     my_id : INTERRUPT[int_id+1].encoder);
      end
   endgenerate

   always @(posedge clk) begin
      if (reset) begin
	 intreq <= 1'b0;
	 ic <= 4'b0000;
      end else begin
	 intreq <= |(interrupt_mask & ~interrupt_latch);
	 ic <= INTERRUPT[1].encoder;
      end

      interrupt_latch <= int_pin;
      if (timer_run)
	interrupt_latch[3] <= ~timer_int;
   end
   
   always @(*) begin
      if (s[0])
	cruin = p_pin[s[1:4]];
      else if (s[1:4] == 4'b0000)
	cruin = control_bit;
      else if (control_bit) begin
	 if (s[1:4] == 4'b1111)
	   cruin = intreq;
	 else
	   cruin = read_reg[s[1:4]];
      end else if(s[1:4] <= 4'd6)
	cruin = int_in[s[1:4]];
      else
	cruin = p_pin[4'd6 - s[1:4]];
   end	   

   always @(posedge clk)
     if (reset) begin
	p_out <= 16'h0000;	
	p_dir <= 16'h0000;
	interrupt_mask <= 15'h0000;

	control_bit <= 1'b0;
	timer_run <= 1'b0;
	timer_int <= 1'b0;
	clock_reg = 14'h0000;
	read_reg <= 14'h0000;
	decrementer <= 14'h0000;
	prediv <= 6'b111111;
     end else begin
	if (clk_en) begin
	   if (prediv == 6'b000000) begin
	      if (decrementer == 14'd0 && timer_run) begin
		 if (s[0] || !control_bit)
		   read_reg <= clock_reg;
		 decrementer <= clock_reg;
		 timer_int <= 1'b1;
	      end else begin
		 if (s[0] || !control_bit)
		   read_reg <= decrementer - 14'd1;
		 decrementer <= decrementer - 14'd1;
	      end
	   end
	   prediv <= prediv - 6'd1;
	end

	if (cruclk && ce) begin
	   if (s[0]) begin
	      p_out[s[1:4]] <= cruout;
	      p_dir[s[1:4]] <= 1'b1;
	   end else if (s[1:4] == 4'b0000) begin
	      control_bit <= cruout;
	   end else if (control_bit) begin
	      if (s[1:4] == 4'b1111) begin
		 if (cruout) begin
		    // RST2
		    p_out <= 16'h0000;	
		    p_dir <= 16'h0000;
		    interrupt_mask <= 15'h0000;
		 end
	      end else begin
		 clock_reg[s[1:4]] = cruout;
		 decrementer <= clock_reg;
		 timer_run <= |clock_reg;
	      end
	   end else begin
	      interrupt_mask[s[1:4]] <= cruout;
	      if (s[1:4] == 4'd3)
		timer_int <= 1'b0;
	   end
	end

     end // else: !if(reset)

endmodule // tms9901_psi
