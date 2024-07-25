module peb_fdc(input         clk,
	       input	     clk_3mhz_en,
	       input	     reset,

	       input [0:15]  a,
	       input [0:7]   d,
	       output [0:7]  q,
	       output	     q_select,
	       input	     memen,
	       input	     we,
	       input	     cruclk,
	       output reg    cruin,
	       output	     cru_select,
	       output	     ready,
	       output        led,

	       // ROM / FIFO / img regs access wishbone slave
	       input [0:13]  wb_adr_i,
	       input [0:7]   wb_dat_i,
	       output [0:7]  wb_dat_o,
	       input	     wb_we_i,
	       input [0:0]   wb_sel_i,
	       input	     wb_stb_i,
	       output reg    wb_ack_o,
	       input	     wb_cyc_i);

   reg dskpgena;
   reg kaclk, kaclk_prev;
   reg waiten;
   reg hlt;
   reg dsel1, dsel2, dsel3;
   reg sidsel;

   reg        dvena;
   reg [0:23] ena_count;
   reg	      wait_completed;

   wire	wdsel;
   wire	d1c, d2c, d3c;

   wire	intrq;
   wire	drq;
   wire [0:7] ddb;
   reg [0:7]  ddb_reg;

   wire	       dsr_select;
   reg [0:7]   dsr_rom [0:8191];
   reg [0:7]   dsr_rom_data;
   wire [0:12] readaddr;

   wire [7:0]  img_din;
   reg [1:0]   img_mounted;
   reg [1:0]   img_wp;
   reg [15:0]  img_size;
   wire [31:0] img_lba;
   wire [1:0]  img_rd;
   wire [1:0]  img_wr;
   reg	       img_ack;
   reg [0:7]   wb_reg_q;

   assign led = dskpgena;

   assign wdsel = dskpgena && memen && (a[0:11] == 12'h5ff);
   assign d1c = dsel1 & dvena;
   assign d2c = dsel2 & dvena;
   assign d3c = dsel3 & dvena;

   assign q_select = dskpgena && (a[0:2] == 3'b010);
   assign cru_select = (a[0:7] == 8'h11);
   assign dsr_select = q_select && memen && !we;

   assign q = (a[0:11] == 12'h5ff ? ddb_reg : dsr_rom_data);
   assign ready = ~wdsel | ~waiten | wait_completed;

   assign readaddr = (dsr_select ? a[3:15] : wb_adr_i[1:13]);
   assign wb_dat_o = ( wb_adr_i[0] ?
		       ( wb_adr_i[1] ? wb_reg_q : img_din )
		       : dsr_rom_data );

   /* u11 */
   always @(posedge clk)
     if (~wdsel)
       wait_completed <= 1'b0;
     else if (clk_3mhz_en && (drq | intrq | ~dvena))
       wait_completed <= 1'b1;

   /* u22 */
   always @(*) begin
      cruin <= 1'b0;
      case (a[12:14])
	3'b000: cruin <= hlt; // HLD
	3'b001: cruin <= d1c;
	3'b010: cruin <= d2c;
	3'b011: cruin <= d3c;
	3'b100: cruin <= ~dvena;
	3'b101: cruin <= 1'b0;
	3'b110: cruin <= 1'b1;
	3'b111: cruin <= sidsel;
      endcase // case (a[12:14])
   end // always @ (*)

   /* u23 */
   always @(posedge clk)
     if (reset) begin
	dskpgena <= 1'b0;
	kaclk <= 1'b0;
	waiten <= 1'b0;
	hlt <= 1'b0;
	dsel1 <= 1'b0;
	dsel2 <= 1'b0;
	dsel3 <= 1'b0;
	sidsel <= 1'b0;
     end else if (cruclk && cru_select)
       case (a[12:14])
	 3'b000: dskpgena <= a[15];
	 3'b001: kaclk <= a[15];
	 3'b010: waiten <= a[15];
	 3'b011: hlt <= a[15];
	 3'b100: dsel1 <= a[15];
	 3'b101: dsel2 <= a[15];
	 3'b110: dsel3 <= a[15];
	 3'b111: sidsel <= a[15];
       endcase // case (a[12:14])

   /* u9a */
   always @(posedge clk)
     if (reset) begin
	dvena <= 1'b0;
	kaclk_prev <= kaclk;
     end else begin
	if (dvena && clk_3mhz_en) begin
	   if (|ena_count)
	     ena_count <= ena_count - 24'd1;
	   else
	     dvena <= 1'b0;
	end
	if (kaclk & ~kaclk_prev) begin
	   dvena <= 1'b1;
	   ena_count <= 24'd9421362; // 2.632 s, from K=0.28, RT=200k, Cext=47u
	end
	kaclk_prev <= kaclk;
     end // else: !if(reset)

   /* u26 / u27 */
   always @(posedge clk) begin
      // Read port
      if (dsr_select || (wb_cyc_i && wb_stb_i && !wb_we_i && !wb_adr_i[0]))
	dsr_rom_data <= dsr_rom[readaddr];

      // Write port
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && wb_sel_i[0] && !wb_adr_i[0])
	dsr_rom[wb_adr_i[1:13]] <= wb_dat_i;

      // Wishbone handshake
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o && (wb_we_i || wb_adr_i[0] || !dsr_select);
   end // always @ (posedge clk)

   /* u28 */
   fdc1772 #(.CLK(107386350), .CLK_EN(3579545), .SECTOR_SIZE_CODE(2'd1))
   floppy_controller(.clkcpu(clk), .clk8m_en(clk_3mhz_en),
		     .floppy_drive({ 1'b1, ~d3c, ~d2c, ~d1c }),
		     .floppy_side(sidsel),
		     .floppy_reset(~reset), .irq(intrq), .drq(drq),
		     .cpu_addr(a[13:14]),
		     .cpu_sel(wdsel & (we ^ ~a[12]) & ~a[15]),
		     .cpu_rw(~a[12]), .cpu_din(~d), .cpu_dout(ddb),

		     .img_mounted(img_mounted), .img_wp(img_wp),
		     .img_size({7'd0, img_size, 9'd0}), .sd_lba(img_lba),
		     .sd_rd(img_rd), .sd_wr(img_wr), .sd_ack(img_ack),
		     .sd_buff_addr(wb_adr_i[5:13]),
		     .sd_dout(wb_dat_i), .sd_din(img_din),
		     .sd_dout_strobe(wb_cyc_i && wb_stb_i && wb_we_i &&
				     wb_ack_o && wb_sel_i[0] &&
				     wb_adr_i[0:1] == 2'b10),
		     .sd_din_strobe(wb_cyc_i && wb_stb_i && !wb_we_i &&
				    wb_ack_o && wb_adr_i[0:1] == 2'b10));
   always @(posedge clk)
     if (wdsel && ~a[12])
       ddb_reg <= ~ddb;
     else
       ddb_reg <= 8'hff;


   /* Service processor interface */

   reg [15:0] img_lba_reg;
   always @(posedge clk)
     if (wb_cyc_i && wb_stb_i && !wb_ack_o && !wb_we_i)
       img_lba_reg <= img_lba[15:0]; /* Improve timing slack */

   always @(*) begin
      wb_reg_q <= 8'h00;
      case (wb_adr_i[10:13])
	4'b0000: begin
	   wb_reg_q[2:3] <= img_mounted[1:0];
	   wb_reg_q[6:7] <= img_wp[1:0];
	end
	4'b0001: begin
	   wb_reg_q[2:3] <= img_rd[1:0];
	   wb_reg_q[6:7] <= img_wr[1:0];
	end
	4'b0010: wb_reg_q[7] <= img_ack;
	4'b0100: wb_reg_q <= img_size[15:8];
	4'b0101: wb_reg_q <= img_size[7:0];
	4'b0110: wb_reg_q <= img_lba_reg[15:8];
	4'b0111: wb_reg_q <= img_lba_reg[7:0];
	default: ;
      endcase // case (wb_adr_i[10:13])
   end // always @ (*)

   always @(posedge clk) begin
      if (reset) begin
	 img_mounted <= 2'b00;
	 img_wp <= 2'b00;
	 img_ack <= 1'b0;
	 img_size <= 16'h0000;
      end else if (wb_cyc_i && wb_stb_i && wb_we_i &&
		   wb_ack_o && wb_sel_i[0] && wb_adr_i[0:1] == 2'b11)
	case (wb_adr_i[10:13])
	  4'b0000: begin
	     img_mounted[1:0] <= wb_dat_i[2:3];
	     img_wp[1:0] <= wb_dat_i[6:7];
	  end
	  4'b0010: img_ack <= wb_dat_i[7];
	  4'b0100: img_size[15:8] <= wb_dat_i;
	  4'b0101: img_size[7:0] <= wb_dat_i;
	endcase // case (wb_adr_i[10:13])
   end // always @ (posedge clk)

endmodule // peb_fdc
