module mega99_nexys_a7_top(input         CLK100MHZ,

			   output [3:0]	 VGA_R,
			   output [3:0]	 VGA_G,
			   output [3:0]	 VGA_B,
			   output	 VGA_HS,
			   output	 VGA_VS,

			   output	 LED16_G,
			   output	 LED17_R,

			   output	 SD_RESET,
			   input	 SD_CD,
			   output	 SD_SCK,
			   output	 SD_CMD,
			   inout [3:0]	 SD_DAT,

			   input	 PS2_CLK,
			   input	 PS2_DATA,

			   inout	 AUD_PWM,
			   output	 AUD_SD,

			   input	 UART_RXD,
			   output	 UART_TXD,

			   input [1:4]	 JAlo,
			   input [8:8]	 JAhi,
			   input [1:4]	 JBlo,
			   input [8:8]	 JBhi,
		     
			   inout [15:0]	 ddr2_dq,
			   inout [1:0]	 ddr2_dqs_n,
			   inout [1:0]	 ddr2_dqs_p,
			   output [12:0] ddr2_addr,
			   output [2:0]	 ddr2_ba,
			   output	 ddr2_ras_n,
			   output	 ddr2_cas_n,
			   output	 ddr2_we_n,
			   output	 ddr2_ck_p,
			   output	 ddr2_ck_n,
			   output	 ddr2_cke,
			   output	 ddr2_cs_n,
			   output [1:0]	 ddr2_dm,
			   output	 ddr2_odt);

   wire        clk;
   wire	       clk_mem;
   wire	       clk_ref;
   wire	       clk_locked;
   wire	       reset;
   
   wire [2:31] xmem_adr_o;
   wire [0:31] xmem_dat_o;
   wire [0:31] xmem_dat_i;
   wire	       xmem_we_o;
   wire [0:3]  xmem_sel_o;
   wire	       xmem_stb_o;
   wire	       xmem_ack_i;
   wire	       xmem_cyc_o;

   wire	       sdcard_cs;

   wire [7:0]  kbd_scancode;
   wire	       kbd_trigger;

   wire [0:15] audio_in;
   wire [15:0] audio_out;
   wire	       audio_sd;
   
   wire	       vdp_clk_en;
   wire	       vga_clk_en;
   wire	       overlay_clk_en;
   wire	       clk_3mhz_en;

   wire	       vdp_hsync;
   wire	       vdp_vsync;
   wire	       vdp_cburst;
   wire [0:3]  vdp_color;
   wire	       vdp_color_en;

   wire	       vga_hsync;
   wire [0:3]  vga_color;
   wire [0:3]  overlay_color;

   wire [0:15] debug_pc;
   wire [0:15] debug_st;
   wire [0:15] debug_wp;
   wire [0:15] debug_ir;
   wire [0:13] debug_vdp_addr;
   wire [0:15] debug_grom_addr;

   wire	       cpu_turbo;
   wire [0:47] key_state;
   wire	       alpha_state;
   wire	       keypress;
   wire [0:6]  keycode;
   wire [0:3]  shift_state;
   wire	       keyboard_block;

   wire	       cs1_cntrl;
   wire	       cs2_cntrl;
   wire	       mag_out;

   wire [0:23] sp_adr_o;
   wire [0:7]  sp_dat_o;
   wire [0:7]  sp_dat_i;
   wire	       sp_we_o;
   wire [0:0]  sp_sel_o;
   wire	       sp_stb_o;
   wire	       sp_ack_i;
   wire	       sp_cyc_o;

   wire	       reset_9900;
   wire	       reset_9901;
   wire	       reset_9918;
   wire	       reset_9919;
   wire	       reset_5200;

   wire	       tp_valid;
   wire [0:31] tp_pc;
   wire [0:31] tp_insn;


   assign VGA_HS = ~vga_hsync;
   assign VGA_VS = ~vdp_vsync;

   assign AUD_PWM = (audio_sd ? 1'bz : 1'b0);
   assign AUD_SD = 1'b1;

   assign SD_RESET = 1'b0;
   assign SD_DAT[3] = ~sdcard_cs;


   nexys_a7_clkwiz clkgen(.clk_mem(clk_mem), .clk_sys(clk), .clk_ref(clk_ref),
			  .locked(clk_locked), .clk_in1(CLK100MHZ));

   nexys_a7_mig_wrapper mig(.clk_mem(clk_mem), .clk_ref(clk_ref), .rst_n(~reset),

			    .ddr2_dq(ddr2_dq),
			    .ddr2_dqs_n(ddr2_dqs_n), .ddr2_dqs_p(ddr2_dqs_p),
			    .ddr2_addr(ddr2_addr), .ddr2_ba(ddr2_ba),
			    .ddr2_ras_n(ddr2_ras_n), .ddr2_cas_n(ddr2_cas_n),
			    .ddr2_we_n(ddr2_we_n),
			    .ddr2_ck_p(ddr2_ck_p), .ddr2_ck_n(ddr2_ck_n),
			    .ddr2_cke(ddr2_cke), .ddr2_cs_n(ddr2_cs_n),
			    .ddr2_dm(ddr2_dm), .ddr2_odt(ddr2_odt),

			    .cpu_clk(clk),
			    .wb_adr_i(xmem_adr_o),
			    .wb_dat_i(xmem_dat_o),
			    .wb_dat_o(xmem_dat_i),
			    .wb_we_i(xmem_we_o),
			    .wb_sel_i(xmem_sel_o),
			    .wb_stb_i(xmem_stb_o),
			    .wb_ack_o(xmem_ack_i),
			    .wb_cyc_i(xmem_cyc_o));

   ps2com #(.clock_filter(24))
   kbdcom(.clk(clk), .reset(reset),
	  .ps2_clk_in(PS2_CLK), .ps2_dat_in(PS2_DATA),
	  .recv_trigger(kbd_trigger), .recv_byte(kbd_scancode));

   keyboard_ps2 keyboard(.clk(clk), .reset(reset),
			 .scancode(kbd_scancode), .trigger(kbd_trigger),
			 .key_state(key_state), .alpha_state(alpha_state),
			 .turbo_state(cpu_turbo),
			 .keypress(keypress), .keycode(keycode),
			 .shift_state(shift_state),
			 .keyboard_block(keyboard_block));

   sigmadelta #(.audio_bits(10))
   sd_dac(.clk(clk), .d(audio_out[15 -: 10]), .q(audio_sd));

   sp service_processor(.clk(clk), .reset(reset),
			.wb_adr_o(sp_adr_o), .wb_dat_o(sp_dat_o),
			.wb_dat_i(sp_dat_i), .wb_we_o(sp_we_o),
			.wb_sel_o(sp_sel_o), .wb_stb_o(sp_stb_o),
			.wb_ack_i(sp_ack_i), .wb_cyc_o(sp_cyc_o),

			.xmem_adr_o(xmem_adr_o), .xmem_dat_o(xmem_dat_o),
			.xmem_dat_i(xmem_dat_i), .xmem_we_o(xmem_we_o),
			.xmem_sel_o(xmem_sel_o), .xmem_stb_o(xmem_stb_o),
			.xmem_ack_i(xmem_ack_i), .xmem_cyc_o(xmem_cyc_o),

			.tp_valid(tp_valid), .tp_pc(tp_pc), .tp_insn(tp_insn),

			.led_green(LED16_G), .led_red(LED17_R),
			.sw_reset({reset_9900, reset_9901,
				   reset_9918, reset_9919, reset_5200}),
			.overlay_clk_en(overlay_clk_en), .overlay_vsync(vdp_vsync),
			.overlay_hsync(vga_hsync), .overlay_color(overlay_color),
			.keypress(keypress), .keycode(keycode),
			.shift_state({shift_state[0:1], alpha_state,
				      (|shift_state[2:3])}),
			.keyboard_block(keyboard_block),
			.clk_3mhz_en(clk_3mhz_en), .tape_audio(audio_in),
			.cs1_cntrl(cs1_cntrl), .cs2_cntrl(cs2_cntrl),
			.mag_out(mag_out),
			.sdcard_cs(sdcard_cs), .sdcard_cd(~SD_CD),
			.sdcard_wp(1'b0), .sdcard_sck(SD_SCK),
			.sdcard_miso(SD_DAT[0]), .sdcard_mosi(SD_CMD),
			.uart_txd(UART_TXD), .uart_rxd(UART_RXD));

   mainboard #(.vdp_clk_multiplier(10),  .cpu_clk_multiplier(36),
	       .vsp_clk_multiplier(675), .generate_overlay_clk_en(1),
	       .audio_bits(16))
   mb(.clk(clk), .ext_reset(~clk_locked), .sys_reset(reset),
      .reset_9900(reset_9900), .reset_9901(reset_9901),
      .reset_9918(reset_9918), .reset_9919(reset_9919),
      .reset_5200(reset_5200), .cpu_turbo(cpu_turbo),
      .vdp_clk_en(vdp_clk_en), .vga_clk_en(vga_clk_en),
      .overlay_clk_en(overlay_clk_en), .clk_3mhz_en(clk_3mhz_en),
      .vdp_hsync(vdp_hsync), .vdp_vsync(vdp_vsync),
      .vdp_cburst(vdp_cburst), .vdp_color(vdp_color),
      .vdp_color_en(vdp_color_en), .vdp_extvideo(),
      .audio_in(audio_in), .audio_out(audio_out),
      .key_state(key_state), .alpha_state(alpha_state),
      .joy1({~JAhi[8], ~JAlo[3], ~JAlo[4], ~JAlo[2], ~JAlo[1]}),
      .joy2({~JBhi[8], ~JBlo[3], ~JBlo[4], ~JBlo[2], ~JBlo[1]}),
      .cs1_cntrl(cs1_cntrl), .cs2_cntrl(cs2_cntrl),
      .audio_gate(), .mag_out(mag_out),
      .debug_pc(debug_pc), .debug_st(debug_st),
      .debug_wp(debug_wp), .debug_ir(debug_ir),
      .debug_vdp_addr(debug_vdp_addr), .debug_grom_addr(debug_grom_addr),
      .wb_adr_i(sp_adr_o), .wb_dat_i(sp_dat_o), .wb_dat_o(sp_dat_i),
      .wb_we_i(sp_we_o), .wb_sel_i(sp_sel_o), .wb_stb_i(sp_stb_o),
      .wb_ack_o(sp_ack_i), .wb_cyc_i(sp_cyc_o));

   tms9918_scandoubler
     scandoubler(.clk(clk), .clk_en_in(vdp_clk_en), .clk_en_out(vga_clk_en),
		 .sync_h_in(vdp_hsync),
		 .cburst_in(vdp_cburst),
		 .color_in(vdp_color),
		 .color_en_in(vdp_color_en),
		 .sync_h_out(vga_hsync),
		 .cburst_out(),
		 .color_out(vga_color),
		 .color_en_out());

   tms9918_color_to_rgb #(.red_bits(4), .green_bits(4), .blue_bits(4))
     vga_color_to_rgb(.color(overlay_color == 4'd0 ? vga_color : overlay_color),
		      .red(VGA_R), .green(VGA_G), .blue(VGA_B));

endmodule // mega99_nexys_a7_top
