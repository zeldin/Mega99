module spmmio_uart(input             clk,
		   input	     reset,

		   input [0:2]	     adr,
		   input	     cs,
		   input [0:3]	     sel,
		   input	     we,
		   input [0:31]	     d,
		   output reg [0:31] q,

		   output	     uart_txd,
		   input	     uart_rxd);

   reg [0:15] baudrate;
   reg [0:15] txcnt;
   reg [0:15] rxcnt;

   reg [0:9] txshift;
   reg	     txactive;
   reg [0:8] rxshift;
   reg	     rxactive;
   reg	     rxvalid;
   
   assign uart_txd = txshift[9];

   always @(posedge clk)
     if (reset) begin
	baudrate <= 16'hffff;
	txshift <= 10'b0000000001;
	txactive <= 1'b0;
	rxshift <= 9'b111111111;
	rxactive <= 1'b0;
	rxvalid <= 1'b0;
     end else begin
	if (txactive) begin
	   if (|txcnt)
	     txcnt <= txcnt - 1;
	   else begin
	      txcnt <= baudrate;
	      if (txshift == 10'b0000000001)
		txactive <= 1'b0;
	      else
		txshift <= { 1'b0, txshift[0:8] };
	   end
	end

	if (rxactive) begin
	   if (|rxcnt)
	     rxcnt <= rxcnt - 1;
	   else begin
	      rxcnt <= baudrate;
	      if (!rxshift[8]) begin
		 if (uart_rxd) // Check stop bit
		   rxvalid <= 1'b1;
		 rxactive <= 1'b0;
	      end
	      rxshift <= { uart_rxd, rxshift[0:7] };
	   end
	   if (uart_rxd && !(|(~rxshift)))
	     rxactive <= 1'b0;  // Bad start bit
	end else if(!rxvalid && !uart_rxd) begin
	   rxshift <= 9'b111111111;
	   rxcnt <= { 1'b0, baudrate[0:14] }; // half a bitlength
	   rxactive <= 1'b1;
	end

	if (cs && we && sel[0])
	  case (adr)
	    3'h0: baudrate[0:7] <= d[0:7];
	  endcase // case (adr)

	if (cs && we && sel[1])
	  case (adr)
	    3'h0: baudrate[8:15] <= d[8:15];
	  endcase // case (adr)

	if (cs && we && sel[3])
	  case (adr)
	    3'h0:
	      if (!txactive) begin
		 txshift <= { 1'b1, d[24:31], 1'b0 };
		 txcnt <= baudrate;
		 txactive <= 1'b1;
	      end
	  endcase // case (adr)

	if (cs && !we)
	  case (adr)
	    3'h1: rxvalid <= 1'b0;
	  endcase // case (adr)
     end

   always @(*) begin
      q <= 32'h00000000;
      case (adr)
	4'h0: begin
	   q[0:15] <= baudrate;
	   q[22] <= rxvalid;
	   q[23] <= ~txactive;
	end
	4'h1: begin
	   q[0:7] <= rxshift[1:8];
	end
	default: ;
      endcase // case (adr)
   end

endmodule // spmmio_uart
