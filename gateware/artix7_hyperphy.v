module artix7_hyperphy(input        clk,
		       input	    clk_phi90,
		       input	    reset,
		       input	    clk_enable,

		       input	    rwds_da,
		       input	    rwds_db,
		       output	    rwds_qa,
		       output	    rwds_qb,
		       input [7:0]  dq_da,
		       input [7:0]  dq_db,
		       output [7:0] dq_qa,
		       output [7:0] dq_qb,
		       input	    rwds_oe,
		       input	    dq_oe,

		       output	    ck,
		       inout	    rwds,
		       inout [7:0]  dq);

   wire [8:0] pins;
   wire [8:0] oe;
   wire [8:0] rx_q0;
   wire [8:0] rx_q1;
   wire [8:0] tx_d0;
   wire [8:0] tx_d1;

   assign pins = { rwds, dq };
   assign oe = { rwds_oe, {8{dq_oe}} };
   assign rwds_qa = rx_q0[8];
   assign rwds_qb = rx_q1[8];
   assign dq_qa = rx_q0[7:0];
   assign dq_qb = rx_q1[7:0];
   assign tx_d0 = { rwds_da, dq_da };
   assign tx_d1 = { rwds_db, dq_db };

   reg clk_enable_dly;
   reg reset_phi90;

   always @(posedge clk_phi90) begin
      clk_enable_dly <= clk_enable;
      reset_phi90 <= reset;
   end

   // Clock output is delayed 90 degrees to convert TX aligned and RX
   // centered into TX centered and RX aligned from the perspective of
   // the external slave

   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"))
   clk_output(.C(clk_phi90), .D1(clk_enable_dly), .D2(1'b0), .Q(ck),
	      .CE(1'b1), .R(reset_phi90), .S(1'b0));

   genvar i;
   generate
      for (i=0; i<9; i=i+1)
        begin : DDR

           wire d, q;
           reg t;
           
           always @(posedge clk)
              t <= ~oe[i];           

           IOBUF bidir(.I(q), .T(t), .O(d), .IO(pins[i]));

	   IDDR #(.DDR_CLK_EDGE("SAME_EDGE"))
           rx(.C(clk), .D(d), .Q1(rx_q1[i]), .Q2(rx_q0[i]),
	      .CE(1'b1), .R(reset), .S(1'b0));

	   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"))
           tx(.C(clk), .D1(tx_d0[i]), .D2(tx_d1[i]), .Q(q),
	      .CE(1'b1), .R(reset), .S(1'b0));

        end
   endgenerate

endmodule // artix7_hyperphy
