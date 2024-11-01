module icap_wrapper(input	       clk,
		    input [4:0]	      reg_num,
		    output reg [31:0] reg_value,
		    input	      trigger_read,
		    output	      busy);

   function automatic [7:0] bitswap8(input [7:0] x);
      begin
	 bitswap8 = { x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7] };
      end
   endfunction // bitswap8

   function automatic [31:0] bitswap32(input [31:0] x);
      begin
	 bitswap32 = { bitswap8(x[31:24]), bitswap8(x[23:16]),
		       bitswap8(x[15:8]), bitswap8(x[7:0]) };
      end
   endfunction // bitswap32

   wire [31:0] icap_out;
   reg [31:0]  icap_in;
   reg	       icap_csn = 1'b1;
   reg	       icap_rdwrn = 1'b1;
   reg	       icap_clk = 1'b0;
   reg [3:0]   counter = 4'd0;

   wire [31:0] cmd_sync;
   wire [31:0] cmd_nop;
   reg [31:0]  cmd_read_reg;

   assign busy = !(&counter);

   assign cmd_sync = 32'hAA995566;
   assign cmd_nop = 32'h20000000;

   always @(reg_num) begin
      cmd_read_reg = 32'h28000001;
      cmd_read_reg[17:13] = reg_num;
   end

   ICAPE2 #(.ICAP_WIDTH("X32"))
   icap(.CLK(icap_clk), .CSIB(icap_csn), .I(icap_in), .O(icap_out),
	.RDWRB(icap_rdwrn));

   always @(posedge clk) begin
      icap_csn <= 1'b1;
      icap_rdwrn <= 1'b1;
      icap_in <= ~(32'd0);
      icap_clk <= busy & ~icap_clk;

      if (busy && icap_clk) begin

	 icap_in <= bitswap32(cmd_nop);
	 case (counter)
	   4'd0, 4'd1: icap_in <= ~(32'd0);
	   4'd4: icap_in <= bitswap32(cmd_sync);
	   4'd7: icap_in <= bitswap32(cmd_read_reg);
	 endcase // case (counter)

	 if ((counter >= 4'd3 && counter <= 4'd7) ||
             (counter >= 4'd10 && counter <= 4'd13))
           icap_csn <= 1'b0;

	 if (counter >= 3 && counter <= 8)
           icap_rdwrn <= 1'b0;

	 if (counter == 4'd14)
           reg_value <= bitswap32(icap_out);

	 counter <= counter + 4'd1;

      end // if (busy)

      if (trigger_read)
	counter <= 4'd0;

   end // always @ (posedge clk)

endmodule // icap_wrapper
