module tms5200_multiplier(input	            clk,
			  input		    clk_en,
			  input [4:0]	    p1_stage,
			  input [4:0]	    m1_stage,
			  input [4:1]	    p2_stage,
			  input [4:0]	    m2_stage,
			  input [13:0]	    mr,
			  output reg [13:0] p);

   // Stage 0

   wire [14:2] stage0_sigma;
   assign stage0_sigma = ({13{m2_stage[0]}} & {~mr[13:1]}) |
			 ({13{m1_stage[0]}} & {~mr[13], ~mr[13:2]}) |
			 ({13{p1_stage[0]}} & {mr[13], mr[13:2]});

   // Stage 1-4

   reg [14:0]  mr_out [1:3];
   genvar i;
   generate
      for (i=1; i<=4; i=i+1) begin : STAGE
	 wire [14:0] mr_in;
	 wire [14:0] sigma_in;
	 wire [14:0] addend;
	 wire	     carry_in;
	 reg [14:0]  sigma_out;
	 if (i == 1) begin
	    assign mr_in = { mr[13], mr[13:0] };
	    assign sigma_in = { stage0_sigma[14], stage0_sigma[14],
				stage0_sigma[14:2] };
	 end else begin
	    assign mr_in = mr_out[i-1];
	    assign sigma_in = { STAGE[i-1].sigma_out[14],
				STAGE[i-1].sigma_out[14],
				STAGE[i-1].sigma_out[14:2] };
	 end
	 assign addend = ({15{p1_stage[i]}} & mr_in) |
			 ({15{m1_stage[i]}} & ~mr_in) |
			 ({15{p2_stage[i]}} & {mr_in[13:0], 1'b0}) |
			 ({15{m2_stage[i]}} & {~mr_in[13:0], 1'b1});
	 assign carry_in = m1_stage[i] | m2_stage[i];
	 always @(posedge clk)
	   if (clk_en) begin
	      if (i < 4)
		mr_out[i] <= mr_in;
	      sigma_out <= sigma_in + addend + carry_in;
	   end
      end // block: STAGE
   endgenerate
   
   // Delay stage

   reg [14:2] delay1;
   reg [14:2] delay2;
   reg [14:2] delay3;
   always @(posedge clk)
     if (clk_en) begin
	delay1 <= STAGE[4].sigma_out[14:2];
	delay2 <= delay1;
	delay3 <= delay2;
	p <= { delay3, 1'b0 };
     end

endmodule // tms5200_multiplier
