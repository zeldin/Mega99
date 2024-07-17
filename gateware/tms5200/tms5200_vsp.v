// The following implementation is closely based on the schematics in
// US patent US4335277A (expired by 2000).

module tms5200_vsp(input            reset,
		   input	    clk, // Enabled cycles should give
		   input	    clk_en, // ROMCLK clock, 160 kHz
		   output reg	    t11,
		   output reg	    io,

		   input [0:7]	    dd,
		   output [0:7]	    dq,
		   input	    rs,
		   input	    ws,
		   output	    rdy,
		   output reg	    int,
		   
		   output reg [0:3] add_out,
		   input	    add8_in,
		   output	    m0,
		   output	    m1,

		   output	    promout);

   reg lchen_todd;
   reg ddis;
   reg i01, i02, i03, i11;
   wire	i04;
   reg rb_la_start;
   reg [9:0]  poshift;
   wire	bl, be, bf;

   assign m0 = (lchen_todd & ~ddis) | i01 | i02 | i03 | i04;
   assign m1 = i11 | rb_la_start;
   assign promout = poshift[0];
   
   wire	puc;
   assign puc = reset; // Use external reset instead of internal POR
   
   reg [4:0] tcnt;
   reg [4:0] pc;
   reg [2:0] ic;
   reg div1, div2, div4, div8, ic_eq_7;
   reg pc0, pc_eq_0, pc_eq_1, pc_gt_5, pc_eq_12;
   reg t1, t2, t8, t10, t14, t15, t16, t17, t19, t20;
   reg t1_to_t9, t9_to_t18, t10_to_t18;
   reg tp, te10;

   wire	todd;
   assign todd = tcnt[0];
   
   wire	talkst;
   reg talkd;
   reg tcon;
   reg spen;
   assign talkst = talkd | tcon | spen; // Note: Patent does not have tcon here


   // Timing

   always @(posedge clk)
     if (clk_en) begin
       if (reset) begin
	  tcnt <= 5'd1;
	  pc <= 5'd0;
	  ic <= 3'd0;
       end else begin
	  if (t19)
	    tcnt <= 5'd1;
	  else
	    tcnt <= tcnt + 5'd1;

	  if (t16) begin
	     if (pc[4:1] == 4'd12)
	       pc <= 5'd0;
	     else
	       pc <= pc + 5'd1;
	  end

	  if (t2 && ~|pc)
	    ic <= ic + 3'd1;
       end

	t1 <= (tcnt == 5'd1);
	t2 <= (tcnt == 5'd2);
	t8 <= (tcnt == 5'd8);
	t10 <= (tcnt == 5'd10);
	t11 <= (tcnt == 5'd11);
	t14 <= (tcnt == 5'd14);
	t15 <= (tcnt == 5'd15);
	t16 <= (tcnt == 5'd16);
	t17 <= (tcnt == 5'd17);
	t19 <= (tcnt == 5'd19);
	t20 <= (tcnt == 5'd20);
	t1_to_t9 <= (tcnt >= 5'd1 && tcnt <= 5'd9);
	t9_to_t18 <= (tcnt >= 5'd9 && tcnt <= 5'd18);
	t10_to_t18 <= (tcnt >= 5'd10 && tcnt <= 5'd18);
	
	pc0 <= pc[0];

	pc_eq_0 <= pc[4:1] == 4'd0;
	pc_eq_1 <= pc[4:1] == 4'd1;
	pc_gt_5 <= (pc[4:1] == 4'd6 || pc[4:1] == 4'd7 || pc[4]);
	if (t1)
	  pc_eq_12 <= pc[4:1] == 4'd12;
	tp <= (tcnt == 5'd11 && pc[4:1] == 4'd1);
	te10 <= ((tcnt == 5'd10 && pc[4:1] == 4'd0) ||
		 (tcnt == 5'd20 && pc[4:1] == 4'd11));

	div1 <= (ic == 3'b000);
	div8 <= |ic[1:0] & ~ic[2];
	div4 <= (ic[2:1] == 2'b10);
	div2 <= (ic[2:1] == 2'b11);
	ic_eq_7 <= (ic == 3'b111);
     end // if (clk_en)

   reg tk;
   reg ldp;
   always @(posedge clk)
     if (clk_en) begin
	tk <= 1'b0;
	case (pc[4:1])
	  4'd2: tk <= (tcnt == 5'd9);
	  4'd3: tk <= (tcnt == 5'd8);
	  4'd4: tk <= (tcnt == 5'd7);
	  4'd5: tk <= (tcnt == 5'd6);
	  4'd6: tk <= (tcnt == 5'd5);
	  4'd7: tk <= (tcnt == 5'd4);
	  4'd8: tk <= (tcnt == 5'd3);
	  4'd9: tk <= (tcnt == 5'd2);
	  4'd10: tk <= (tcnt == 5'd1);
	endcase // case (pc[4:1])
	ldp <= 1'b0;
	case (pc[4:1])
	  4'd0: ldp <= (tcnt == 5'd5);
	  4'd1: ldp <= (tcnt == 5'd19); // T1 in patent, but we need RPT too!
	  4'd2: ldp <= (tcnt == 5'd3);
	  4'd3: ldp <= (tcnt == 5'd3);
	  4'd4: ldp <= (tcnt == 5'd5);
	  4'd5: ldp <= (tcnt == 5'd5);
	  4'd6: ldp <= (tcnt == 5'd5);
	  4'd7: ldp <= (tcnt == 5'd5);
	  4'd8: ldp <= (tcnt == 5'd5);
	  4'd9: ldp <= (tcnt == 5'd7);
	  4'd10: ldp <= (tcnt == 5'd7);
	  4'd11: ldp <= (tcnt == 5'd7);
	  default: ;
	endcase // case (pc[4:1])
     end // if (clk_en)

   
   // Digital output

   reg [13:4] io_sr;
   reg [13:0] yl;

   always @(posedge clk)
     if (clk_en) begin
	if (t11) begin
	   io <= 1'b0;
	   io_sr <= yl[13:4];
	end else begin
	   io <= io_sr[4];
	   io_sr <= { io_sr[13], io_sr[13:5] };
	end
     end


   // Command reg

   reg [1:3] cmd;
   wire	     rdby;
   wire	     spkext;
   wire	     rb;
   wire	     la;
   wire	     spk;
   wire	     rst;
   wire	     nop;
   wire	     nopfin;
   reg	     last_nop;
   wire	     ldce, ldce_clear;
   assign rdby = (cmd == 3'b001 && !talkst && !ldce);
   assign spkext = (cmd == 3'b110 && !talkst && !ldce);
   assign rb = (cmd == 3'b011 && !talkst && !ldce);
   assign la = (cmd == 3'b100 && !talkst && !ldce);
   assign spk = (cmd == 3'b101 && !ldce);
   assign rst = (cmd == 3'b111 && !ldce);
   assign nop = (cmd[1] == 1'b0 && cmd[3] == 1'b0 && !ldce);
   assign nopfin = (nop && !last_nop);

   always @(posedge clk)
     if (reset)
       cmd[1:3] <= 3'b111;
     else if (clk_en) begin
	last_nop <= nop;
	if (ldce_clear && !ldce) begin
	   // Prevent last command from reactivating, not in patent...
	   cmd[1:3] <= 3'b000;
	   last_nop <= 1'b1;
	end
	if (ldce)
	  cmd[1:3] <= dd[1:3];
     end


   // SPKEXT logic

   reg spefin;
   reg last_spkext, last_talkst;
   wire	spkee;
   assign spkee = spkext & ~last_spkext;

   always @(posedge clk)
     if (reset) begin
	ddis <= 1'b0;
     end else if (clk_en) begin
	last_spkext <= spkext;
	last_talkst <= talkst;
	spefin <= last_talkst & ~talkst;
	
	if (spkee)
	  ddis <= 1'b1;
	if (spefin)
	  ddis <= 1'b0;
     end
   

   // State machine

   reg delay_timer, delay_latch, last_delay_latch, delay_pending;
   reg i01_pre;
   wire i03_pre;
   wire	la_latch_clear;
   reg	la_latch;
   reg last_rst;
   reg last_puc_rst;
   wire	rstfin;
   reg	rdbyen, rdbyen_last;
   wire	rdbyen_pre;
   reg	rdby_primer, rdby_start;
   reg	last_rdby_spk, rdby_spk_start, last_rdby_spk_start;
   wire	rdbyfin;
   reg	spkfin, spkfin_pre;

   assign i03_pre = la_latch & la_latch_clear & ~(rb | last_puc_rst);
   assign la_latch_clear = rdby | spk | rb | last_puc_rst;
   assign rstfin = delay_timer & rst;
   assign rdbyfin = rdbyen_last & ~rdbyen;
   assign rdbyen_pre = rdby & t2 & rdby_start;

   always @(posedge clk)
     if (reset) begin
	delay_latch <= 1'b0;
	delay_pending <= 1'b0;
	last_rst <= 1'b0;
	last_puc_rst <= 1'b1;
	i01 <= 1'b0;
	i01_pre <= 1'b0;
	i11 <= 1'b0;
	rdbyen <= 1'b0;
	rdby_start <= 1'b0;
     end else if (clk_en) begin
	last_delay_latch <= delay_latch;
	delay_timer <= last_delay_latch & ~delay_latch;
	if (t16)
	  delay_latch <= 1'b0;
	if (t2 & delay_pending)
	  delay_latch <= 1'b1;
	if (delay_timer)
	  delay_pending <= 1'b0;
	if (i01 || i03_pre)
	  delay_pending <= 1'b1;
	i01 <= i01_pre;
	i01_pre <= i11;
	last_rst <= rst;
	last_puc_rst <= puc | rst;
	i11 <= rst & ~last_rst;
	i03 <= i03_pre;
	if (la_latch_clear)
	  la_latch <= 1'b0;
	if (la)
	  la_latch <= 1'b1;
	rdbyen_last <= rdbyen;
	if (rdbyen_pre)
	  rdbyen <= 1'b1;
	if (t17)
	  rdbyen <= 1'b0;
	if (rdby & delay_timer)
	  rdby_start <= 1'b1;
	if (rdby_primer)
	  rdby_start <= 1'b1;
	if (rdbyen)
	  rdby_start <= 1'b0;
	rdby_primer <= rdby & ~delay_pending & last_rdby_spk_start;
	last_rdby_spk_start <= rdby_spk_start;
	rdby_spk_start <= (rdby | spk) & ~last_rdby_spk;
	last_rdby_spk <= rdby | spk;
	spkfin <= spk & (spkfin_pre | delay_timer);
	spkfin_pre <= ~delay_pending & last_rdby_spk_start;
     end

   
   // RB/LA logic

   reg rb_la_start_pre;
   reg last_rb_la_start;
   wire	lafin;

   assign i04 = rb & rb_la_start;
   assign lafin = la & last_rb_la_start;

   always @(posedge clk)
     if (clk_en) begin
	last_rb_la_start <= rb_la_start;
	rb_la_start <= (rb | la) & rb_la_start_pre;	
	rb_la_start_pre <= ~(rb | la);
     end


   // RB timer
   
   wire	rbfin;
   reg	rbtimer, last_rbtimer;
   reg	rbtimer_a, rbtimer_b;
   assign rbfin = rbtimer & ~last_rbtimer;

   always @(posedge clk)
     if (clk_en) begin
	last_rbtimer <= rbtimer;
	rbtimer <= rbtimer_a | rbtimer_b | ~rb;
	if (!rb) begin
	   rbtimer_a <= 1'b1;
	   rbtimer_b <= 1'b1;
	end else if (t2) begin
	   if (~rbtimer_a)
	     rbtimer_b <= ~rbtimer_b;
	   rbtimer_a <= ~rbtimer_a;
	end
     end

   
   // I/O logic

   reg c0, c1, c2;
   reg	ldce_pre, last_ldce_pre, ldce_gate;
   reg	wbyt;

   assign ldce = ldce_pre && !last_ldce_pre;
   assign ldce_clear = nopfin | rstfin | lafin | rbfin | spkfin | rdbyfin | puc | (spkext & spefin);

   always @(posedge clk)
     if (clk_en) begin
	wbyt <= ws & ddis & ~c0 & !rdy && !wbyt && !bf;

	last_ldce_pre <= ldce_pre;
	ldce_pre <= ~rdy & ws & ~ddis & (ldce_clear || !(ldce || ldce_gate));

	if (ldce_clear)
	  ldce_gate <= 1'b0;
	else if (ldce)
	  ldce_gate <= 1'b1;

	if (reset) // Block command loads until power on reset is done
	   ldce_gate <= 1'b1;
     end

   // Special handling of RDY - is cleared independent of clk_en

   reg rdy_ff;
   assign rdy = rdy_ff || (!ws && !rs);
   always @(posedge clk)
     if (reset || (!ws && !rs))
       rdy_ff <= 1'b0;
     else if (clk_en)
       if (wbyt || c1 || c2 || ldce)
	 rdy_ff <= 1'b1;

   
   // Data/addr reg

   reg         rdby_ff, rdbyfin_ff;
   reg	       last_c1;
   reg	       last_rs;
   reg [0:7]   data_reg;
   assign dq = ({8{c1}} & data_reg) | ({8{c2}} & { talkst, bl, be, 5'b00000 });
   
   always @(posedge clk) begin
      if (reset) begin
	 add_out <= 4'h0;
	 i02 <= 1'b0;
      end
      if (clk_en) begin
	 if (c0)
	   data_reg <= { data_reg[1:7], add8_in };
	 if (ldce)
	   add_out <= dd[4:7];

	 c0 <= i02;
	 i02 <= (rdbyen | rdbyen_pre) & todd;
	 last_c1 <= c1;
	 c1 <= rdbyfin_ff & rs;
	 if (rdbyfin)
	   rdbyfin_ff <= 1'b1;
	 if (!c1 && last_c1)
	   rdbyfin_ff <= 1'b0;
	 c2 <= !(rdby || rdby_ff) && rs;
	 if (rdby)
	   rdby_ff <= 1'b1;
	 if (!c1 && last_c1)
	   rdby_ff <= 1'b0;

	 if (puc | rst) begin
	    rdby_ff <= 1'b0;
	    rdbyfin_ff <= 1'b0;
	 end
      end // if (clk_en)
      if (last_rs && !rs) begin
	 c1 <= 1'b0;
	 c2 <= 1'b0;
	 rdbyfin_ff <= 1'b0;
	 rdby_ff <= 1'b0;
      end
      last_rs <= rs;
   end


   // Talk enable

   reg last_bl;
   reg bl_negedge;
   always @(posedge clk)
     if (reset) begin
	spen <= 1'b0;
     end else if (clk_en) begin
	last_bl <= bl;
	bl_negedge <= last_bl & ~bl;
	if (tcon) // Talk has started, no need to enable it anymore
	  spen <= 1'b0;
	if ((bl_negedge & spkext) | (spk & spkfin))
	  spen <= 1'b1;
     end


   // Parameter loading, storage and decoding logic

   reg resetl;
   reg tc;
   reg en;
   reg [11:0] pshift;
   reg	decodef;
   reg	rpt;
   reg	p_eq_0 = 1'b1, e_eq_0 = 1'b1;
   reg	oldp = 1'b1, olde = 1'b1;
   reg	zpar;
   reg	inhibit;
   reg	last_tp;
   wire	decode0;
   wire	talk;
   wire	in0, in1, in2, in3, in4, in5;
   wire [5:0] cr;
   wire [9:0] prom_data;
   wire	parin;
   reg	latche;
   assign decode0 = pc0 & t16 & ~in0 & ~in1 & ~in2 & ~in3;
   assign talk = ~(puc | rst | tc | decodef);
   assign in0 = parin;
   assign in1 = pshift[1];
   assign in2 = pshift[3];
   assign in3 = pshift[5];
   assign in4 = pshift[7];
   assign in5 = pshift[9];

   always @(posedge clk)
      if (clk_en) begin
	 resetl <= t20 & pc_eq_12 & ic_eq_7;
	 tc <= be && ddis;
	 if (spen && resetl)
	   tcon <= 1'b1;
	 if (~talk)
	   tcon <= 1'b0;
	 if (resetl)
	   talkd <= tcon;
	 if (rst)
	   talkd <= 1'b0;
	 en <= ~((p_eq_0 & pc_gt_5) | e_eq_0 | rpt |
		 ~tcon); // Note: patent has talk here
	 if (resetl) begin
	    rpt <= 1'b0;
	    p_eq_0 <= 1'b0;
	    e_eq_0 <= 1'b0;
	 end else begin
	    if (t16 && pshift[11] && pc_eq_1 && pc0)
	      rpt <= 1'b1;
	    if (~in4 && ~in5 && pc_eq_1 && decode0 && latche)
	      p_eq_0 <= 1'b1;
	    if (pc_eq_0 && decode0 && latche)
	      e_eq_0 <= 1'b1;
	 end
	 if (ic_eq_7 & t17 & pc_eq_12) begin
	    oldp <= p_eq_0;
	    olde <= e_eq_0;
	 end
	 zpar <= (oldp & pc_gt_5) | ~talkd;
	 inhibit <= (olde & ~e_eq_0) || (p_eq_0 != oldp);
	 
	 decodef <= div1 & pc_eq_0 & t16 & pc0 & in0 & in1 & in2 & in3;
	 pshift <= { pshift[10:0], parin };
	 last_tp <= tp;

	 if (~pc0 && (tk || te10 || last_tp))
	   poshift <= prom_data;
	 else
	   poshift <= { prom_data[9], poshift[9:1] };
      end

   tms5200_pram pram(.clk(clk), .clk_en(clk_en),
		     .load_ram(div1 & t16 & pc0 & en),
		     .in({in5, in4, in3, in2, in1, in0}),
		     .pc(pc[4:1]), .cr(cr));

   tms5200_prom prom(.clk(clk), .clk_en(clk_en), .addr({pc[4:1], cr}),
		     .output_transfer(t19), .out(prom_data));
   

   // Parameter interpolator

   wire interp_adder_a;
   reg	interp_adder_b;
   reg	interp_adder_out, interp_adder_carry, interp_adder_carry_last;
   wire interp_subber_a, interp_subber_b;
   reg	interp_subber_out, interp_subber_carry, interp_subber_carry_last;
   reg [0:1] interp_feedback_sr;
   wire	     interp_fb_gate;
   reg	     interp_fb_filter;
   reg	     interp_fb_sel;
   reg	     interp_fb_acyc;
   reg [2:0] interp_delay1_sr;
   wire interp_delay1_in, interp_delay1_out;
   reg [2:0] interp_delay2_sr;
   wire interp_delay2_in, interp_delay2_out;
   reg [3:0] interp_out_sr;
   wire [3:0] interp_out_sr_next;
   reg [9:0] pitch_reg = 0;
   reg new_pitch;
   reg interpolate_pitch;
   wire	aa, bb, cc;
   wire	crykl;
   wire [9:0] transfer_next;

   assign interp_delay1_in = interp_feedback_sr[1];
   assign interp_delay1_out = (div1 & interp_delay1_in) |
			      (div2 & interp_delay1_sr[0]) |
			      (div4 & interp_delay1_sr[1]) |
			      (div8 & interp_delay1_sr[2]);
   assign interp_adder_a = interp_delay1_out;
   assign interp_subber_a = ~interp_fb_gate;
   assign interp_subber_b = promout;
   assign interp_delay2_in = interp_adder_out ^ interp_adder_carry_last;
   assign interp_delay2_out = (div8 & interp_delay2_in) |
			      (div4 & interp_delay2_sr[0]) |
			      (div2 & interp_delay2_sr[1]) |
			      (div1 & interp_delay2_sr[2]);
   assign bb = ((~tk & ~te10) | pc0);
   assign cc = interp_out_sr[3];
   assign interp_out_sr_next[0] = interp_delay2_out & ~zpar;
   assign interp_out_sr_next[3:1] = ( bb ? interp_out_sr[2:0] :
				      {3{transfer_next[9]}} );
   assign interp_fb_gate = interp_fb_sel & interp_fb_filter & interp_fb_acyc;
   assign crykl = (tk || te10 || last_tp);

   always @(posedge clk)
      if (clk_en) begin
	 pitch_reg <= { (new_pitch ? interp_out_sr_next[3] : pitch_reg[0]),
			pitch_reg[9:1] };
	 interp_out_sr <= interp_out_sr_next;
	 if (pc_eq_1 & t1 & pc0)
	   new_pitch <= 1'b1;
	 if (pc0 && tp)
	   new_pitch <= 1'b0;
	 if (t1 && pc_eq_1)
	   interpolate_pitch <= 1'b0;
	 if (tp && !pc0)
	   interpolate_pitch <= 1'b1;

	 interp_delay1_sr <= { interp_delay1_sr[1:0], interp_delay1_in };
	 interp_delay2_sr <= { interp_delay2_sr[1:0], interp_delay2_in };
	 interp_adder_out <= interp_adder_a ^ interp_adder_b;
	 interp_adder_carry_last <= interp_adder_carry;
	 interp_adder_carry <= (interp_adder_a & interp_adder_b) |
			       (interp_adder_a & interp_adder_carry) |
			       (interp_adder_b & interp_adder_carry);
	 if (crykl || (inhibit && !div1))
	   interp_adder_b <= 1'b0;
	 else
	   interp_adder_b <= interp_subber_out ^ interp_subber_carry_last;
	 interp_subber_out <= interp_subber_a ^ interp_subber_b;
	 interp_subber_carry_last <= interp_subber_carry;
	 interp_subber_carry <= (interp_subber_a & interp_subber_b) |
				(interp_subber_a & interp_subber_carry) |
				(interp_subber_b & interp_subber_carry) |
				crykl;
	 interp_feedback_sr <= { interp_fb_gate, interp_feedback_sr[0] };
	 interp_fb_sel <= ( interpolate_pitch ? pitch_reg[0] : aa );
	 interp_fb_filter <= (interpolate_pitch | ~pc_eq_1);
	 if (crykl)
	   interp_fb_acyc <= ~pc0;
      end


   // K-stack / E10 loop

   reg [8:0] ke10_transfer_reg = 0;
   reg [19:0] e10_loop = 0;
   wire [9:0] kstack_out;
   assign transfer_next = ( bb ? { cc, ke10_transfer_reg } :
			    ( tk ? kstack_out : e10_loop[9:0] ) );
   assign aa = transfer_next[0];

   always @(posedge clk)
      if (clk_en) begin
	 ke10_transfer_reg <= transfer_next[9:1];
	 if (pc0 && te10)
	   e10_loop <= { ke10_transfer_reg[0], e10_loop[19:10],
			 cc, ke10_transfer_reg[8:1] };
	 else
	   e10_loop <= { e10_loop[0], e10_loop[19:1] };
      end

   wire [4:0] p1_stage;
   wire [4:0] m1_stage;
   wire [4:1] p2_stage;
   wire [4:0] m2_stage;
   
   tms5200_kstack
     kstack(.clk(clk), .clk_en(clk_en),
	    .kin((pc0 && (tk || te10)) ? { cc, ke10_transfer_reg } :
		 ((t10 || t20) ? e10_loop[9:0] : kstack_out)),
	    .kout(kstack_out), .p1_stage(p1_stage), .m1_stage(m1_stage),
	    .p2_stage(p2_stage), .m2_stage(m2_stage));


   // Excitation generator

   reg       t12;
   reg [8:0] chirp_addr_sr;
   reg	     chirp_comparator_carry;
   reg	     chirp_addr_reset;
   reg	     chirp_inhibit;
   reg	     chirp_adder_output;
   reg	     chirp_adder_carry;

   wire [13:6] i;
   wire	       im1, im2;
   reg	       im1_ff, im2_ff;
   reg [12:0]  rans = ~13'd0;

   assign i[13] = im2_ff;
   assign i[12] = im1_ff;

   always @(posedge clk)
      if (clk_en) begin
	 t12 <= t11;

	 chirp_addr_sr <= { chirp_adder_output & ~chirp_addr_reset &
			    ~chirp_inhibit, chirp_addr_sr[8:1] };
	 chirp_adder_output <= chirp_addr_sr[0] ^ chirp_adder_carry;
	 if (t1 || ~chirp_addr_sr[0])
	   chirp_adder_carry <= 1'b0;
	 if (t11)
	   chirp_adder_carry <= 1'b1;
	 if (t2 & ~chirp_comparator_carry)
	   chirp_addr_reset <= 1'b1;
	 if (t12)
	   chirp_addr_reset <= 1'b0;
	 if (t11)
	   chirp_comparator_carry <= 1'b0;
	 else begin
	    if (pitch_reg[0] & ~chirp_addr_sr[0])
	      chirp_comparator_carry <= 1'b1;
	    if (~pitch_reg[0] & chirp_addr_sr[0])
	      chirp_comparator_carry <= 1'b0;
	 end
	 if (t12 && ic_eq_7 && pc_eq_12 && inhibit)
	   chirp_inhibit <= 1'b1;
	 if (t12 && div1)
	   chirp_inhibit <= 1'b0;
	 rans <= { rans[0] | puc | rst, rans[12:4],
		   rans[3] ^ rans[12], rans[2] ^ rans[12],
		   rans[1] ^ (rans[0] | puc | rst) };
	 im1_ff <= im1 | oldp;
	 im2_ff <= im2 | (oldp & rans[0]);
      end   

   tms5200_crom crom(.clk(clk), .clk_en(clk_en),
		     .addr(chirp_addr_sr), .addr_en(t12),
		     .out({im2, im1, i[11:6]}));


   // Filter

   reg [13:0] mr_delay;
   reg [13:0] accumulator;
   wire [13:0] accumulator_in;
   wire [13:0] p;
   wire [13:0] bstack_out;

   assign accumulator_in = ({14{t10_to_t18}} & accumulator) |
			   ({14{~(t10_to_t18 | t19 | t8)}} & bstack_out) |
			   ({14{t8}} & yl);
   always @(posedge clk)
      if (clk_en) begin
	 if (t10)
	   mr_delay <= { i, 6'b000000 };
	 else if (t8)
	   mr_delay <= bstack_out;
	 else if (~t1_to_t9)
	   mr_delay <= accumulator;
	 if (t9_to_t18)
	   accumulator <= accumulator_in - p;
	 else
	   accumulator <= accumulator_in + p;
	 if (t8)
	   yl <= bstack_out;
      end

   tms5200_multiplier mult(.clk(clk), .clk_en(clk_en),
			   .p1_stage(p1_stage), .m1_stage(m1_stage),
			   .p2_stage(p2_stage), .m2_stage(m2_stage),
			   .mr((t1_to_t9 ? accumulator : mr_delay)), .p(p));

   tms5200_bstack bstack(.clk(clk), .clk_en(clk_en), .shift_en(~t10_to_t18),
			 .bin(accumulator), .bout(bstack_out));


   // Load speech logic

   reg lchen, lchen_pre, latche_pre;
   reg sse;
   wire	fifdso;
   assign parin = latche & (ddis ? fifdso & ~sse : add8_in);
   always @(posedge clk)
      if (clk_en) begin
	 latche <= latche_pre;
	 latche_pre <= lchen;

	 if (lchen_pre)
	   lchen <= 1'b1;
	 if (t14 || !en)
	   lchen <= 1'b0;
	 lchen_pre <= ldp & pc0 & div1;
      end

   
   // FIFO control
   
   reg       clr;
   reg [0:3] bytr_cnt;
   wire	     bytr;

   assign bytr = sse & bytr_cnt[2] & !bytr_cnt[3];
   always @(posedge clk)
     if (clk_en) begin
	if (clr)
	  bytr_cnt <= 4'b1111;
	else if(sse)
	  bytr_cnt <= { ~bytr_cnt[3], bytr_cnt[0:2] };
	clr <= puc | rst | spkee;
     end
   
   tms5200_fifo fifo(.clk(clk), .clk_en(clk_en), .df(dd),
		     .wbyt(wbyt), .bytr(bytr), .clr(clr), .shift(sse),
		     .fifdso(fifdso), .be(be), .bl(bl), .bf(bf));

   // I0 logic
   
   reg sse_pre;
   always @(posedge clk)
      if (clk_en) begin
	 sse <= sse_pre & ddis;
	 sse_pre <= lchen_todd;
	 lchen_todd <= lchen & todd;
      end   


   // INT logic

   reg last_be;
   reg be_trigger, bl_trigger, talkst_trigger;
   
   always @(posedge clk)
      if (clk_en) begin
	 if (be_trigger || bl_trigger || talkst_trigger)
	   int <= 1'b1;
	 if (rst || c2)
	   int <= 1'b0;
	 be_trigger <= be & ~last_be;
	 bl_trigger <= bl & ~last_bl;
	 talkst_trigger <= ~talkst & last_talkst;
	 last_be <= be;
      end   

   
endmodule // tms5200_vsp
