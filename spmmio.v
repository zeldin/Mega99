module spmmio(input             clk,
	      input		reset,

	      input [0:23]	adr_i, // 21 is last significant bit
	      input		stb_i,
	      input		cyc_i,
	      input [0:3]	sel_i,
	      input		we_i,
	      input [0:31]	dat_i,
	      output reg	ack_o,
	      output reg [0:31]	dat_o,

	      output		led_red,
	      output		led_green,
	      output [0:3]	sw_reset,

	      output		sdcard_cs,
	      input		sdcard_cd,
	      input		sdcard_wp,
	      output		sdcard_sck,
	      input		sdcard_miso,
	      output		sdcard_mosi);

   reg	       stb_misc;
   reg	       stb_sdcard;
   wire [0:31] dat_misc;
   wire [0:31] dat_sdcard;

   always @(*) begin
      ack_o <= stb_i;
      dat_o <= 32'h00000000;

      stb_misc <= 1'b0;
      stb_sdcard <= 1'b0;
      case (adr_i[0 +: 8])
	8'h00: begin
	   stb_misc <= stb_i;
	   dat_o <= dat_misc;
	end
	8'h01: begin
	   stb_sdcard <= stb_i;
	   dat_o <= dat_sdcard;
	end
	default: ;
      endcase // case (adr_i[0 +: 8])
   end

   spmmio_misc misc(.clk(clk), .reset(reset),
		    .adr(adr_i[21 -: 4]), .cs(cyc_i && stb_misc),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_misc),

		    .led_red(led_red), .led_green(led_green),
		    .sw_reset(sw_reset));

   spmmio_sdcard sdcard(.clk(clk), .reset(reset),
			.adr(adr_i[21 -: 4]), .cs(cyc_i && stb_sdcard),
			.sel(sel_i), .we(we_i), .d(dat_i), .q(dat_sdcard),

			.sdcard_cs(sdcard_cs), .sdcard_cd(sdcard_cd),
			.sdcard_wp(sdcard_wp),.sdcard_sck(sdcard_sck),
			.sdcard_miso(sdcard_miso), .sdcard_mosi(sdcard_mosi));

endmodule // spmmio
