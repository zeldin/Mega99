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
	      output [0:6]	sw_enable,
	      output [0:3]	sw_dip,
	      output [0:23]	led1_rgb,
	      output [0:23]	led2_rgb,
	      output [0:23]	led3_rgb,
	      output [0:23]	led4_rgb,
	      input		cpu_turbo,
	      input [1:3]	drive_activity,
	      input		overlay_clk_en,
	      input		overlay_vsync,
	      input		overlay_hsync,
	      output [0:3]	overlay_color,

	      input		keypress,
	      input		keypress_isup,
	      input [0:6]	keycode,
	      input [0:3]	shift_state,
	      output		keyboard_block,
	      output [0:47]	synth_key_state,
	      output		synth_keys_enabled,

	      input		clk_3mhz_en,
	      output [0:15]	tape_audio,
	      input		cs1_cntrl,
	      input		cs2_cntrl,
	      input		mag_out,

	      output		sdcard_select,
	      output		sdcard_cs,
	      input [0:1]	sdcard_cd,
	      input [0:1]	sdcard_wp,
	      output		sdcard_sck,
	      input		sdcard_miso,
	      output		sdcard_mosi,

	      output		uart_txd,
	      input		uart_rxd,

	      input		tipi_enable,
	      output		tipi_clk,
	      output		tipi_rt,
	      output		tipi_le,
	      input		tipi_reset,
	      output		tipi_dout,
	      input		tipi_din,
	      output		tipi_dc);

   parameter keyboard_model = 0;
   parameter num_sdcard = 1;

   reg	       stb_misc;
   reg	       stb_sdcard;
   reg	       stb_uart;
   reg	       stb_overlay;
   reg	       stb_kbd;
   reg	       stb_tape;
   reg	       stb_tipi;
   wire        ack_overlay;
   wire [0:31] dat_misc;
   wire [0:31] dat_sdcard;
   wire [0:31] dat_uart;
   wire [0:31] dat_overlay;
   wire [0:31] dat_kbd;
   wire [0:31] dat_tape;
   wire [0:31] dat_tipi;

   always @(*) begin
      ack_o <= stb_i;
      dat_o <= 32'h00000000;

      stb_misc <= 1'b0;
      stb_sdcard <= 1'b0;
      stb_uart <= 1'b0;
      stb_overlay <= 1'b0;
      stb_kbd <= 1'b0;
      stb_tape <= 1'b0;
      stb_tipi <= 1'b0;
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
	8'h06: begin
	   stb_tipi <= stb_i;
	   dat_o <= dat_tipi;
	end
	default: ;
      endcase // case (adr_i[0 +: 8])
   end

   spmmio_misc misc(.clk(clk), .reset(reset),
		    .adr(adr_i[21 -: 4]), .cs(cyc_i && stb_misc),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_misc),

		    .led_red(led_red), .led_green(led_green),
		    .sw_reset(sw_reset), .sw_enable(sw_enable), .sw_dip(sw_dip),
		    .led1_rgb(led1_rgb), .led2_rgb(led2_rgb),
		    .led3_rgb(led3_rgb), .led4_rgb(led4_rgb),
		    .cpu_turbo(cpu_turbo), .drive_activity(drive_activity));

   spmmio_sdcard #(.num_sdcard(num_sdcard))
   sdcard(.clk(clk), .reset(reset),
	  .adr(adr_i[21 -: 4]), .cs(cyc_i && stb_sdcard),
	  .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_sdcard),

	  .sdcard_select(sdcard_select), .sdcard_cs(sdcard_cs),
	  .sdcard_cd(sdcard_cd), .sdcard_wp(sdcard_wp),.sdcard_sck(sdcard_sck),
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

   spmmio_keyboard #(.keyboard_model(keyboard_model))
   keyboard(.clk(clk), .reset(reset),
	    .adr(adr_i[21 -: 3]), .cs(cyc_i && stb_kbd),
	    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_kbd),

	    .keypress(keypress), .isup(keypress_isup), .keycode(keycode),
	    .shift_state(shift_state),
	    .keyboard_block(keyboard_block),
	    .synth_key_state(synth_key_state),
	    .synth_keys_enabled(synth_keys_enabled));

   spmmio_tape tape(.clk(clk), .reset(reset), .clk_3mhz_en(clk_3mhz_en),
		    .adr(adr_i[21 -: 14]), .cs(cyc_i && stb_tape),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_tape),
		    .tape_audio(tape_audio), .cs1_cntrl(cs1_cntrl),
		    .cs2_cntrl(cs2_cntrl), .mag_out(mag_out));

   spmmio_tipi tipi(.clk(clk), .reset(reset), .clk_3mhz_en(clk_3mhz_en),
		    .adr(adr_i[21 -: 4]), .cs(cyc_i && stb_tipi),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_tipi),
		    .enable(tipi_enable), .tclk(tipi_clk),
		    .rt(tipi_rt), .le(tipi_le), .treset(tipi_reset),
		    .dout(tipi_dout), .din(tipi_din), .dc(tipi_dc));

endmodule // spmmio
