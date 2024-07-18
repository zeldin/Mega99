module tms5200_kstack(input	       clk,
		      input	       clk_en,
		      input [9:0]      kin,
		      output [9:0]     kout,
		      output reg [4:0] p1_stage,
		      output reg [4:0] m1_stage,
		      output reg [4:1] p2_stage,
		      output reg [4:0] m2_stage);

   wire [9:0] current;
   
   genvar i;
   generate
      for (i=0; i<10; i=i+1) begin : BITSTACK
	 reg [0:9] stack;
	 assign kout[i] = stack[9];
	 if (i < 4)
	   assign current[i] = kin[i];
	 else
	   assign current[i] = stack[(i-4)>>1];
	 always @(posedge clk)
	   if (clk_en) begin
	      stack <= { kin[i], stack[0:8] };
	   end
      end
   endgenerate

   always @(posedge clk)
     if (clk_en) begin
	m2_stage[0] <= current[1] & ~current[0]; // -2 stage 0
	p1_stage[0] <= current[0] & ~current[1]; // +1 stage 0
	m1_stage[0] <= current[0] & current[1];  // -1 stage 0
     end

   wire [1:4] c_in;
   reg [1:3]  c_out;

   always @(posedge clk)
     if (clk_en)
       c_out[1:3] <= c_in[1:3];

   generate
      for (i=1; i<=4; i=i+1) begin : RECODER
	 wire a, b, c;
	 if (i == 1)
	   assign a = current[1];
	 else
	   assign a = c_out[i-1];
	 assign b = current[2*i+0];
	 assign c = current[2*i+1];
	 assign c_in[i] = c;
	 always @(posedge clk)
	   if (clk_en) begin
	      p2_stage[i] <= a & b & ~c;   // +2 stage i
	      m2_stage[i] <= ~a & ~b & c;  // -2 stage i
	      p1_stage[i] <= (a ^ b) & ~c; // +1 stage i
	      m1_stage[i] <= (a ^ b) & c;  // -1 stage i
	   end
      end
   endgenerate
   
endmodule // tms5200_kstack
