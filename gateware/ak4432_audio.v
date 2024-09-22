/* Note: AK4432 defaults to mode 6, which is different from I2S:
   * LRCLK is high for L and low for R instead of the other way around
   * There is no one BCLK delay between LRCLK and sample start
   (AK4432 does support I2S but it has to be selected as e.g. mode 7.) */

module ak4432_audio
  #(parameter audio_bits = 16)
   (input			  ref_clk, // >= 1 MHz
    input [(audio_bits-1):0]	  pcm_in,  // synced to ref_clk
    input			  mclk,    // 12.288 MHz (fs * 256)
    output			  bclk,
    output			  sdata,
    output			  lrclk,
    output reg [(audio_bits-1):0] pcm_out, // synced to mclk
    output reg			  clken);  // new stable value in pcm_out

   reg [7:0]  cnt = 8'h80; // Start with LRCLK high
   reg [31:0] data;

   (* ASYNC_REG = "true" *) reg [4:0] lrclk_cdc;

   assign bclk = cnt[1];
   assign sdata = data[31];
   assign lrclk = cnt[7];

   always @(posedge ref_clk) begin
      // Latch incoming data on L->R switch, so that it is stable by
      // next sample (R->L switch).
      if (lrclk_cdc[4:2] == 3'b100) // 3'b011 for I2S
	pcm_out <= pcm_in;
      lrclk_cdc <= { lrclk_cdc[3:0], lrclk };
   end

   always @(posedge mclk) begin
      clken <= 1'b0;
      if (cnt[1:0] == 2'b11) begin
	 if (cnt == 8'h7f) begin // 8'h03 for I2S
	    data <= 32'h00000000;
	    data[31 -: audio_bits] <= pcm_out;
	    clken <= 1'b1;
	 end else
	   data <= { data[30:0], data[31] }; // L data is shifted back into R
      end
      cnt <= cnt + 8'h01;
   end

endmodule // ak4432_audio
