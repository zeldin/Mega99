module tms9900_cpu(input reset,
		   input	     clk, // Enabled cycles should give
		   input	     clk_en, // main CPU clock, 3.579545 MHz

		   // Note, memen_out will go low on the first clk cycle
		   // after both memen_out and ready_in being high
		   // (the one in which data is expected on d_in for a
		   // read cycle), but a, q, we, dbin and iaq will remain valid
		   // for at least one more clk cycle like on a real TMS9900
		   output	     memen_out,
		   output reg	     we,
		   output reg	     iaq,
		   output	     dbin,
		   input	     ready_in,
		   output	     waiting, // "wait" is a reserved word...
		   output [0:14]     a,
		   input [0:15]	     d_in,
		   output reg [0:15] q,

		   input	     cruin,
		   output reg	     cruout,
		   output	     cruclk_out,

		   input	     intreq,
		   input [0:3]	     ic,
		   input	     hold,
		   output reg	     holda,
		   input	     load,

		   output [0:15]     debug_pc,
		   output [0:15]     debug_st,
		   output [0:15]     debug_wp,
		   output [0:15]     debug_ir
		   );

   // FSM ("microcode") states (a kingdom for an enum!)
   localparam [0:6] S_RESET = 0;
   localparam [0:6] S_INTREQ_1 = 1;
   localparam [0:6] S_INTREQ_2 = 2;
   localparam [0:6] S_INTREQ_3 = 3;
   localparam [0:6] S_INTREQ_4 = 4;
   localparam [0:6] S_INTREQ_5 = 5;
   localparam [0:6] S_INTREQ_6 = 6;
   localparam [0:6] S_INTREQ_7 = 7;
   localparam [0:6] S_INTREQ_8 = 8;
   localparam [0:6] S_INTREQ_9 = 9;
   localparam [0:6] S_INTREQ_10 = 10;
   localparam [0:6] S_INTREQ_11 = 11;
   localparam [0:6] S_IFETCH_NOIRQ = 12;
   localparam [0:6] S_IFETCH = 13;
   localparam [0:6] S_LOAD_IR = 14;
   localparam [0:6] S_DECODE = 15;
   localparam [0:6] S_ILLEGAL = 16;
   localparam [0:6] S_GET_IOP_1 = 17;
   localparam [0:6] S_GET_IOP_2 = 18;
   localparam [0:6] S_GET_IOP_3 = 19;
   localparam [0:6] S_IOP = 20;
   localparam [0:6] S_IOP_WRITEBACK = 21;
   localparam [0:6] S_LIMI_1 = 22;
   localparam [0:6] S_LIMI_2 = 23;
   localparam [0:6] S_LIMI_3 = 24;
   localparam [0:6] S_STWP_STST_1 = 25;
   localparam [0:6] S_STWP_STST_2 = 26;
   localparam [0:6] S_JUMP_1 = 27;
   localparam [0:6] S_JUMP_2 = 28;
   localparam [0:6] S_JUMP_3 = 29;
   localparam [0:6] S_GET_TS = 30;
   localparam [0:6] S_GET_TS_INDIR_1 = 31;
   localparam [0:6] S_GET_TS_INDIR_2 = 32;
   localparam [0:6] S_GET_TS_AUTOINC_1 = 33;
   localparam [0:6] S_GET_TS_AUTOINC_2 = 34;
   localparam [0:6] S_GET_TS_AUTOINC_3 = 35;
   localparam [0:6] S_GET_TS_AUTOINC_4 = 36;
   localparam [0:6] S_GET_TS_INDEXED_1 = 37;
   localparam [0:6] S_GET_TS_INDEXED_2 = 38;
   localparam [0:6] S_GET_TS_INDEXED_3 = 39;
   localparam [0:6] S_GET_TS_INDEXED_4 = 40;
   localparam [0:6] S_TS_COMPLETE = 41;
   localparam [0:6] S_GET_TD = 42;
   localparam [0:6] S_GET_TD_INDIR_1 = 43;
   localparam [0:6] S_GET_TD_INDIR_2 = 44;
   localparam [0:6] S_GET_TD_AUTOINC_1 = 45;
   localparam [0:6] S_GET_TD_AUTOINC_2 = 46;
   localparam [0:6] S_GET_TD_AUTOINC_3 = 47;
   localparam [0:6] S_GET_TD_AUTOINC_4 = 48;
   localparam [0:6] S_GET_TD_INDEXED_1 = 49;
   localparam [0:6] S_GET_TD_INDEXED_2 = 50;
   localparam [0:6] S_GET_TD_INDEXED_3 = 51;
   localparam [0:6] S_GET_TD_INDEXED_4 = 52;
   localparam [0:6] S_DUAL_MULTI_OP_1 = 53;
   localparam [0:6] S_DUAL_MULTI_OP_2 = 54;
   localparam [0:6] S_DUAL_MULTI_OP_3 = 55;
   localparam [0:6] S_SHIFT_1 = 56;
   localparam [0:6] S_SHIFT_2 = 57;
   localparam [0:6] S_SHIFT_3 = 58;
   localparam [0:6] S_SHIFT_4 = 59;
   localparam [0:6] S_SHIFT_5 = 60;
   localparam [0:6] S_SHIFT_6 = 61;
   localparam [0:6] S_SHIFT_7 = 62;
   localparam [0:6] S_SHIFT_8 = 63;
   localparam [0:6] S_SHIFT_9 = 64;
   localparam [0:6] S_BL_1 = 65;
   localparam [0:6] S_BL_2 = 66;
   localparam [0:6] S_B = 67;
   localparam [0:6] S_SINGLE_OP_1 = 68;
   localparam [0:6] S_SINGLE_OP_2 = 69;
   localparam [0:6] S_SINGLE_OP_3 = 70;
   localparam [0:6] S_SINGLE_OP_4 = 71;
   localparam [0:6] S_BIT_OP_1 = 72;
   localparam [0:6] S_BIT_OP_2 = 73;
   localparam [0:6] S_BIT_OP_3 = 74;
   localparam [0:6] S_BIT_OP_4 = 75;
   localparam [0:6] S_XOP_1 = 76;
   localparam [0:6] S_XOP_2 = 77;
   localparam [0:6] S_XOP_3 = 78;
   localparam [0:6] S_XOP_4 = 79;
   localparam [0:6] S_XOP_5 = 80;
   localparam [0:6] S_XOP_6 = 81;
   localparam [0:6] S_XOP_7 = 82;
   localparam [0:6] S_CRU_SINGLE_1 = 83;
   localparam [0:6] S_CRU_SINGLE_2 = 84;
   localparam [0:6] S_RTWP_1 = 85;
   localparam [0:6] S_RTWP_2 = 86;
   localparam [0:6] S_RTWP_3 = 87;
   localparam [0:6] S_RTWP_4 = 88;
   localparam [0:6] S_RTWP_5 = 89;
   localparam [0:6] S_EXTOP_1 = 90;
   localparam [0:6] S_EXTOP_2 = 91;
   localparam [0:6] S_EXTOP_3 = 92;
   localparam [0:6] S_EXTOP_4 = 93;
   localparam [0:6] S_CRU_MULTIPLE_1 = 94;
   localparam [0:6] S_CRU_MULTIPLE_2 = 95;
   localparam [0:6] S_CRU_MULTIPLE_3 = 96;
   localparam [0:6] S_CRU_MULTIPLE_4 = 97;
   localparam [0:6] S_CRU_MULTIPLE_5 = 98;
   localparam [0:6] S_MPY_1 = 99;
   localparam [0:6] S_MPY_2 = 100;
   localparam [0:6] S_MPY_3 = 101;
   localparam [0:6] S_MPY_4 = 102;
   localparam [0:6] S_MPY_5 = 103;
   localparam [0:6] S_MPY_6 = 104;
   localparam [0:6] S_MPY_7 = 105;
   localparam [0:6] S_MPY_8 = 106;
   localparam [0:6] S_DIV_1 = 107;
   localparam [0:6] S_DIV_2 = 108;
   localparam [0:6] S_DIV_3 = 109;
   localparam [0:6] S_DIV_4 = 110;
   localparam [0:6] S_DIV_5 = 111;
   localparam [0:6] S_DIV_6 = 112;
   localparam [0:6] S_DIV_7 = 113;
   localparam [0:6] S_DIV_8 = 114;
   localparam [0:6] S_DIV_9 = 115;
   localparam [0:6] S_DIV_10 = 116;
   localparam [0:6] S_DIV_11 = 117;
   localparam [0:6] S_DIV_12 = 118;
   localparam [0:6] S_DIV_13 = 119;
   localparam [0:6] S_DIV_14 = 120;

   reg [0:6]  state;
   reg	      phase;
   reg	      idling;

   reg [0:15] pc;
   reg [0:15] st;
   reg [0:15] wp;
   reg [0:15] ir;
   
   reg [0:15] addr;
   reg [0:15] operand;
   reg [0:15] extra;
   reg	      bytemode;
   reg [0:3]  c;

   wire [0:15] d;
   wire	       ready;
   reg	       memen;
   reg	       cruclk;
   reg	       cru_cycle;
   reg	       mem_complete;
   reg	       d_live;
   reg [0:15]  d_latch;
   reg	       cruin_latch;
   
   assign waiting = memen && !ready;
   assign a = addr[0:14];
   assign d = (d_live ? d_in : d_latch);
   assign memen_out = memen && !mem_complete && !holda;
   assign ready = mem_complete | ready_in;
   assign cruclk_out = clk_en && cruclk && !holda;
   assign dbin = (memen && !we) || holda;

   assign debug_pc = pc;
   assign debug_st = st;
   assign debug_wp = wp;
   assign debug_ir = ir;

   function automatic [0:15] wpaddr(input [0:3] r);
      begin
	 wpaddr = wp + { 11'd0, r, 1'b0 };
      end
   endfunction // wpaddr

   always @(posedge clk) begin

      if (reset)
	d_latch <= 16'h0000;
      else if (d_live)
	d_latch <= d_in;
      if (reset || !memen || holda) begin
	 mem_complete <= 1'b0;
	 d_live <= 1'b0;
      end else if (!mem_complete && ready_in) begin
	 mem_complete <= 1'b1;
	 d_live <= ~we;
      end else
	d_live <= 1'b0;

     if (reset && clk_en) begin
	memen <= 1'b0;
	we <= 1'b0;
	iaq <= 1'b0;
	phase <= 1'b0;
	state <= S_RESET;
	holda <= 1'b0;
	idling <= 1'b0;
	cruclk <= 1'b0;
	cru_cycle <= 1'b0;
     end else if (clk_en) begin
	if (phase == 1'b1) begin
	   if (cru_cycle && !holda) begin
	      /*
	      if (!cruclk)
		$display("CRU in %0d @ %03x", cruin, a[3:14]);
	       */
	      cruclk <= 1'b0;
	      cru_cycle <= 1'b0;
	      cruin_latch <= cruin;
	   end
	   if (memen) begin
	      if (ready && !holda) begin
		 phase <= 1'b0;
		 memen <= 1'b0;
	      end
	   end else begin
	      if (!(cru_cycle && holda))
		phase <= 1'b0;
	      if (hold)
		holda <= 1'b1;
	   end
	   if (!hold)
	     holda <= 1'b0;
	   case (state)
	     S_DECODE: begin
		bytemode <= 1'b0;
		if (ir[0:2] != 3'b000) begin
		   if (ir[0:1] != 2'b00)
		     bytemode <= ir[3];
		  state <= S_GET_TS;
		end else if (ir[3] == 1'b1)
		  state <= S_JUMP_1;
		else if (ir[4] == 1'b1) begin
		   c <= ir[8:11];
		   if (ir[5] == 1'b1)
		     state <= S_ILLEGAL; // illegal op
		   else
		     state <= S_SHIFT_1;
		end else if (ir[5] == 1'b1) begin
		   if (ir[6:8] == 3'b111)
		     state <= S_ILLEGAL; // illegal op
		   else
		     state <= S_GET_TS;
		end else if (ir[6] == 1'b1) begin
		   if (ir[7] == 1'b1) begin
		      if (ir[8:9] != 2'b00) begin
			 if (ir[9:10] == 2'b00)
			   state <= S_RTWP_1; // RTWP
			 else
			   state <= S_EXTOP_1;
		      end else if (ir[10] == 1'b0)
			state <= S_GET_IOP_1; // LIMI
		      else
			state <= S_ILLEGAL; // illegal op
		   end else begin // if (ir[7] == 1'b1)
		      if (ir[8:10] == 3'b101 || ir[8:10] == 3'b110)
			state <= S_STWP_STST_1; // STWP / STST
		      else
			state <= S_GET_IOP_1; // LI/AI/ANDI/ORI/CI / LWPI
		   end
		end else // if (ir[6] == 1'b1)
		  state <= S_ILLEGAL; // illegal op
	     end
	     S_TS_COMPLETE: begin
		if (ir[0:1] != 2'b00)
		  state <= S_GET_TD;
		else if (ir[2] == 1'b1) begin
		   if (ir[3])
		     case (ir[4:5])
		       2'b00, 2'b01: begin
			  // LDCR / STCR
			  c <= ir[6:9];
			  if (ir[6:9] != 4'd0 && ir[6:9] <= 4'd8)
			    bytemode <= 1'b1;
			  state <= S_CRU_MULTIPLE_1;
		       end
		       2'b10: state <= S_MPY_1;
		       2'b11: state <= S_DIV_1;
		     endcase // case (ir[4:5])
		   else if(ir[4:5] == 2'b11)
		     state <= S_XOP_1; // XOP
		   else
		     state <= S_BIT_OP_1; // COC / CZC / XOR
		end else 
		  case (ir[6:9])
		    4'b0000: state <= S_INTREQ_2; // BLWP
		    4'b0001: state <= S_B; // B
		    4'b0010: state <= S_LOAD_IR; // X
		    4'b1010: state <= S_BL_1; // BL
		    default: state <= S_SINGLE_OP_1; // CLR/NEG/INV/INC(T)/DEC(T)/SWPB/SETO/ABS
		  endcase // case (ir[6:9])
	     end // case: S_TS_COMPLETE

	     // A(B) / C(B) / S(B) / SOC(B) / SZC(B) / MOV(B)
	     S_DUAL_MULTI_OP_2: begin
		if (bytemode) begin
		   // byte operand
		   q <= { (addr[15] ? d_latch[8:15] : d_latch[0:7]), 8'h00 };
		   if (addr[15])
		     d_latch <= { d_latch[8:15], d_latch[0:7] };
		end else
		  q <= d_latch;
	     end
	     // CLR / NEG / INV / INC(T) / DEC(T) / SWPB / SETO / ABS
	     S_SINGLE_OP_4:
	       case (ir[6:9])
		 4'b0011: q <= 16'h0000; // CLR
		 4'b0100: { st[3], q } <= 17'h00001 + { 1'b0, ~d_latch }; // NEG
		 4'b0101: q <= ~d_latch; // INV
		 4'b0110: { st[3], q } <= { 1'b0, d_latch } + 17'd1; // INC
		 4'b0111: { st[3], q } <= { 1'b0, d_latch } + 17'd2; // INCT
		 4'b1000: { st[3], q } <= { 1'b0, d_latch } + 17'hffff; // DEC
		 4'b1001: { st[3], q } <= { 1'b0, d_latch } + 17'hfffe; // DECT
		 4'b1011: q <= { d_latch[8:15], d_latch[0:7] }; // SWPB
		 4'b1100: q <= 16'hffff; // SETO
		 4'b1101: q <= d_latch; // ABS
	       endcase // case (ir[6:9])
	   endcase // case (state)
	end else begin
	   phase <= 1'b1;
	   state <= state + 7'd1;
	   we <= 1'b0;
	   iaq <= 1'b0;
	   
	   case (state)
	     S_RESET: begin
		pc <= 16'h0000;
		st <= 16'h0000;
		wp <= 16'h0000;
		addr <= 16'h0000;
	     end
	     S_INTREQ_1: begin
		memen <= 1'b1;
	     end
	     S_INTREQ_2: begin
		q <= wp;
		wp <= d;
		extra <= addr + 16'd2;
		extra[15] <= 1'b0;
	     end
	     S_INTREQ_4: begin
		addr <= wpaddr(4'd13);
		memen <= 1'b1;
		we <= 1'b1;
	     end
	     S_INTREQ_5:
		q <= pc;
	     S_INTREQ_6: begin
		addr <= wpaddr(4'd14);
		memen <= 1'b1;
		we <= 1'b1;
	     end
	     S_INTREQ_7:
		q <= st;
	     S_INTREQ_8: begin
		addr <= wpaddr(4'd15);
		memen <= 1'b1;
		we <= 1'b1;
	     end
	     S_INTREQ_10: begin
		if (extra[15])
		  st[6] <= 1'b1; // XOP
		addr <= extra;
		memen <= 1'b1;
	     end
	     S_INTREQ_11:
		pc <= d;

	     S_IFETCH_NOIRQ: begin
		if (load) begin
		   state <= S_INTREQ_1;
		   addr <= 16'hfffc;
		end else begin
		   addr <= pc;
		   pc <= pc + 16'd2;
		   memen <= 1'b1;
		   iaq <= 1'b1;
		   state <= S_LOAD_IR;
		end
	     end
	     S_IFETCH: begin
		if (load) begin
		   state <= S_INTREQ_1;
		   addr <= 16'hfffc;
		   idling <= 1'b0;
		end else if (intreq && ic <= st[12:15]) begin
		   state <= S_INTREQ_1;
		   addr <= { 10'h000, ic, 2'b00 };
		   idling <= 1'b0;
		end else if (idling)
		  state <= S_IFETCH;
		else begin
		   addr <= pc;
		   pc <= pc + 16'd2;
		   memen <= 1'b1;
		   iaq <= 1'b1;
		end
	     end
	     S_LOAD_IR: begin
		ir <= d;
		state <= S_DECODE; // Decode happens in phase 1
	     end
	     S_ILLEGAL: state <= S_IFETCH;

	     // AI / ANDI / CI / LI / ORI / LWPI / LIMI
	     S_GET_IOP_1: begin
		addr <= pc;
		pc <= pc + 16'd2;
		memen <= 1'b1;
	     end
	     S_GET_IOP_2: begin
		operand <= d;
		addr <= wpaddr(ir[12:15]);
		if (ir[8:10] == 3'b000 || ir[8:10] == 3'b111)
		  state <= S_IOP;
		else
		  memen <= 1'b1;
	     end
	     S_IOP:
	       if (ir[7])
		 state <= S_LIMI_1; // LIMI
	       else if (ir[8:10] == 3'b111) begin
		  // LWPI
		  wp <= operand;
		  state <= S_IFETCH;
	       end else begin
		case (ir[8:10])
		  3'b000: q <= operand; // LI
		  3'b001: {st[3], q} <= {1'b0, operand} + {1'b0, d_latch}; // AI
		  3'b010: q <= operand & d_latch; // ANDI
		  3'b011: q <= operand | d_latch; // ORI
		  3'b100: q <= operand - d_latch; // CI
		endcase // case (ir[8:10])
	     end
	     S_IOP_WRITEBACK: begin
		if (ir[8:10] == 3'b001)
		  // AI
		  st[4] <= (d_latch[0] == operand[0]) && (d_latch[0] != q[0]);
		st[2] <= ~|q;
		if (ir[8]) begin
		   // CI
		   st[1] <= (!d_latch[0] && operand[0]) ||
			    (d_latch[0] == operand[0] && q[0]);
		   st[0] <= (d_latch[0] && !operand[0]) ||
			    (d_latch[0] == operand[0] && q[0]);
		end else begin
		   st[1] <= !q[0] && |q;
		   st[0] <= |q;
		   memen <= 1'b1;
		   we <= 1'b1;
		end
		state <= S_IFETCH;
	     end // case: S_IOP_WRITEBACK
	     S_LIMI_1: st[12:15] <= operand[12:15];
	     S_LIMI_3: state <= S_IFETCH;

	     // STST / STWP
	     S_STWP_STST_1: begin
		if (ir[10])
		  q <= wp;
		else
		  q <= st;
		addr <= wpaddr(ir[12:15]);
	     end
	     S_STWP_STST_2: begin
		memen <= 1'b1;
		we <= 1'b1;
		state <= S_IFETCH;
	     end

	     // JEQ / JGT / JH / JHE / JL / JLE / JLT / JMP / JNC / JNE / JNO / JOC / JOP
	     S_JUMP_1: begin
		operand <= { {8{ir[8]}}, ir[8:15] };
		if (ir[4:5] == 2'b11 && ir[6:7] != 2'b00) begin
		   // SBO / SBZ / TB
		   addr <= wpaddr(4'd12);
		   memen <= 1'b1;
		end
	     end
	     S_JUMP_2: begin
		case (ir[4:7])
		  4'b0001: if (st[1] != 1'b0 || st[2] != 1'b0) state <= S_IFETCH;
		  4'b0010: if (st[0] != 1'b0 && st[2] != 1'b1) state <= S_IFETCH;
		  4'b0011: if (st[2] != 1'b1) state <= S_IFETCH;
		  4'b0100: if (st[0] != 1'b1 && st[2] != 1'b1) state <= S_IFETCH;
		  4'b0101: if (st[1] != 1'b1) state <= S_IFETCH;
		  4'b0110: if (st[2] != 1'b0) state <= S_IFETCH;
		  4'b0111: if (st[3] != 1'b0) state <= S_IFETCH;
		  4'b1000: if (st[3] != 1'b1) state <= S_IFETCH;
		  4'b1001: if (st[4] != 1'b0) state <= S_IFETCH;
		  4'b1010: if (st[0] != 1'b0 || st[2] != 1'b0) state <= S_IFETCH;
		  4'b1011: if (st[0] != 1'b1 || st[2] != 1'b0) state <= S_IFETCH;
		  4'b1100: if (st[5] != 1'b1) state <= S_IFETCH;
		  4'b1101, 4'b1110, 4'b1111: state <= S_CRU_SINGLE_1; // SBO / SBZ / TB
		endcase // case (ir[4:7])
	     end
	     S_JUMP_3: begin
		pc <= pc + { operand[1:15], 1'b0 };
		state <= S_IFETCH;
	     end

	     // TS operand decode & fetch
	     S_GET_TS: begin
		addr <= wpaddr(ir[12:15]);
		memen <= 1'b1;
		case (ir[10:11])
		  2'b00: state <= S_TS_COMPLETE;
		  2'b01: state <= S_GET_TS_INDIR_1;
		  2'b10: begin
		     state <= S_GET_TS_INDEXED_1;
		     if (ir[12:15] == 4'h0)
		       memen <= 1'b0;
		  end
		  2'b11: state <= S_GET_TS_AUTOINC_1;
		endcase // case (ir[10:11])
	     end // case: S_GET_TS
	     S_GET_TS_INDIR_1: addr <= d;
	     S_GET_TS_INDIR_2: begin
		memen <= 1'b1;
		state <= S_TS_COMPLETE;
	     end
	     S_GET_TS_AUTOINC_1: begin
		addr <= d;
		extra <= d;
		memen <= 1'b1;
	     end
	     S_GET_TS_AUTOINC_2: begin
		q <= (bytemode? extra + 16'd1 : extra + 16'd2);
		addr <= wpaddr(ir[12:15]);
		memen <= 1'b1;
		we <= 1'b1;
		if (bytemode) state <= S_GET_TS_AUTOINC_4;
	     end
	     S_GET_TS_AUTOINC_4: begin
		addr <= extra;
		state <= S_TS_COMPLETE;
	     end
	     S_GET_TS_INDEXED_2: begin
		if (ir[12:15] == 4'h0)
		  q = 16'h0000;
		else
		  q <= d_latch;
		addr <= pc;
		pc <= pc + 16'd2;
		memen <= 1'b1;
	     end
	     S_GET_TS_INDEXED_4: begin
		addr <= d_latch + q;
		memen <= 1'b1;
		state <= S_TS_COMPLETE;
	     end

	     // TD operand decode & fetch
	     S_GET_TD: begin
		if (bytemode) begin
		   // byte operand
		   operand[0:7] <= (addr[15] ? d[8:15] : d[0:7]);
		   operand[8:15] <= 8'h00;
		end else
		  operand <= d;
		// Get TD
		addr <= wpaddr(ir[6:9]);
		memen <= 1'b1;
		case (ir[4:5])
		  2'b00: state <= S_DUAL_MULTI_OP_1;
		  2'b01: state <= S_GET_TD_INDIR_1;
		  2'b10: begin
		     state <= S_GET_TD_INDEXED_1;
		     if (ir[6:9] == 4'h0)
		       memen <= 1'b0;
		  end
		  2'b11: state <= S_GET_TD_AUTOINC_1;
		endcase // case (ir[0:2])
	     end
	     S_GET_TD_INDIR_1: addr <= d;
	     S_GET_TD_INDIR_2: begin
		memen <= 1'b1;
		state <= S_DUAL_MULTI_OP_1;
	     end
	     S_GET_TD_AUTOINC_1: begin
		addr <= d;
		extra <= d;
		memen <= 1'b1;
	     end
	     S_GET_TD_AUTOINC_2: begin
		q <= (bytemode? extra + 16'd1 : extra + 16'd2);
		addr <= wpaddr(ir[6:9]);
		memen <= 1'b1;
		we <= 1'b1;
		if (bytemode) state <= S_GET_TD_AUTOINC_4;
	     end
	     S_GET_TD_AUTOINC_4: begin
		addr <= extra;
		state <= S_DUAL_MULTI_OP_1;
	     end
	     S_GET_TD_INDEXED_2: begin
		if (ir[6:9] == 4'h0)
		  q = 16'h0000;
		else
		  q <= d_latch;
		addr <= pc;
		pc <= pc + 16'd2;
		memen <= 1'b1;
	     end
	     S_GET_TD_INDEXED_4: begin
		addr <= d_latch + q;
		memen <= 1'b1;
		state <= S_DUAL_MULTI_OP_1;
	     end

	     // A(B) / C(B) / S(B) / SOC(B) / SZC(B) / MOV(B)
	     S_DUAL_MULTI_OP_2: begin
		case (ir[0:2])
		  3'b010: q <= q & ~operand; // SZC
		  3'b011: {st[3], q} <= {1'b0, q} + {1'b0, ~operand} + 17'd1; // S
		  3'b100: q <= q - operand; // C
		  3'b101: {st[3], q} <= {1'b0, q} + {1'b0, operand}; // A
		  3'b110: q <= operand; // MOV
		  3'b111: q <= q | operand; // SOC
		endcase // case (ir[0:1])
	     end
	     S_DUAL_MULTI_OP_3: begin
		if (ir[0:2] == 3'b101)
		  // A
		  st[4] <= (d_latch[0] == operand[0]) && (d_latch[0] != q[0]);
		else if (ir[0:2] == 3'b011)
		  // S
		  st[4] <= (d_latch[0] != operand[0]) && (d_latch[0] != q[0]);
		st[2] <= ~|q;
		if (ir[0:2] == 3'b100) begin
		   // C
		   st[1] <= (!operand[0] && d_latch[0]) ||
			    (operand[0] == d_latch[0] && q[0]);
		   st[0] <= (operand[0] && !d_latch[0]) ||
			    (operand[0] == d_latch[0] && q[0]);
		end else begin
		   st[1] <= !q[0] && |q;
		   st[0] <= |q;
		   memen <= 1'b1;
		   we <= 1'b1;
		end
		if (bytemode) begin
		   // byte operand
		   st[5] <= ((ir[0] == 1'b1 && ir[2] == 1'b0)? // C / MOV
			     ^operand[0:7] : ^q[0:7]);
		   if (addr[15]) begin
		      q[8:15] <= q[0:7];
		      q[0:7] <= d_latch[8:15];
		   end else
		     q[8:15] <= d_latch[8:15];
		end
		state <= S_IFETCH;
	     end // case: S_DUAL_MULTI_OP_3

	     // SLA / SRA / SRC / SRL
	     S_SHIFT_1: begin
		addr <= wpaddr(4'd0);
		memen <= 1'b1;
		if (c != 4'b000) begin
		   addr <= wpaddr(ir[12:15]);
		   state <= S_SHIFT_6;
		end
	     end
	     S_SHIFT_3: begin
		c <= d_latch[12:15];
		addr <= wpaddr(ir[12:15]);
		memen <= 1'b1;
	     end
	     S_SHIFT_7: begin
		q <= d_latch;
		if (ir[6:7] == 2'b10)
		  st[4] <= 1'b0;
	     end
	     S_SHIFT_8: begin
		case (ir[6:7])
		  2'b00: { q, st[3] } <= { q[0], q[0:15] }; // SRA
		  2'b01: { q, st[3] } <= { 1'b0, q[0:15] }; // SRL
		  2'b10: begin
		     if (q[0] != q[1])
		       st[4] <= 1'b1;
		     { st[3], q } <= { q, 1'b0 }; // SLA
		  end
		  2'b11: { q, st[3] } <= { q[15], q[0:15] }; // SRC
		endcase
		if (c != 4'b0001) begin
		  c <= c - 4'b0001;
		  state <= S_SHIFT_8;
		end
	     end // case: S_SHIFT_8
	     S_SHIFT_9: begin
		st[0] <= |q;
		st[1] <= !q[0] && |q;
		st[2] <= ~|q;
		we <= 1'b1;
		memen <= 1'b1;
		state <= S_IFETCH;
	     end

	     // B / BL
	     S_BL_1: begin
		operand <= addr;
		addr <= wpaddr(4'd11);
		q <= pc;
		we <= 1'b1;
		memen <= 1'b1;
	     end
	     S_BL_2:
	       addr <= operand;
	     S_B: begin
		pc <= addr;
		state <= S_IFETCH;
	     end

	     // CLR / NEG / INV / INC(T) / DEC(T) / SWPB / SETO / ABS
	     S_SINGLE_OP_1: begin
		state <= S_SINGLE_OP_4;
		case (ir[6:9])
		  4'b0100: state <= S_SINGLE_OP_3; // NEG: one extra cycle
		  4'b1101: state <= S_SINGLE_OP_2; // ABS: one or two extra
		  default: state <= S_SINGLE_OP_4;
		endcase // case (ir[6:9])
	     end
	     S_SINGLE_OP_2: begin
		if (d_latch[0] == 1'b0)
		  state <= S_SINGLE_OP_4; // ABS: Second extra only if negative
	     end
	     S_SINGLE_OP_4: begin
		memen <= 1'b1;
		we <= 1'b1;
		if (ir[6:7] != 2'b00 &&
		    ir[6:9] != 4'b1011 && ir[6:9] != 4'b1100) begin
		   case (ir[6:9])	
		     4'b0100: st[4] <= (q == 16'h8000); // NEG
		     4'b0110, 4'b0111:
		       st[4] <= (d_latch[0] == 1'b0 && q[0] == 1'b1); // INC(T)
		     4'b1000, 4'b1001:
		       st[4] <= (d_latch[0] == 1'b1 && q[0] == 1'b0); // DEC(T)
		     4'b1101: // ABS
		       if (q[0]) begin
			  st[4] <= (q == 16'h8000);
			  { st[3], q } <= 17'h00001 + { 1'b0, ~q };
			  st[3] <= 1'b0; // Since q is known not to be == 0
		       end else begin
			  st[3] <= 1'b0;
			  st[4] <= 1'b0;
			  memen <= 1'b0;
			  we <= 1'b0;
		       end
		   endcase // case (ir[6:9])
		   st[0] <= |q;
		   st[1] <= !q[0] && |q;
		   st[2] <= ~|q;
		end
		state <= S_IFETCH;
	     end // case: S_SINGLE_OP_4

	     // COC / CZC / XOR
	     S_BIT_OP_1: begin
		operand <= d;
		addr <= wpaddr(ir[6:9]);
		memen <= 1'b1;
	     end
	     S_BIT_OP_3: begin
		case (ir[4:5])
		  2'b00: q <= (~d_latch) & operand; // COC
		  2'b01: q <= d_latch & operand; // CZC
		  2'b10: q <= d_latch ^ operand; // XOR
		endcase // case (ir[4:5])
	     end
	     S_BIT_OP_4: begin
		st[2] <= ~|q;
		if (ir[4]) begin
		   st[0] <= |q;
		   st[1] <= !q[0] && |q;
		   memen <= 1'b1;
		   we <= 1'b1;
		end
		state <= S_IFETCH;
	     end

	     // XOP
	     S_XOP_1: begin
		q <= addr;
	        extra <= wp;
	     end
	     S_XOP_2: begin
		addr <= { 10'h001, ir[6:9], 2'b00 };
		memen <= 1'b1;
	     end
	     S_XOP_3: wp <= d;
	     S_XOP_4: begin
		addr <= wpaddr(4'd11);
		we <= 1'b1;
		memen <= 1'b1;
	     end
	     S_XOP_7: begin
		q <= extra;
		extra <= { 10'h001, ir[6:9], 2'b11 };
		state <= S_INTREQ_4;
	     end

	     // SBO / SBZ / TB
	     S_CRU_SINGLE_1: begin
		addr <= { operand[1:15], 1'b0 } + d_latch;
		addr[0:2] <= 3'b000;
		cru_cycle <= 1'b1;
		if (ir[6:7] != 2'b11) begin
		   // SBO / SBZ
		   cruout <= ir[7];
		   cruclk <= 1'b1;
		end
	     end
	     S_CRU_SINGLE_2: begin
		if (ir[6:7] == 2'b11)
		   st[2] <= cruin_latch; // TB
		state <= S_IFETCH;
	     end		

	     // RTWP
	     S_RTWP_1: begin
		addr <= wpaddr(4'd15);
		memen <= 1'b1;
	     end
	     S_RTWP_2: begin
		st <= d;
		addr <= wpaddr(4'd14);
		memen <= 1'b1;
	     end
	     S_RTWP_3: begin
		pc <= d;
		addr <= wpaddr(4'd13);
		memen <= 1'b1;
	     end
	     S_RTWP_4:
	       wp <= d;
	     S_RTWP_5:
	       state <= S_IFETCH;

	     // IDLE / RSET / CKOF / CKON / LREX
	     S_EXTOP_1: begin
		addr[0:2] <= ir[8:10];
		cru_cycle <= 1'b1;
		cruclk <= 1'b1;
	     end
	     S_EXTOP_2:
	       case (ir[8:10])
		 3'b010: idling <= 1'b1;       // IDLE
		 3'b011: st[12:15] <= 4'b0000; // RSET
	       endcase // case (ir[8:10])
	     S_EXTOP_4: state <= S_IFETCH;

	     // LDCR / STCR
	     S_CRU_MULTIPLE_1: begin
		if (ir[5] == 1'b1) begin
		   operand <= addr;
		   extra <= d;
		end else if (bytemode)
		  operand <= { 8'h00, (addr[15]? d[8:15] : d[0:7]) };
		else
		  operand <= d;
		addr <= wpaddr(4'd12);
		memen <= 1'b1;
	     end
	     S_CRU_MULTIPLE_2: begin
		addr <= d;
		addr[0:2] <= 3'b000;
		if (ir[5] == 1'b1)
		   d_latch <= extra;
		// Fix timing
		if (ir[5] == 1'b0)
		  extra[0:2] <= 3'd3;
		else if (c[1:3] == 3'b000)
		  extra[0:2] <= 3'd7;
		else
		  extra[0:2] <= 3'd6;
	     end
	     S_CRU_MULTIPLE_3: begin
		if (extra[0:2] != 3'b000) begin
		   extra[0:2] <= extra[0:2] - 3'b001;
		   state <= S_CRU_MULTIPLE_3;
		end else begin
		   if (ir[5] == 1'b1) begin
		      if (bytemode)
			q <= 16'h007f;
		      else
			q <= 16'h7fff;
		   end else if (bytemode)
		     q <= { operand[8:15], 8'h00 };
		   else
		     q <= operand;

		   cru_cycle <= 1'b1;
		   if (ir[5] == 1'b0) begin
		      // LDCR
		      cruclk <= 1'b1;
		      cruout <= operand[15];
		      operand <= { 1'b0, operand[0:14] };
		   end
		   c <= c - 4'b0001;
		end
	     end
	     S_CRU_MULTIPLE_4: begin
		addr[3:14] <= addr[3:14] + 12'h001;
		if (ir[5] == 1'b0) begin
		   // LDCR
		   if (c != 4'b0000) begin
		      state <= S_CRU_MULTIPLE_4;
		      cruclk <= 1'b1;
		      cruout <= operand[15];
		      operand <= { 1'b0, operand[0:14] };
		   end
		end else begin // if (ir[5] == 1'b0)
		   // STCR
		   if (q[15] == 1'b1)
		     state <= S_CRU_MULTIPLE_4;
		   q <= { cruin_latch, q[0:14] };
		   cruin_latch <= 1'b0;
		end // else: !if(ir[5] == 1'b0)
		if (c != 4'b0000) begin
		  cru_cycle <= 1'b1;
		  c <= c - 4'b0001;
		end
	     end // case: S_CRU_MULTIPLE_4
	     S_CRU_MULTIPLE_5: begin
		st[0] <= |q;
		st[1] <= !q[0] && |q;
		st[2] <= ~|q;
		if (bytemode)
		  st[5] <= ^q[0:7];
		if (ir[5] == 1'b1) begin
		   addr <= operand;
		   if (bytemode) begin
		      if (operand[15])
			q <= { d_latch[0:7], q[0:7] };
		      else
			q <= { q[0:7], d_latch[8:15] };
		   end
		   we <= 1'b1;
		   memen <= 1'b1;
		end
		state <= S_IFETCH;
	     end

	     // MPY
	     S_MPY_1: begin
		extra <= d;
		addr <= wpaddr(ir[6:9]);
		memen <= 1'b1;
	     end
	     S_MPY_2: begin	
		q <= extra;
		extra <= 16'h0000;
		c <= 4'b1111;
	     end
	     S_MPY_3: begin
		if (q[0])
		  { q, extra } <= { q[1:15], extra, 1'b0 } + { 16'h0000, d_latch };
		else
		  { q, extra } <= { q[1:15], extra, 1'b0 };
		if (c != 4'b0000)
		  state <= S_MPY_3;
		c <= c - 4'b0001;
	     end
	     S_MPY_4: begin
		we <= 1'b1;
		memen <= 1'b1;
	     end
	     S_MPY_5: begin
		addr <= addr + 16'd2;
		q <= extra;
		we <= 1'b1;
		memen <= 1'b1;
	     end
	     S_MPY_8: state <= S_IFETCH;

	     // DIV
	     S_DIV_1: begin
		operand <= d;
		addr <= wpaddr(ir[6:9]);
		memen <= 1'b1;
	     end
	     S_DIV_2:
	       extra <= d;
	     S_DIV_3: begin
		if (operand <= extra) begin
		   st[4] <= 1'b1;
		   state <= S_DIV_13;
		end else begin
		   st[4] <= 1'b0;
		   addr <= addr + 16'd2;
		   memen <= 1'b1;
		end
	     end
	     S_DIV_5: begin
		q <= d_latch;
		c <= 4'b1111;
	     end
	     S_DIV_6: begin
		if ((extra[0] == 1'b0) && ({ extra[1:15], q[0] } < operand))
		  state <= S_DIV_8;
		{ extra, q } <= { extra[1:15], q, 1'b0 };
	     end
	     S_DIV_7: begin
		extra <= extra - operand;
		q[15] = 1'b1;
	     end
	     S_DIV_8: begin
		if (c != 4'b0000)
		  state <= S_DIV_6;
		c <= c - 4'b0001;
	     end
	     S_DIV_9: begin
		addr <= wpaddr(ir[6:9]);
		memen <= 1'b1;
		we <= 1'b1;
	     end
	     S_DIV_10: begin
		addr <= addr + 16'd2;
		q <= extra;
		memen <= 1'b1;
		we <= 1'b1;
	     end
	     S_DIV_14:
	       state <= S_IFETCH;
	   endcase // case (state)
	end // else: !if(phase == 1'b1)
     end // if (clk_en)
   end // always @ (posedge clk)
   
endmodule
