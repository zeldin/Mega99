module peb_pcode(input        clk,
		 input	      grclk_en,
		 input	      reset,
		 input	      enable,

		 input [0:15] a,
		 input [0:7]  d,
		 output [0:7] q,
		 output	      q_select,
		 input	      memen,
		 input        dbin,
		 input	      cruclk,
		 output	      ready,
		 output	      led,

		 // ROM access wishbone slave
		 input [0:16] wb_adr_i,
		 input [0:7]  wb_dat_i,
		 output [0:7] wb_dat_o,
		 input	      wb_we_i,
		 input [0:0]  wb_sel_i,
		 input	      wb_stb_i,
		 output	      wb_ack_o,
		 input	      wb_cyc_i);

   parameter LED_BIT7 = 0;

   reg cru_bit0;
   reg cru_bit4;
   reg cru_bit7;

   wire	dsr_enable;
   wire	rom2_bank;
   wire	cru_select;
   wire	dsr_select;
   wire	grom_select;
   wire	gs;

   reg [0:7]   rom1 [0:4095];
   reg [0:7]   rom1_data;
   reg [0:7]   rom2 [0:8191];
   reg [0:7]   rom2_data;
   wire [0:12] readaddr;

   wire [0:7]  grom_q;
   wire	       grom_ready;
   wire [0:7]  grom_wb_dat_o;
   wire	       grom_wb_ack_o;

   reg	       dsr_wb_ack_o;

   wire [0:15] prefetch_grom_addr;
   wire	       grom_do_prefetch;
   wire	       grom_prefetch_complete;
   wire [0:7]  grom_prefetch_data;

   assign led = (LED_BIT7 ? cru_bit7 : cru_bit0);
   assign dsr_enable = cru_bit0;
   assign rom2_bank = cru_bit4;

   assign q_select = dsr_enable && (a[0:2] == 3'b010);
   assign cru_select = enable && (a[0:7] == 8'h1F);
   assign dsr_select = q_select && memen && dbin;
   assign grom_select = ((a & 16'hFBFD) == 16'h5BFC) &&
			(a[5] == 1'b0 || !dbin);
   assign gs = dsr_enable && memen && grom_select;
   assign q = (grom_select ? grom_q : (a[3] ? rom2_data : rom1_data));
   assign ready = grom_ready || !gs;

   assign readaddr = (dsr_select ? { rom2_bank, a[4:15] } : wb_adr_i[4:16]);

   assign wb_dat_o = (wb_adr_i[0] ? grom_wb_dat_o :
		      (wb_adr_i[3] ? rom2_data : rom1_data));
   assign wb_ack_o = (wb_adr_i[0]? grom_wb_ack_o : dsr_wb_ack_o);


   // CRU
   
   always @(posedge clk)
     if (reset || !enable) begin
	cru_bit0 <= 1'b0;
	cru_bit4 <= 1'b0;
	cru_bit7 <= 1'b0;
     end else if (cruclk && cru_select)
       case ({a[8], a[13:14]})
	 3'b000: cru_bit0 <= a[15];
	 3'b100: cru_bit4 <= a[15];
	 3'b111: cru_bit7 <= a[15];
       endcase // case ({a[8], a[13:14]})


   // DSR ROMs
   
   always @(posedge clk) begin
      // Read ports
      if (dsr_select ||
	  (wb_cyc_i && wb_stb_i && !wb_we_i && !wb_adr_i[0])) begin
	 rom1_data <= rom1[readaddr[1:12]];
	 rom2_data <= rom2[readaddr[0:12]];
      end

      // Write ports
      if (wb_cyc_i && wb_stb_i && wb_we_i && dsr_wb_ack_o &&
	  wb_sel_i[0] && !wb_adr_i[0]) begin
	 if (wb_adr_i[3])
	   rom2[wb_adr_i[4:16]] <= wb_dat_i;
	 else
	   rom1[wb_adr_i[5:16]] <= wb_dat_i;
      end
   end // always @ (posedge clk)
   
   always @(posedge clk) begin
      // Wishbone handshake
      if (!wb_cyc_i || !wb_stb_i || wb_adr_i[0] || dsr_wb_ack_o)
	dsr_wb_ack_o <= 1'b0;
      else
	dsr_wb_ack_o <= wb_we_i || !dsr_select;
   end


   // GROMs

   groms pcode_groms(.clk(clk), .grclk_en(grclk_en), .m(dbin),
		     .gs(gs), .mo(a[14]), .d(d), .q(grom_q),
		     .gready(grom_ready), .grom_set(4'h0),
		     .prefetch_grom_set(),
		     .prefetch_grom_addr(prefetch_grom_addr),
		     .do_prefetch(grom_do_prefetch),
		     .prefetch_complete(grom_prefetch_complete),
		     .prefetch_data(grom_prefetch_data));

   grom_storage_bram
     pcode_grom_storage(.clk(clk), .prefetch_grom_set(4'h0),
			.prefetch_grom_addr(prefetch_grom_addr),
			.do_prefetch(grom_do_prefetch),
			.prefetch_complete(grom_prefetch_complete),
			.prefetch_data(grom_prefetch_data),
			.wb_adr_i(wb_adr_i[1:16]), .wb_dat_i(wb_dat_i),
			.wb_dat_o(grom_wb_dat_o), .wb_we_i(wb_we_i),
			.wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_i && wb_adr_i[0]),
			.wb_ack_o(grom_wb_ack_o), .wb_cyc_i(wb_cyc_i));

endmodule // peb_pcode
