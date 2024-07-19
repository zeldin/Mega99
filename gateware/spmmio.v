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
	      output [0:4]	sw_reset,
	      input		overlay_clk_en,
	      input		overlay_vsync,
	      input		overlay_hsync,
	      output [0:3]	overlay_color,

	      input		keypress,
	      input [0:6]	keycode,
	      input [0:3]	shift_state,
	      output		keyboard_block,

	      input		clk_3mhz_en,
	      output [0:15]	tape_audio,
	      input		cs1_cntrl,

	      output		sdcard_cs,
	      input		sdcard_cd,
	      input		sdcard_wp,
	      output		sdcard_sck,
	      input		sdcard_miso,
	      output		sdcard_mosi,

	      output		uart_txd,
	      input		uart_rxd);

   reg	       stb_misc;
   reg	       stb_sdcard;
   reg	       stb_uart;
   reg	       stb_overlay;
   reg	       stb_kbd;
   reg	       stb_tape;
   wire        ack_overlay;
   wire [0:31] dat_misc;
   wire [0:31] dat_sdcard;
   wire [0:31] dat_uart;
   wire [0:31] dat_overlay;
   wire [0:31] dat_kbd;
   wire [0:31] dat_tape;

   always @(*) begin
      ack_o <= stb_i;
      dat_o <= 32'h00000000;

      stb_misc <= 1'b0;
      stb_sdcard <= 1'b0;
      stb_uart <= 1'b0;
      stb_overlay <= 1'b0;
      stb_kbd <= 1'b0;
      stb_tape <= 1'b0;
      case (adr_i[0 +: 8])
	8'h00: begin
	   stb_misc <= stb_i;
	   dat_o <= dat_misc;
	end
	8'h01: begin
	   stb_sdcard <= stb_i;
	   dat_o <= dat_sdcard;
	end
	8'h02: begin
	   stb_uart <= stb_i;
	   dat_o <= dat_uart;
	end
	8'h03: begin
	   stb_overlay <= stb_i;
	   ack_o <= ack_overlay;
	   dat_o <= dat_overlay;
	end
	8'h04: begin
	   stb_kbd <= stb_i;
	   dat_o <= dat_kbd;
	end
	8'h05: begin
	   stb_tape <= stb_i;
	   dat_o <= dat_tape;
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

   spmmio_uart uart(.clk(clk), .reset(reset),
		    .adr(adr_i[21 -: 3]), .cs(cyc_i && stb_uart),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_uart),

		    .uart_txd(uart_txd), .uart_rxd(uart_rxd));

   spmmio_overlay overlay(.clk(clk), .reset(reset),
			  .adr(adr_i[21 -: 13]), .cs(cyc_i && stb_overlay),
			  .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_overlay),
			  .ack(ack_overlay),

			  .pixel_clock(overlay_clk_en),
			  .vsync(overlay_vsync), .hsync(overlay_hsync),
			  .color(overlay_color));

   spmmio_keyboard keyboard(.clk(clk), .reset(reset),
			    .adr(adr_i[21 -: 3]), .cs(cyc_i && stb_kbd),
			    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_kbd),

			    .keypress(keypress), .keycode(keycode),
			    .shift_state(shift_state),
			    .keyboard_block(keyboard_block));

   spmmio_tape tape(.clk(clk), .reset(reset), .clk_3mhz_en(clk_3mhz_en),
		    .adr(adr_i[21 -: 14]), .cs(cyc_i && stb_tape),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_tape),

		    .tape_audio(tape_audio), .cs1_cntrl(cs1_cntrl));

endmodule // spmmio
