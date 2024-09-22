module hyperram(input clk,
		input reset,

		// DDR PHY interface
		input pll_locked,
		output reg ck = 1'b0,
		input [1:0] rwds_in,
		output reg [1:0] rwds_out,
		input [15:0] dq_in,
		output reg [15:0] dq_out,
		output reg rwds_oe = 1'b0,
		output reg dq_oe = 1'b0,

		// Direct pin interface
		output reg cs_b = 1'b1,
		output reg ram_reset_b = 1'b0,

		// Bus interface
		input as,
		input we,
		input linear_burst,
		input [31:0] a,
		input [31:0] d,
		input [3:0] ds,
		output reg [31:0] q,

		input req,
		output reg ack = 1'b0);

   parameter CLK_HZ = 166000000;
   parameter DUAL_DIE = 0;
   parameter FIXED_LATENCY_ENABLE = 0;
   parameter INITIAL_LATENCY_OVERRIDE = 0;

   generate begin
      if (CLK_HZ > 166000000)
	initial $error("Clock exceeds 166 MHz");
      if (INITIAL_LATENCY_OVERRIDE &&
	  (INITIAL_LATENCY_OVERRIDE < 3 || INITIAL_LATENCY_OVERRIDE > 6))
	initial $error("Invalid initial latency override");
      if (DUAL_DIE && !FIXED_LATENCY_ENABLE)
	initial $error("Must use fixed latency for dual die part");
   end endgenerate

   localparam RESET_DELAY = CLK_HZ / 5000000 + 1;
   localparam MIN_INITIAL_LATENCY = (CLK_HZ <= 83000000? 3 :
				     (CLK_HZ <= 100000000? 4 :
				      (CLK_HZ <= 133000000? 5 : 6)));
   localparam INITIAL_LATENCY = (INITIAL_LATENCY_OVERRIDE?
				 INITIAL_LATENCY_OVERRIDE : MIN_INITIAL_LATENCY);
   localparam [3:0] IL_CODE = (INITIAL_LATENCY == 3? 4'b1110 :
			       (INITIAL_LATENCY == 4? 4'b1111 :
				(INITIAL_LATENCY == 5? 4'b0000 : 4'b0001)));
   localparam [0:0] FLE_CODE = (FIXED_LATENCY_ENABLE? 1'b1 : 1'b0);

   // Latencies of DDR phy
   localparam TX_LATENCY = 1;
   localparam RX_LATENCY = 1;

   localparam RWDS_SKEW = (RX_LATENCY > 2 ? RX_LATENCY-2 : 0);

   generate begin
      if (INITIAL_LATENCY_OVERRIDE && INITIAL_LATENCY_OVERRIDE < MIN_INITIAL_LATENCY)
	initial $error("Too low initial latency for this frequency set in override");
      if (INITIAL_LATENCY < 3 + RWDS_SKEW)
	initial $error("Initial latency too low for this RWDS_SKEW");
      if (!FIXED_LATENCY_ENABLE && INITIAL_LATENCY < 1 + 2 + TX_LATENCY )
	initial $error("Must enable fixed latency with this initial latency");
   end endgenerate


   reg [5:0] dlycnt = 6'h3f;
   reg [3:0] state = 4'b1100;
   reg [47:0] ca;
   reg [15:0] data;
   reg [3:0]  ds_int;

   always @(posedge clk)
     if (reset) begin
	ram_reset_b <= 1'b0;
	cs_b <= 1'b1;
	ck <= 1'b0;
	rwds_oe <= 1'b0;
	dq_oe <= 1'b0;
	rwds_out <= 2'b11;
	dq_out <= 16'h0000;
	state <= 4'b1100;
	dlycnt <= RESET_DELAY;
	ack <= 1'b0;
     end else if (dlycnt != 0)
       dlycnt <= dlycnt - 1;
     else if (~ram_reset_b) begin
	state <= 4'b0001;
	ca <= 48'h600001000000; // Write CR0
	data <= { 1'b1, 3'b000, 4'b1111,
		  IL_CODE[3:0], FLE_CODE[0], 1'b1, 2'b11 };
	dlycnt <= RESET_DELAY;
	if (pll_locked)
	   ram_reset_b <= 1'b1;
     end else begin
	state <= state + 1;
	case (state)
	  4'b0001: begin
	     cs_b <= 1'b0;
	     ck <= 1'b1;
	     dq_oe <= 1'b1;
	     dq_out <= ca[47:32];
	     rwds_out <= 2'b11;
	  end
	  4'b0010: dq_out <= ca[31:16];
	  4'b0011: dq_out <= ca[15:0];
	  4'b0100: begin
	     if (ca[47])
	       dq_out <= 16'h0000;
	     else begin
	        dq_out <= data;
                data <= d[15:0];
             end
             dq_oe <= 1'b0;
	     if (ca[47] == 1'b1) begin
		// Read operation
		dlycnt <= RWDS_SKEW;
		state <= 4'b1001;
	     end else if(ca[46] == 1'b1) begin
	       // Zero latency write to register
                dq_oe <= 1'b1;
	        state <= 4'b1000;
	     end else begin
		// Normal write
		dlycnt <= RWDS_SKEW;
	     end
	  end
	  4'b0101: begin
	     dlycnt <= (!FIXED_LATENCY_ENABLE && ~rwds_in[1]?
			INITIAL_LATENCY - 1 - 2 - RWDS_SKEW :
			2 * INITIAL_LATENCY - 1 - 2 - RWDS_SKEW);
	  end
	  4'b0110: begin
	     rwds_out <= ~ds_int[3:2];
	     rwds_oe <= 1'b1;
	     dq_oe <= 1'b1;
	  end
	  4'b0111: begin
	     rwds_out <= ~ds_int[1:0];
             dq_out <= data;
	  end
	  4'b1000: begin
	     ck <= 1'b0;
	     dq_oe <= 1'b0;
	     rwds_out <= 2'b11;
             rwds_oe <= 1'b0;
	     dlycnt <= TX_LATENCY;
	     state <= 4'b1100;
	  end
      	  4'b1001: begin
	     dlycnt <= (!FIXED_LATENCY_ENABLE && ~rwds_in[0]?
			INITIAL_LATENCY - 2 + TX_LATENCY + RX_LATENCY - RWDS_SKEW :
                        2 * INITIAL_LATENCY - 2 + TX_LATENCY + RX_LATENCY - RWDS_SKEW);
	  end
	  4'b1010: if (~rwds_in[1])
	    state <= 4'b1010; /* Wait for read ack from RAM */
	  else begin
             if (TX_LATENCY > 0 || RX_LATENCY > 0)
	       ck <= 1'b0;
	     q[31:16] <= dq_in;
	  end
          4'b1011: begin
	     ck <= 1'b0;
	     dlycnt <= TX_LATENCY;
	     q[15:0] <= dq_in;
          end
	  4'b1100: begin
	     cs_b <= 1'b1;
	     ack <= req;
	  end
	  4'b1101: begin
	     state <= 4'b1101;
	     if (DUAL_DIE && ca[47:46] == 2'b01 && ca[35] == 0) begin
		/* Repeat config for second die */
		ca[35] <= 1'b1;
		state <= 4'b0001;
	     end else if (req != ack) begin
		ca <= {~we, as, linear_burst | (as & we),
		       a[31:3], {13{1'b0}}, a[2:0]};
		data <= d[31:16];
		ds_int <= ds;
		state <= 4'b0001;
	     end
	  end
	  default: state <= 4'b1100;
	endcase // case (state)

     end

endmodule // hyperram
