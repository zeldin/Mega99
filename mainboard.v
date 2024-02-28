module mainboard(input  clk,
		 input			   ext_reset,
		 output			   sys_reset,
		 input			   cpu_turbo,
		 output			   vdp_clk_en,
		 output			   vga_clk_en,
		 output			   hdmi_clk_en,

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

		 input [0:14]		   wb_adr_i,
		 input [0:7]		   wb_dat_i,
		 output [0:7]		   wb_dat_o,
		 input			   wb_we_i,
		 input [0:0]		   wb_sel_i,
		 input			   wb_stb_i,
		 output			   wb_ack_o,
		 input			   wb_cyc_i);

   // clk rate is this number times 10.738635 MHz
   parameter integer clk_multiplier = 1;
   // set to 1 to geneate hdmi_clk_en
   parameter integer generate_hdmi_clk_en = 0;

   parameter audio_bits = 16; // should be > 8 for full dynamic range


   wire	       reset;
   wire	       vdp_clk_en_next;
   wire	       cpu_clk_en;
   wire	       clk_3mhz_en;
   wire	       grom_clk_en;

   wire	       memen;
   wire	       we;
   wire	       iaq;
   wire	       dbin;
   wire [0:14] a;
   wire [0:15] d;
   wire [0:15] q;
   wire	       sysrdy;
   wire	       ready_grom;
   wire	       ready_sgc;
   wire	       cruin;
   wire	       cruout;
   wire	       cruclk;

   wire	       intreq;
   wire	       vdp_irq;

   wire [0:15] d_rom;
   wire [0:15] d_sp;
   wire [0:15] d_vdp;
   wire [0:15] d_grom;
   reg	       d_rom_valid;
   reg	       d_sp_valid;
   reg	       d_vdp_valid;
   reg	       d_grom_valid;

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
   
   assign sys_reset = reset;
   
   assign int_in[1] = 1'b1;
   assign int_in[2] = ~vdp_irq;
   assign p_in[0:10] = ~11'd0;
   assign p_in[11] = audio_in[0];

   assign cs1_cntrl = p_out[6];
   assign cs2_cntrl = p_out[7];
   assign audio_gate = p_out[8];
   assign mag_out = p_out[9];

   assign a15 = 1'b0;

   assign d = 16'hffff &
	      (d_rom_valid?  d_rom  : 16'hffff) &
	      (d_sp_valid?   d_sp   : 16'hffff) &
	      (d_vdp_valid?  d_vdp  : 16'hffff) &
	      (d_grom_valid? d_grom : 16'hffff);
   assign sysrdy = (ready_grom | ~gs) & ready_sgc;

   assign d_vdp[8:15] = 8'hff;
   assign d_grom[8:15] = 8'hff;
   
   always @(posedge clk) begin
      d_rom_valid <= dbin && romen;
      d_sp_valid <= dbin && mb && ramblk;
      d_vdp_valid <= dbin && vdp_csr;
      d_grom_valid <= dbin && gs;
   end

   clkgen #(.clk_multiplier(clk_multiplier),
	    .generate_hdmi_clk_en(generate_hdmi_clk_en))
   cg(.ext_reset_in(ext_reset), .clk(clk), .cpu_turbo(cpu_turbo),
      .reset_out(reset),
      .vdp_clk_en(vdp_clk_en), .vdp_clk_en_next(vdp_clk_en_next),
      .vga_clk_en(vga_clk_en), .hdmi_clk_en(hdmi_clk_en),
      .cpu_clk_en(cpu_clk_en), .clk_3mhz_en(clk_3mhz_en),
      .grom_clk_en(grom_clk_en));

   address_decoder addr_dec(.memen(memen), .we(we), .dbin(dbin), .a(a),
			    .a15(a15), .romen(romen), .mbe(mbe),
			    .romg(romg), .mb(mb), .sound_sel(sound_sel),
			    .vdp_csr(vdp_csr), .vdp_csw(vdp_csw),
			    .sbe(sbe), .gs(gs), .ramblk(ramblk),
			    .memex(memex));

   keymatrix matrix(.p_out(p_out[2:5]),
		    .int_in(int_in[3:6]), .p_in(p_in[12:15]),
		    .key_state(key_state), .alpha_state(alpha_state),
		    .joy1(5'b00000), .joy2(5'b0000));

   tms9900_cpu cpu(.reset(reset), .clk(clk), .clk_en(cpu_clk_en),
		   .memen_out(memen), .we(we), .iaq(iaq), .ready_in(sysrdy),
		   .waiting(), .a(a), .d_in(d), .q(q), .dbin(dbin),
		   .cruin(cruin), .cruout(cruout), .cruclk_out(cruclk),
		   .intreq(intreq), .ic(4'b0001),
		   .debug_pc(debug_pc), .debug_st(debug_st),
		   .debug_wp(debug_wp), .debug_ir(debug_ir));

   tms9901_psi psi(.reset(reset), .clk(clk), .clk_en(clk_3mhz_en),
		   .cruout(cruout), .cruin(cruin), .cruclk(cruclk),
		   .s(a[10:14]), .ce(ramblk),
		   .int_in(int_in), .p_in(p_in), .p_out(p_out), .p_dir(p_dir),
		   .intreq(intreq), .ic());

   tms9918_wrapper
     vdp(.reset(reset), .clk(clk), .clk_en(vdp_clk_en),
         .clk_en_next(vdp_clk_en_next),
	 .sync_h(vdp_hsync), .sync_v(vdp_vsync), .cburst(vdp_cburst),
	 .color(vdp_color), .extvideo(vdp_extvideo),
	 .cd(q[0:7]), .cq(d_vdp[0:7]), .csr(vdp_csr), .csw(vdp_csw),
         .mode(a[14]), .int_pending(vdp_irq),
         .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
         .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_i),
	 .wb_ack_o(wb_ack_o), .wb_cyc_i(wb_cyc_i),
	 .debug_vdp_addr(debug_vdp_addr));
   
   tms9919_sgc #(.audio_bits(audio_bits))
     sgc(.reset(reset), .clk(clk), .clk_en(clk_3mhz_en),
	 .d(q[0:7]), .cs(sound_sel), .we(we), .ready(ready_sgc),
	 .audioin((audio_gate? {audio_bits{1'b0}} : audio_in)),
         .audioout(audio_out));

   console_rom rom(.clk(clk), .cs(romen), .a(a), .q(d_rom));

   scratchpad_ram ram(.clk(clk), .cs(mb && ramblk), .we(we),
		      .a(a), .d(q), .q(d_sp));

   groms grom(.clk(clk), .grclk_en(grom_clk_en), .m(dbin), .gs(gs),
	      .mo(a[14]), .d(q[0:7]), .q(d_grom[0:7]), .gready(ready_grom),
	      .grom_set(a[10:13]), .debug_grom_addr(debug_grom_addr));
				      
endmodule // mainboard
