module tms5200_prom(input            clk,
		    input	     clk_en,
		    input [9:0]	     addr,
		    input	     output_transfer,
		    output reg [9:0] out);

   reg [9:0] data [0:271];

   reg [6:0] ydecode;
   reg [1:0] xdecode;

   initial $readmemh("tms5200_parameter_rom.hex", data);

   always @(posedge clk)
     if (clk_en) begin

	if (output_transfer)
	  out <= data[{ ydecode, xdecode }];
	   
	xdecode <= addr[1:0];
	ydecode <= 7'd0;
	case (addr[9:6])
	  4'd0: ydecode <= 7'd0 + addr[3:2]; // E
	  4'd1: ydecode <= 7'd4 + addr[5:2]; // P
	  4'd2: // K1
	    if (addr[5])
	      ydecode <= (addr[4:2] == 3'b000 ? 7'd20 : 7'd0);
	    else
	      ydecode <= 7'd21 + addr[4:2];
	  4'd3: // K2
	    if (addr[5])
	      ydecode <= (addr[4:2] == 3'b000 ? 7'd29 : 7'd0);
	    else
	      ydecode <= 7'd30 + addr[4:2];
	  4'd4: // K3
	    if (addr[4])
	      ydecode <= (addr[3:2] == 2'b00 ? 7'd38 : 7'd0);
	    else
	      ydecode <= 7'd39 + addr[3:2];
	  4'd5: // K4
	    if (addr[4])
	      ydecode <= (addr[3:2] == 2'b00 ? 7'd43 : 7'd0);
	    else
	      ydecode <= 7'd44 + addr[3:2];
	  4'd6: // K5
	    if (addr[4])
	      ydecode <= (addr[3:2] == 2'b00 ? 7'd48 : 7'd0);
	    else
	      ydecode <= 7'd49 + addr[3:2];
	  4'd7: // K6
	    if (addr[4])
	      ydecode <= (addr[3:2] == 2'b00 ? 7'd53 : 7'd0);
	    else
	      ydecode <= 7'd54 + addr[3:2];
	  4'd8: ydecode <= 7'd58 + addr[3:2]; // K7
	  4'd9: ydecode <= 7'd62 + addr[2:2]; // K8
	  4'd10: ydecode <= 7'd64 + addr[2:2]; // K9
	  4'd11: ydecode <= 7'd66 + addr[2:2]; // K10
	  default: ydecode <= 7'd0;
	endcase // case (addr[9:6])
     end
   
endmodule // tms5200_prom
