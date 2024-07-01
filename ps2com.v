module ps2com #(parameter integer clock_filter = 10)
   (input        clk,
    input	 reset,
    input	 ps2_clk_in,
    input	 ps2_dat_in,
    output reg   recv_trigger,
    output [7:0] recv_byte);

   reg [1:0]  com_state = 2'b00;
   reg	      clk_reg = 1'b1;
   reg [5:0]  clk_filter_cnt;
   reg	      current_bit;
   reg [3:0]  bit_count;
   reg [10:0] recv_byte_loc;

   assign recv_byte = recv_byte_loc[8:1];

   always @(posedge clk) begin
      clk_reg <= ps2_clk_in;
      if (clk_reg != ps2_clk_in)
	clk_filter_cnt <= clock_filter;
      else if (clk_filter_cnt != 0)
	clk_filter_cnt <= clk_filter_cnt - 1;
   end

   always @(posedge clk) begin

      recv_trigger <= 1'b0;

      case (com_state)
	2'b00: begin
	   bit_count <= 4'd0;
	   if (clk_reg == 1'b0 && !(|clk_filter_cnt))
	     com_state <= 2'b01;
	end
	2'b01: if (clk_reg == 1'b0 && !(|clk_filter_cnt)) begin
	   recv_byte_loc <= { ps2_dat_in, recv_byte_loc[10:1] };
	   bit_count <= bit_count + 1;
	   com_state <= 2'b10;
	end
	2'b10: if (clk_reg == 1'b1 && !(|clk_filter_cnt)) begin
	   com_state <= 2'b01;
	   if (bit_count == 4'd11) begin
	      recv_trigger <= 1'b1;
	      com_state <= 2'b00;
	   end
	end
      endcase // case (com_state)

      if (reset)
	com_state <= 2'b00;

   end // always @ (posedge clk)

endmodule // ps2com
