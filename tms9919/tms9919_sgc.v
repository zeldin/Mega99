module tms9919_sgc
       #(parameter audio_bits = 16) // should be > 8 for full dynamic range
                  (input reset,
		   input clk, // Enabled cycles should give
		   input clk_en, // 3.579545 MHz

		   input [0:7]			 d,
		   input			 cs,
		   input			 we,
		   output			 ready,
		   input [0:(audio_bits-1)]	 audioin,
		   output reg [0:(audio_bits-1)] audioout);

   reg  [0:2] r;
   wire [0:2] raddr;

   reg [0:3]  div16;
   reg [0:6]  div2048;
   reg	      tick16;
   reg	      tick512;
   reg	      tick1024;
   reg	      tick2048;
   wire	      tickgen2;

   reg [0:audio_bits]     accum;
   reg		          onval;
   reg [0:3]	          aval;
   reg [0:(audio_bits-4)] term;
   reg			  term_valid;

   function [0:(audio_bits-4)] atten(input [0:31] fraction);
      begin
	 atten = fraction[0:(audio_bits-4)];
      end
   endfunction
   
   assign ready = 1'b1;

   assign raddr = (d[0] ? d[1:3] : r);
   
   genvar i;
   generate
      for (i = 0; i <= 3; i = i+1) begin : GENERATOR
	 reg [0:3] a;
	 if (i == 3) begin
	    reg        fb;
	    reg [0:1]  f;
	    reg	       tick;
	    reg [0:14] shiftreg;
	    wire       feedback;
	    assign feedback = (fb ? ~(shiftreg[13] ^ shiftreg[14]) :
			       shiftreg[14]);
	    always @(posedge clk)
	      case (f)
		2'b00: tick <= tick512;
		2'b01: tick <= tick1024;
		2'b10: tick <= tick2048;
		2'b11: tick <= tickgen2;
	      endcase // case (f)
	 end else begin
	    reg [0:9] f;
	    reg [0:9] decrementer;
	    wire      tick;
	    assign tick = tick16;
	    if (i == 2) begin
	       reg tickout;
	       assign tickgen2 = tickout;
	    end
	 end
	 reg on;
	 always @(posedge clk)
	   if (reset) begin
	      a <= 4'b1111;
	      if (i == 3) begin
		 fb <= 1'b0;
		 f <= 2'b00;
		 shiftreg <= 15'h4000;
	      end else begin
		 f <= 10'h000;
		 decrementer <= 10'd0;
	      end;
	      on <= 1'b0;
	      if (i == 2)
		tickout <= 1'b0;
	   end else begin
	      if (i == 2)
		tickout <= 1'b0;
	      if (tick)
		if (i == 3) begin
		   on <= shiftreg[14];
		   shiftreg <= { feedback, shiftreg[0:13] };
		end else begin
		   if (decrementer[0:8] == 9'd0) begin
		      decrementer <= f;
		      if (i == 2 && on)
			tickout <= 1'b1;
		      on <= ~on;
		   end else
		     decrementer <= decrementer - 10'd1;
		end
	      if (cs && we && raddr[0:1] == i) begin
		 if (raddr[2] == 1'b1)
		   a <= d[4:7];
		 else if (i == 3) begin
		    fb <= d[5];
		    f <= d[6:7];
		    shiftreg <= 15'h4000;
		 end else if (d[0] == 1'b1)
		   f[6:9] <= d[4:7];
		 else
		   f[0:5] <= d[2:7];
	      end
	   end
      end
   endgenerate

   always @(posedge clk) begin
     if (cs && we && d[0])
       r <= d[1:3];

      tick16 <= 1'b0;
      tick512 <= 1'b0;
      tick1024 <= 1'b0;
      tick2048 <= 1'b0;
      if (reset) begin
	 term_valid <= 1'b0;
	 onval <= 1'b0;
	 div16 <= 4'd0;
	 accum <= { audioin[0], audioin }; // sign extend
	 audioout <= audioin;
      end else if (clk_en) begin
	 if (term_valid)
	   accum <= accum + { 4'b0000, term };
	 term_valid <= onval;
	 if (onval)
	   case (aval)
	     4'b0000: term <= atten(32'b11111111111111111111111111111111);
	     4'b0001: term <= atten(32'b11001011010110010001100001011101);
	     4'b0010: term <= atten(32'b10100001100001100110101110100111);
	     4'b0011: term <= atten(32'b10000000010011011100111001111001);
	     4'b0100: term <= atten(32'b01100101111010100101100111111101);
	     4'b0101: term <= atten(32'b01010000111101000100110110001000);
	     4'b0110: term <= atten(32'b01000000010011011110011000011111);
	     4'b0111: term <= atten(32'b00110011000101000010011010101110);
	     4'b1000: term <= atten(32'b00101000100100101100000110001010);
	     4'b1001: term <= atten(32'b00100000001110100111111001011011);
	     4'b1010: term <= atten(32'b00011001100110011001100110011001);
	     4'b1011: term <= atten(32'b00010100010101011011010110100010);
	     4'b1100: term <= atten(32'b00010000001001110000101011000011);
	     4'b1101: term <= atten(32'b00001100110101001001010010100101);
	     4'b1110: term <= atten(32'b00001010001100010000100011111111);
	     4'b1111: term <= atten(32'b00000000000000000000000000000000);
	   endcase // case (aval)
	 onval <= 1'b0;
	 case (div16)
	   4'd0: begin
	      aval <= GENERATOR[0].a;
	      onval <= GENERATOR[0].on;
	   end
	   4'd1: begin
	      aval <= GENERATOR[1].a;
	      onval <= GENERATOR[1].on;
	   end
	   4'd2: begin
	      aval <= GENERATOR[2].a;
	      onval <= GENERATOR[2].on;
	   end
	   4'd3: begin
	      aval <= GENERATOR[3].a;
	      onval <= GENERATOR[3].on;
	   end
	   4'd7: div2048 <= div2048 + 7'd1;
	   4'd8: begin
	      tick16 <= 1'b1;
	      if (div2048[0:6] == 7'b0000000)
		tick2048 <= 1'b1;
	      if (div2048[1:6] == 6'b000000)
		tick1024 <= 1'b1;
	      if (div2048[2:6] == 5'b00000)
		tick512 <= 1'b1;
	   end
	   4'd15: begin
	      if (accum[0:1] == 2'b00 || accum[0:1] == 2'b11)
		audioout <= accum[1:audio_bits];
	      else
		// Saturation
		audioout <= { accum[0], {(audio_bits-1){~accum[0]}} };
	      accum <= { audioin[0], audioin }; // sign extend
	   end
	 endcase
	 div16 <= div16 + 4'd1;
      end
   end
      
endmodule // tms9919_sgc
