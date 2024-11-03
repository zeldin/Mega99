module mega99_mega65r3_top(input        CLK100MHZ,

			   output	H_CLK,
			   inout	RWDS,
			   inout [7:0]	DQ,
			   output	CS0,
			   output	H_RES,

			   output	VDAC_CLK,
			   output	VDAC_SYNC_N,
			   output	VDAC_BLANK_N,

			   output [7:0]	VGA_R,
			   output [7:0]	VGA_G,
			   output [7:0]	VGA_B,
			   output	VGA_HS,
			   output	VGA_VS,

			   output	PWM_L,
			   output	PWM_R,
			   output	AUDIO_MCLK,
			   output	AUDIO_BCLK,
			   output	AUDIO_SDATA,
			   output	AUDIO_LRCLK, 
			   output	AUDIO_PDN,

			   output	TXC_N,
			   output	TXC_P,
			   output [2:0]	TX_N,
			   output [2:0]	TX_P,
			   inout	SCL_A,
			   inout	SDA_A,
			   output	LS_OE,
			   inout	CEC_A,
			   input	HPD_A,
			   output	CT_HPD,

			   output	FPGA_TX,      /* FIXME */
			   output	FPGA_RX,      /*   "   */
			   input	FPGA_RESET_N, /*   "   */

			   input	SD1_CD,
			   output	SD1_SCK,
			   output	SD1_CMD,
			   inout [3:0]	SD1_DAT,

			   input	SD2_CD,
			   input	SD2_WP,
			   output	SD2_SCK,
			   output	SD2_CMD,
			   inout [3:0]	SD2_DAT,

			   inout [3:0]	SPI_DQ,
			   output       SPI_CS,

			   inout	KB_IO0,
			   inout	KB_IO1,
			   input	KB_IO2,

			   input	UART_RXD,
			   output	UART_TXD,

			   input	FA_DOWN,
			   input	FA_UP,
			   input	FA_LEFT,
			   input	FA_RIGHT,
			   input	FA_FIRE,
			   input	FB_DOWN,
			   input	FB_UP,
			   input	FB_LEFT,
			   input	FB_RIGHT,
			   input	FB_FIRE);

   wire        clk;
   wire	       clk_hdmi;
   wire	       clk_hdmi_x5;
   wire	       clk_pcm;
   wire	       locked_pcm;
   wire	       clk_locked;
   wire	       reset;
   reg [0:3]   hdmi_reset;

   wire [2:31] xmem_adr_o;
   wire [0:31] xmem_dat_o;
   wire [0:31] xmem_dat_i;
   wire	       xmem_we_o;
   wire [0:3]  xmem_sel_o;
   wire	       xmem_stb_o;
   wire	       xmem_ack_i;
   wire	       xmem_cyc_o;

   wire	       sdcard_cs;
   wire	       sdcard_clk;
   wire	       sdcard_mosi;
   wire	       sdcard_select;

   wire [3:0]  qspi_out;
   wire [3:0]  qspi_oe;
   wire	       qspi_sck;

   wire [0:15] audio_in;
   wire [15:0] audio_out;
   wire	       audio_sd;
   wire	       pcm_clken;
   wire [15:0] audio_pcm;
   reg	       pcm_acr;
   reg [5:0]   pcm_acr_cnt;

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
   wire	       vga_color_en;
   wire [0:3]  overlay_color;

   wire [29:0] tmds;

   wire	       led_red;
   wire	       led_green;

   wire [0:15] debug_pc;
   wire [0:15] debug_st;
   wire [0:15] debug_wp;
   wire [0:15] debug_ir;
   wire [0:13] debug_vdp_addr;
   wire [0:15] debug_grom_addr;

   wire [6:0]  kbd_scancode;
   wire	       kbd_strobe;
   wire	       kbd_keypress;
   wire [0:23] led1_rgb;
   wire [0:23] led2_rgb;
   wire [0:23] led3_rgb;
   wire [0:23] led4_rgb;

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
   wire [1:3]  drive_activity;

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


   assign VDAC_CLK = overlay_clk_en;
   assign VDAC_SYNC_N = 1'b0;
   assign VDAC_BLANK_N = 1'b1;
   assign VGA_HS = ~vga_hsync;
   assign VGA_VS = ~vdp_vsync;

   assign PWM_L = audio_sd;
   assign PWM_R = audio_sd;
   assign AUDIO_MCLK = 1'b0;
   assign AUDIO_BCLK = 1'b0;
   assign AUDIO_SDATA = 1'b0;
   assign AUDIO_LRCLK = 1'b0;
   assign AUDIO_PDN = 1'b0;

   assign SCL_A = 1'bz;
   assign SDA_A = 1'bz;
   assign LS_OE = 1'b1;
   assign CEC_A = 1'bz;
   assign CT_HPD = 1'b1;

   assign FPGA_TX = 1'b1; /* FIXME */
   assign FPGA_RX = 1'b1; /*   "   */

   assign SD1_DAT[3] = ~(sdcard_cs & ~sdcard_select);
   assign SD1_SCK = sdcard_sck & ~sdcard_select;
   assign SD1_CMD = sdcard_mosi & ~sdcard_select;
   assign SD2_DAT[3] = ~(sdcard_cs & sdcard_select);
   assign SD2_SCK = sdcard_sck & sdcard_select;
   assign SD2_CMD = sdcard_mosi & sdcard_select;

   assign SPI_DQ[0] = (qspi_oe[0] ? qspi_out[0] : 1'bz);
   assign SPI_DQ[1] = (qspi_oe[1] ? qspi_out[1] : 1'bz);
   assign SPI_DQ[2] = (qspi_oe[2] ? qspi_out[2] : 1'bz);
   assign SPI_DQ[3] = (qspi_oe[3] ? qspi_out[3] : 1'bz);

   mega65_clkwiz clkgen(.clk_sys(clk), .clk_sys_phi90(clk_phi90),
			.clk_hdmi(clk_hdmi), .clk_hdmi_x5(clk_hdmi_x5),
			.clk_pcm(clk_pcm), .locked_pcm(locked_pcm),
			.locked(clk_locked), .clk_in1(CLK100MHZ));

   hyperram_wrapper #(.CLK_HZ(108000000))
   hr_wrapper(.clk(clk), .clk_phi90(clk_phi90), 
	      .reset(reset), .pll_locked(clk_locked),
	      .ck(H_CLK), .rwds(RWDS), .dq(DQ), .cs_b(CS0),
	      .ram_reset_b(H_RES),
	      .adr_i(xmem_adr_o), .dat_i(xmem_dat_o),
	      .dat_o(xmem_dat_i), .we_i(xmem_we_o),
	      .sel_i(xmem_sel_o), .stb_i(xmem_stb_o),
	      .ack_o(xmem_ack_i), .cyc_i(xmem_cyc_o));

   kbdmk1com mk1com(.clk(clk),
		    .kb_ck(KB_IO0), .kb_do(KB_IO1), .kb_di(KB_IO2),
		    .led1_rgb(led1_rgb), .led2_rgb(led2_rgb),
		    .led3_rgb(led3_rgb), .led4_rgb(led4_rgb),
		    .kbd_scancode(kbd_scancode), .kbd_keypress(kbd_keypress),
		    .kbd_strobe(kbd_strobe));

   keyboard_mk1 keyboard(.clk(clk), .reset(reset),
			 .scancode(kbd_scancode), .trigger(kbd_strobe),
			 .pressed(kbd_keypress),
			 .key_state(key_state), .alpha_state(alpha_state),
			 .turbo_state(cpu_turbo),
			 .keypress(keypress), .keycode(keycode),
			 .shift_state(shift_state),
			 .keyboard_block(keyboard_block));

   sp #(.keyboard_model(1), .num_sdcard(2))
   service_processor(.clk(clk), .reset(reset),
		     .wb_adr_o(sp_adr_o), .wb_dat_o(sp_dat_o),
		     .wb_dat_i(sp_dat_i), .wb_we_o(sp_we_o),
		     .wb_sel_o(sp_sel_o), .wb_stb_o(sp_stb_o),
		     .wb_ack_i(sp_ack_i), .wb_cyc_o(sp_cyc_o),

		     .xmem_adr_o(xmem_adr_o), .xmem_dat_o(xmem_dat_o),
		     .xmem_dat_i(xmem_dat_i), .xmem_we_o(xmem_we_o),
		     .xmem_sel_o(xmem_sel_o), .xmem_stb_o(xmem_stb_o),
		     .xmem_ack_i(xmem_ack_i), .xmem_cyc_o(xmem_cyc_o),

		     .tp_valid(tp_valid), .tp_pc(tp_pc), .tp_insn(tp_insn),

		     .led_green(led_green), .led_red(led_red),
		     .sw_reset({reset_9900, reset_9901,
				reset_9918, reset_9919, reset_5200}),
		     .led1_rgb(led1_rgb), .led2_rgb(led2_rgb),
		     .led3_rgb(led3_rgb), .led4_rgb(led4_rgb),
		     .drive_activity(drive_activity),
		     .overlay_clk_en(overlay_clk_en), .overlay_vsync(vdp_vsync),
		     .overlay_hsync(vga_hsync), .overlay_color(overlay_color),
		     .keypress(keypress), .keycode(keycode),
		     .shift_state({shift_state[0:1], alpha_state,
				   (|shift_state[2:3])}),
		     .keyboard_block(keyboard_block),
		     .clk_3mhz_en(clk_3mhz_en), .tape_audio(audio_in),
		     .cs1_cntrl(cs1_cntrl), .cs2_cntrl(cs2_cntrl),
		     .mag_out(mag_out),
		     .sdcard_select(sdcard_select), .sdcard_cs(sdcard_cs),
		     .sdcard_cd(~(sdcard_select ? SD2_CD : SD1_CD)),
		     .sdcard_wp((sdcard_select? SD2_WP : 1'b0)),
		     .sdcard_sck(sdcard_sck),
		     .sdcard_miso((sdcard_select? SD2_DAT[0] : SD1_DAT[0])),
		     .sdcard_mosi(sdcard_mosi),
		     .uart_txd(UART_TXD), .uart_rxd(UART_RXD),
		     .qspi_in(SPI_DQ), .qspi_out(qspi_out), .qspi_oe(qspi_oe),
		     .qspi_csn(SPI_CS), .qspi_sck(qspi_sck));

   mainboard #(.vdp_clk_multiplier(10), .cpu_clk_multiplier(36),
	       .vsp_clk_multiplier(675), .generate_overlay_clk_en(1),
	       .audio_bits(16), .ENABLE_HDMI_TIMING_TWEAKS(1))
   mb(.clk(clk), .ext_reset(1'b0 /*FIXME*/ | ~clk_locked), .sys_reset(reset),
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
      .joy1(~{FA_FIRE, FA_LEFT, FA_RIGHT, FA_DOWN, FA_UP}),
      .joy2(~{FB_FIRE, FB_LEFT, FB_RIGHT, FB_DOWN, FB_UP}),
      .cs1_cntrl(cs1_cntrl), .cs2_cntrl(cs2_cntrl),
      .audio_gate(), .mag_out(mag_out), .drive_activity(drive_activity),
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
		 .color_en_out(vga_color_en));

   tms9918_color_to_rgb #(.red_bits(8), .green_bits(8), .blue_bits(8))
     vga_color_to_rgb(.color(overlay_color == 4'd0 ? vga_color : overlay_color),
		      .red(VGA_R), .green(VGA_G), .blue(VGA_B));

   ak4432_audio #(.audio_bits(16))
   audio_encoder(.ref_clk(clk), .pcm_in(audio_out),
		 .mclk(clk_pcm), .bclk(), .sdata(), .lrclk(),
		 .pcm_out(audio_pcm), .clken(pcm_clken));
   sigmadelta #(.audio_bits(10))
   sd_dac(.clk(clk), .d(audio_out[15 -: 10]), .q(audio_sd));

   always @(posedge clk_pcm) begin
      pcm_acr <= 1'b0;
      if (pcm_clken) begin
	 if (pcm_acr_cnt == 6'd47) begin
            pcm_acr <= 1'b1;
            pcm_acr_cnt <= 6'd0;
	 end else
	   pcm_acr_cnt <= pcm_acr_cnt + 6'd1;
      end
   end

   always @(posedge clk_hdmi)
     if (clk_locked)
       hdmi_reset <= { hdmi_reset[1:3], 1'b1 };
     else
       hdmi_reset <= 4'b0000;

   vga_to_hdmi hdmi_encoder(.select_44100(1'b0), .dvi(1'b0),
			    .vic(8'h00 /* custom */), .aspect(2'b01),
			    .pix_rep(1'b0), .vs_pol(1'b1), .hs_pol(1'b1),
			    .vga_rst(~hdmi_reset[0]), .vga_clk(clk_hdmi),
			    .vga_vs(VGA_VS), .vga_hs(VGA_HS),
			    .vga_de(vga_color_en), .vga_r(VGA_R),
			    .vga_g(VGA_G), .vga_b(VGA_B),
			    .pcm_rst(~locked_pcm), .pcm_clk(clk_pcm),
			    .pcm_clken(pcm_clken),
			    .pcm_l(audio_pcm), .pcm_r(audio_pcm),
			    .pcm_acr(pcm_acr), .pcm_n(20'd6144),
			    .pcm_cts(20'd27000), .tmds(tmds));

   tmds_10to1ddr ser_tx0(.clk_x5(clk_hdmi_x5), .d(tmds[9:0]),
			 .out_p(TX_P[0]), .out_n(TX_N[0]));
   tmds_10to1ddr ser_tx1(.clk_x5(clk_hdmi_x5), .d(tmds[19:10]),
			 .out_p(TX_P[1]), .out_n(TX_N[1]));
   tmds_10to1ddr ser_tx2(.clk_x5(clk_hdmi_x5), .d(tmds[29:20]),
			 .out_p(TX_P[2]), .out_n(TX_N[2]));
   tmds_10to1ddr ser_txc(.clk_x5(clk_hdmi_x5), .d(10'b0000011111),
			 .out_p(TXC_P), .out_n(TXC_N));

   STARTUPE2 startup(.CFGCLK(), .CFGMCLK(), .CLK(1'b0), .EOS(),
		     .GSR(1'b0), .GTS(1'b0), .KEYCLEARB(1'b0),
		     .PACK(1'b0), .PREQ(),
		     .USRCCLKO(qspi_sck), .USRCCLKTS(1'b0),
		     .USRDONEO(1'b1), .USRDONETS(1'b1));

endmodule // mega99_mega65r3_top
