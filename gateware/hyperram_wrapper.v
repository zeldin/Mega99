module hyperram_wrapper(input         clk,
			input	      clk_phi90,
			input	      reset,
			input	      pll_locked,

			output	      ck,
			inout	      rwds,
			inout [7:0]   dq,
			output	      cs_b,
			output	      ram_reset_b,

			input [2:31]  adr_i,
			input [0:31]  dat_i,
			output [0:31] dat_o,
			input	      we_i,
			input [0:3]   sel_i,
		        input	      stb_i,
			output reg    ack_o,
			input	      cyc_i);

   parameter CLK_HZ = 100000000;
   parameter DUAL_DIE = 0;
   parameter FIXED_LATENCY_ENABLE = 0;
   parameter INITIAL_LATENCY_OVERRIDE = 0;

   wire	       ce;
   wire [1:0]  rwds_in, rwds_out;
   wire [15:0] dq_in, dq_out;
   wire	       rwds_oe, dq_oe;

   wire	hr_ack;
   reg	hr_req = 1'b0;
   reg	hr_pending = 1'b0;

   artix7_hyperphy hrphy(.clk(clk), .clk_phi90(clk_phi90),
			 .reset(reset), .clk_enable(ce),
			 .rwds_da(rwds_out[1]), .rwds_db(rwds_out[0]),
			 .rwds_qa(rwds_in[1]), .rwds_qb(rwds_in[0]),
			 .dq_da(dq_out[15:8]), .dq_db(dq_out[7:0]),
			 .dq_qa(dq_in[15:8]), .dq_qb(dq_in[7:0]),
			 .rwds_oe(rwds_oe), .dq_oe(dq_oe),
			 .ck(ck), .rwds(rwds), .dq(dq));

   hyperram #(.CLK_HZ(CLK_HZ), .DUAL_DIE(DUAL_DIE),
              .FIXED_LATENCY_ENABLE(FIXED_LATENCY_ENABLE),
              .INITIAL_LATENCY_OVERRIDE(INITIAL_LATENCY_OVERRIDE))
   hr(.clk(clk), .reset(reset), .pll_locked(pll_locked), .ck(ce),
      .rwds_in(rwds_in), .rwds_out(rwds_out), .dq_in(dq_in), .dq_out(dq_out),
      .rwds_oe(rwds_oe), .dq_oe(dq_oe), .cs_b(cs_b), .ram_reset_b(ram_reset_b),

      .as(1'b0), .we(we_i), .linear_burst(1'b1),
      .a({3'b000, adr_i[2:30]}), .d(dat_i), .ds(sel_i),
      .q(dat_o), .req(hr_req), .ack(hr_ack));

   always @(posedge clk) begin
      if (ack_o)
	ack_o <= 1'b0;
      else if (stb_i && cyc_i) begin
	 if (!hr_pending) begin
	    hr_pending <= 1'b1;
	    hr_req <= ~hr_req;
	 end else if (hr_ack == hr_req) begin
	    ack_o <= 1'b1;
	    hr_pending <= 1'b0;
	 end
      end
   end

endmodule // hyperram_wrapper
