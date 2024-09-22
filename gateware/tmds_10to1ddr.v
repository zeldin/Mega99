module tmds_10to1ddr(input       clk_x5,
		     input [9:0] d,
		     output	 out_p,
		     output	 out_n);

   wire q;

   reg [9:0] shift_reg;
   reg [1:0] cnt = 2'b00;
   reg	     wrap = 1'b0;

   always @(posedge clk_x5) begin
      if (wrap) begin
	 shift_reg <= d;
	 cnt <= 2'b00;
      end else begin
	 shift_reg <= { 2'b00, shift_reg[9:2] };
	 cnt <= cnt + 1;
      end
      wrap <= &cnt;
   end

   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"))
   ddr(.C(clk_x5), .D1(shift_reg[0]), .D2(shift_reg[1]), .Q(q),
       .CE(1'b1), .R(1'b0), .S(1'b0));

   OBUFDS buf_ds(.I(q), .O(out_p), .OB(out_n));

endmodule // tmds_10to1ddr
