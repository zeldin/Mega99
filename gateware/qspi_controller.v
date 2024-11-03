module qspi_controller(input             clk,
		       input		 reset,
		       input [0:27]	 adr_i,
		       input		 stb_i,
		       input		 cyc_i,
		       input [0:3]	 sel_i,
		       input		 we_i,
		       input [0:31]	 dat_i,
		       output reg	 ack_o,
		       output reg [0:31] dat_o,

		       input [3:0]	 dq_in,
		       output [3:0]	 dq_out,
		       output reg [3:0]	 dq_oe,
		       output reg	 csn,
		       output reg	 sck);

   reg [0:2] state;
   reg [0:47] dq0_sr;

   assign dq_out = { 1'b1, 1'b1, 1'b0, dq0_sr[0] };

   always @(posedge clk)
     if (reset) begin
	state <= 3'b001;
	ack_o <= 1'b0;
	dq_oe <= 4'b0000;
	csn <= 1'b1;
	sck <= 1'b0;
	dq0_sr <= { 1'b1, 8'hff /* Mode bit reset */, 2'b01, 37'h0 };
     end else begin
	ack_o <= 1'b0;
	if (state != 3'b000) begin
	   if (sck)
	     dq0_sr <= { dq0_sr[1:47], 1'b0 };
	   sck <= ~sck;
	end
	case (state)
	  3'b000: if (stb_i && cyc_i && !ack_o) begin
	     if (we_i)
	       ack_o <= 1'b1;
	     else begin
		dq_oe <= 4'b1101;
		dq0_sr <= { 8'h6c /* Quad output read (4-byte address) */,
			    4'h0, adr_i[0:25], 2'b00, 8'hff };
		csn <= 1'b0;
		state <= 3'b001;
	     end
	  end
	  3'b001: begin
	     if (sck)
	       csn <= 1'b0;
	     if (sck && (dq0_sr[1:2] == 2'b01) && !(|dq0_sr[3:47]))
	       state <= 3'b011;
	     if (sck && (&dq0_sr[1:8]) && !(|dq0_sr[9:47]))
	       dq_oe <= 4'b0000;
	     if (sck && !(|dq0_sr[1:47])) begin
		dat_o <= 32'h00000008;
		state <= 3'b010;
	     end
	  end
	  3'b010: if (sck) begin
	     if (dat_o[0]) begin
		ack_o <= 1'b1;
		state <= 3'b011;
	     end
	     dat_o <= { dat_o[4:31], dq_in };
	  end
	  3'b011: begin
	     dq_oe <= 4'b0000;
	     csn <= 1'b1;
	     sck <= 1'b0;
	     state <= 3'b000;
	  end
	endcase // case (state)
     end

endmodule // qspi_controller
