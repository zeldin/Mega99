module mainboard #(
		   // clk rate is this number times 10.738635 MHz
		   parameter integer clk_multiplier = 1,
		   // set to 1 to geneate overlay_clk_en
		   parameter integer generate_overlay_clk_en = 0,
		   // should be > 8 for full dynamic range
		   parameter	     audio_bits = 16
		)
                (input                     clk,
		 input			   ext_reset,
		 output			   sys_reset,
		 input			   reset_9900,
		 input			   reset_9901,
		 input			   reset_9918,
		 input			   reset_9919,
		 input			   reset_5200,
		 input			   cpu_turbo,
		 output			   vdp_clk_en,
		 output			   vga_clk_en,
		 output			   overlay_clk_en,
		 output			   clk_3mhz_en,

		 output			   vdp_hsync,
		 output			   vdp_vsync,
		 output			   vdp_cburst,
		 output [0:3]		   vdp_color,
		 output			   vdp_extvideo,

		 input [0:(audio_bits-1)]  audio_in,
		 output [0:(audio_bits-1)] audio_out,

		 input [0:47]		   key_state,
		 input			   alpha_state,
		 input [0:4]		   joy1,
		 input [0:4]		   joy2,

		 output			   cs1_cntrl,
		 output			   cs2_cntrl,
		 output			   audio_gate,
		 output			   mag_out,

		 output [0:15]		   debug_pc,
		 output [0:15]		   debug_st,
		 output [0:15]		   debug_wp,
		 output [0:15]		   debug_ir,
		 output [0:13]		   debug_vdp_addr,
		 output [0:15]		   debug_grom_addr,

		 input [0:23]		   wb_adr_i,
		 input [0:7]		   wb_dat_i,
		 output reg [0:7]	   wb_dat_o,
		 input			   wb_we_i,
		 input [0:0]		   wb_sel_i,
		 input			   wb_stb_i,
		 output reg		   wb_ack_o,
		 input			   wb_cyc_i);

   wire	       reset;
   wire	       vdp_clk_en_next;
   wire	       cpu_clk_en;
   wire	       grom_clk_en;
   wire	       vsp_clk_en;

   wire	       memen;
   wire	       memen8; // use for 8-bit RAM/ROM, not needed for MB
   wire	       we;
   wire	       iaq;
   wire	       dbin;
   wire [0:14] a;
   wire [0:15] d;
   wire [0:15] q;
   wire	       ready;
   wire	       sysrdy;
   wire	       ready_grom;
   wire	       ready_sgc;
   wire	       ready_vsp;
   wire	       ready_peb;
   wire	       cruin_psi;
   wire	       cruin_peb;
   wire	       cruout;
   wire	       cruclk;

   wire	       intreq;
   wire	       vdp_irq;

   wire [0:15] d_rom;
   wire [0:15] d_sp;
   wire [0:15] d_mpx;
   wire [0:7]  d8;
   wire [0:7]  d8_grom;
   wire [0:7]  d8_crom;
   wire [0:7]  d8_vsp;
   wire [0:7]  d8_peb;
   wire [0:7]  cd_vdp;
   wire [0:7]  q8;
   reg	       d_rom_valid;
   reg	       d_sp_valid;
   reg	       d_vdp_valid;
   reg	       d_mpx_hi_valid;
   reg	       d_mpx_lo_valid;
   reg	       d8_grom_valid;
   reg	       d8_crom_valid;
   reg	       d8_vsp_valid;
   reg	       d8_peb_valid;

   wire	       romen;
   wire	       mbe;
   wire	       romg;
   wire	       mb;
   wire	       sound_sel;
   wire	       vdp_csr;
   wire	       vdp_csw;
   wire	       sbe;
   wire	       gs;
   wire	       ramblk;
   wire	       memex;
   wire	       a15;

   wire [1:6]  int_in;
   wire [0:15] p_in;
   wire [0:15] p_out;
   wire [0:15] p_dir;

   wire [0:(audio_bits-1)] audio_vsp;
   wire [0:audio_bits] audio_mix;
   wire [0:(audio_bits-1)] audio_mix_sat;

   wire [0:7]  wb_dat_vdp;
   wire [0:7]  wb_dat_rom;
   wire [0:7]  wb_dat_grom;
   wire [0:7]  wb_dat_crom;
   wire [0:7]  wb_dat_sprom;
   wire [0:7]  wb_dat_peb;
   wire	       wb_ack_vdp;
   wire	       wb_ack_rom;
   wire	       wb_ack_grom;
   wire	       wb_ack_crom;
   wire	       wb_ack_sprom;
   wire	       wb_ack_peb;
   reg	       wb_stb_vdp;
   reg	       wb_stb_rom;
   reg	       wb_stb_grom;
   reg	       wb_stb_crom;
   reg	       wb_stb_sprom;
   reg	       wb_stb_peb;
   
   assign sys_reset = reset;
   
   assign int_in[1] = 1'b1;
   assign int_in[2] = ~vdp_irq;
   assign p_in[0:10] = ~11'd0;
   assign p_in[11] = audio_in[0];

   assign cs1_cntrl = p_out[6];
   assign cs2_cntrl = p_out[7];
   assign audio_gate = p_out[8];
   assign mag_out = p_out[9];

   assign d = 16'hffff &
	      (d_rom_valid ?    d_rom                  : 16'hffff) &
	      (d_sp_valid ?     d_sp                   : 16'hffff) &
	      (d_vdp_valid ?    { cd_vdp, 8'hff }      : 16'hffff) &
	      (d_mpx_hi_valid ? { d_mpx[0:7], 8'hff }  : 16'hffff) &
	      (d_mpx_lo_valid ? { 8'hff, d_mpx[8:15] } : 16'hffff);
   assign d8 = 8'hff &
	       (d8_grom_valid ? d8_grom : 8'hff) &
	       (d8_crom_valid ? d8_crom : 8'hff) &
	       (d8_vsp_valid ? d8_vsp : 8'hff) &
	       (d8_peb_valid ? d8_peb : 8'hff);
   assign sysrdy = (ready_grom | ~gs) & ready_sgc & ready_vsp & ready_peb;

   assign audio_mix = {audio_in[0], audio_in} + {audio_vsp[0], audio_vsp};
   assign audio_mix_sat = (audio_gate? audio_vsp :
			   (audio_mix[0:1] == 2'b00 ||
			    audio_mix[0:1] == 2'b11 ? audio_mix :
			    {audio_mix[0], {(audio_bits-1){audio_mix[0]}}}));

   always @(posedge clk) begin
      d_rom_valid <= dbin && romen;
      d_sp_valid <= dbin && mb && ramblk;
      d_vdp_valid <= dbin && vdp_csr;
      d_mpx_hi_valid <= dbin && !(romen | (mb & ramblk)) && !vdp_csr;
      d_mpx_lo_valid <= dbin && !(romen | (mb & ramblk));
      d8_grom_valid <= dbin && gs;
      d8_crom_valid <= dbin && romg;
      d8_vsp_valid <= dbin && sbe;
      d8_peb_valid <= dbin && (mbe || memex);
   end

   always @(*) begin
      wb_dat_o <= 8'h00;
      wb_ack_o <= 1'b0;
      wb_stb_vdp <= 1'b0;
      wb_stb_rom <= 1'b0;
      wb_stb_grom <= 1'b0;
      wb_stb_crom <= 1'b0;
      wb_stb_sprom <= 1'b0;
      wb_stb_peb <= 1'b0;
      if (wb_adr_i[0]) begin
	 wb_stb_peb <= wb_stb_i;
	 wb_dat_o <= wb_dat_peb;
	 wb_ack_o <= wb_ack_peb;
      end else
	case (wb_adr_i[1 +: 3])
	  3'h0:
	    case (wb_adr_i[4 +: 4])
	      4'h0: begin
		 wb_stb_vdp <= wb_stb_i;
		 wb_dat_o <= wb_dat_vdp;
		 wb_ack_o <= wb_ack_vdp;
	      end
	      4'h1: begin
		 wb_stb_rom <= wb_stb_i;
		 wb_dat_o <= wb_dat_rom;
		 wb_ack_o <= wb_ack_rom;
	      end
	      4'h3: begin
		 wb_stb_crom <= wb_stb_i;
		 wb_dat_o <= wb_dat_crom;
		 wb_ack_o <= wb_ack_crom;
	      end
	      default: ;
	    endcase // case (wb_adr_i[4 +: 4])
	  3'h1: begin
	     wb_stb_grom <= wb_stb_i;
	     wb_dat_o <= wb_dat_grom;
	     wb_ack_o <= wb_ack_grom;
	  end
	  3'h2: begin
	     wb_stb_crom <= wb_stb_i;
	     wb_dat_o <= wb_dat_crom;
	     wb_ack_o <= wb_ack_crom;
	  end
	  3'h3: begin
	     wb_stb_sprom <= wb_stb_i;
	     wb_dat_o <= wb_dat_sprom;
	     wb_ack_o <= wb_ack_sprom;
	  end
	  default: ;
	endcase // case (wb_adr_i[1 +: 3])
   end

   clkgen #(.clk_multiplier(clk_multiplier),
	    .generate_overlay_clk_en(generate_overlay_clk_en))
   cg(.ext_reset_in(ext_reset), .clk(clk), .cpu_turbo(cpu_turbo),
      .reset_out(reset),
      .vdp_clk_en(vdp_clk_en), .vdp_clk_en_next(vdp_clk_en_next),
      .vga_clk_en(vga_clk_en), .overlay_clk_en(overlay_clk_en),
      .cpu_clk_en(cpu_clk_en), .clk_3mhz_en(clk_3mhz_en),
      .grom_clk_en(grom_clk_en), .vsp_clk_en(vsp_clk_en));

   address_decoder addr_dec(.memen(memen), .we(we), .dbin(dbin), .a(a),
			    .a15(a15), .romen(romen), .mbe(mbe),
			    .romg(romg), .mb(mb), .sound_sel(sound_sel),
			    .vdp_csr(vdp_csr), .vdp_csw(vdp_csw),
			    .sbe(sbe), .gs(gs), .ramblk(ramblk),
			    .memex(memex));

   multiplexer mpx(.clk(clk), .clk_en(cpu_clk_en),
		   .start(memen & !(romen | (mb & ramblk))),
		   .memen(memen), .sysrdy(sysrdy),
		   .memen8(memen8), .ready(ready), .a15(a15),
		   .d8(d8), .q8(q8), .d(d_mpx), .q(q));

   keymatrix matrix(.p_out(p_out[2:5]),
		    .int_in(int_in[3:6]), .p_in(p_in[12:15]),
		    .key_state(key_state), .alpha_state(alpha_state),
		    .joy1(joy1), .joy2(joy2));

   tms9900_cpu cpu(.reset(reset|reset_9900), .clk(clk), .clk_en(cpu_clk_en),
		   .memen_out(memen), .we(we), .iaq(iaq), .ready_in(ready),
		   .waiting(), .a(a), .d_in(d), .q(q), .dbin(dbin),
		   .cruin(ramblk ? cruin_psi : cruin_peb),
		   .cruout(cruout), .cruclk_out(cruclk),
		   .intreq(intreq), .ic(4'b0001),
		   .hold(1'b0), .holda(), .load(1'b0),
		   .debug_pc(debug_pc), .debug_st(debug_st),
		   .debug_wp(debug_wp), .debug_ir(debug_ir));

   tms9901_psi psi(.reset(reset|reset_9901), .clk(clk), .clk_en(clk_3mhz_en),
		   .cruout(cruout), .cruin(cruin_psi), .cruclk(cruclk),
		   .s(a[10:14]), .ce(ramblk),
		   .int_in(int_in), .p_in(p_in), .p_out(p_out), .p_dir(p_dir),
		   .intreq(intreq), .ic());

   tms9918_wrapper
     vdp(.reset(reset|reset_9918), .clk(clk), .clk_en(vdp_clk_en),
         .clk_en_next(vdp_clk_en_next),
	 .sync_h(vdp_hsync), .sync_v(vdp_vsync), .cburst(vdp_cburst),
	 .color(vdp_color), .extvideo(vdp_extvideo),
	 .cd(q[0:7]), .cq(cd_vdp), .csr(vdp_csr), .csw(vdp_csw),
         .mode(a[14]), .int_pending(vdp_irq),
         .wb_adr_i(wb_adr_i[23 -: 15]), .wb_dat_i(wb_dat_i),
	 .wb_dat_o(wb_dat_vdp), .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
	 .wb_stb_i(wb_stb_vdp), .wb_ack_o(wb_ack_vdp), .wb_cyc_i(wb_cyc_i),
	 .debug_vdp_addr(debug_vdp_addr));
   
   tms9919_sgc #(.audio_bits(audio_bits))
     sgc(.reset(reset|reset_9919), .clk(clk), .clk_en(clk_3mhz_en),
	 .d(q[0:7]), .cs(sound_sel), .we(we), .ready(ready_sgc),
	 .audioin(audio_mix_sat), .audioout(audio_out));

   tms5200_wrapper #(.audio_bits(audio_bits), .vsm_size(32768))
     vsp(.reset(reset|reset_5200), .clk(clk), .clk_en(vsp_clk_en),
	 .dd(q8), .dq(d8_vsp), .rs(sbe && !a[5]), .ws(sbe && a[5]),
	 .rdy(ready_vsp), .int(), .audioout(audio_vsp),
	 .wb_adr_i(wb_adr_i[23 -: 18]), .wb_dat_i(wb_dat_i),
	 .wb_dat_o(wb_dat_sprom), .wb_we_i(wb_we_i),
	 .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_sprom),
	 .wb_ack_o(wb_ack_sprom), .wb_cyc_i(wb_cyc_i));

   console_rom rom(.clk(clk), .cs(romen), .a(a), .q(d_rom),
		   .wb_adr_i(wb_adr_i[23 -: 16]), .wb_dat_i(wb_dat_i),
		   .wb_dat_o(wb_dat_rom), .wb_we_i(wb_we_i),
		   .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_rom),
		   .wb_ack_o(wb_ack_rom), .wb_cyc_i(wb_cyc_i));

   scratchpad_ram ram(.clk(clk), .cs(mb && ramblk), .we(we),
		      .a(a), .d(q), .q(d_sp));

   groms grom(.clk(clk), .grclk_en(grom_clk_en), .m(dbin), .gs(gs),
	      .mo(a[14]), .d(q8), .q(d8_grom), .gready(ready_grom),
	      .grom_set(a[10:13]), .debug_grom_addr(debug_grom_addr),
	      .wb_adr_i(wb_adr_i[23 -: 16]), .wb_dat_i(wb_dat_i),
	      .wb_dat_o(wb_dat_grom), .wb_we_i(wb_we_i),
	      .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_grom),
	      .wb_ack_o(wb_ack_grom), .wb_cyc_i(wb_cyc_i));

   cartridge_rom crom(.clk(clk), .cs(romg), .we(we),
		      .a({a[3:14], a15}), .d(q8), .q(d8_crom),
		      .wb_adr_i({wb_adr_i[2], wb_adr_i[23 -: 20]}),
		      .wb_dat_i(wb_dat_i),
		      .wb_dat_o(wb_dat_crom), .wb_we_i(wb_we_i),
		      .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_crom),
		      .wb_ack_o(wb_ack_crom), .wb_cyc_i(wb_cyc_i));

   peb peb(.clk(clk), .clk_3mhz_en(clk_3mhz_en), .reset(reset),
	   .a({a, a15 & (cruout | memen)}), .d(q8), .q(d8_peb),
	   .memen(memen8), .dbin(dbin), .we(we), .cruclk(cruclk),
	   .cruin(cruin_peb), .ready(ready_peb),

	   .wb_adr_i(wb_adr_i[1:23]), .wb_dat_i(wb_dat_i),
	   .wb_dat_o(wb_dat_peb), .wb_we_i(wb_we_i),
	   .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_peb),
	   .wb_ack_o(wb_ack_peb), .wb_cyc_i(wb_cyc_i));

endmodule // mainboard
