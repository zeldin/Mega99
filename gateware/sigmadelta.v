module sigmadelta #(parameter audio_bits = 16)
   (input                    clk,
    input [(audio_bits-1):0] d,
    output reg		     q);

   reg [(audio_bits-1):0]    acc;
   reg [audio_bits:0]	     t;

   always @(posedge clk) begin
      t = { 1'b0, ~d[audio_bits-1], d[(audio_bits-2):0] } + { 1'b0, acc };
      acc = t[(audio_bits-1):0];
      q = t[audio_bits];
   end

endmodule // sigmadelta
