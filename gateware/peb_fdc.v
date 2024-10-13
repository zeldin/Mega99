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
	       output	     led,

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
   wire hld;
   reg hlt;
   reg dsel1, dsel2, dsel3;
   reg sidsel;

   reg        dvena;
   reg [0:23] ena_count;
   reg	      wait_completed;

   wire	wdsel;
   wire	d1c, d2c, d3c;

   wire	      intrq;
   wire	      drq;
   wire [0:7] ddb;
   wire	      step;
   wire	      dirc;

   wire	       dsr_select;
   reg [0:7]   dsr_rom [0:8191];
   reg [0:7]   dsr_rom_data;
   wire [0:12] readaddr;

   reg [2:0]   img_mounted = 3'b000;
   reg [2:0]   img_wp = 3'b000;
   reg [2:0]   img_strobe;
   reg	       img_ds;
   reg	       img_dd;
   reg [4:0]   img_sps;
   reg [2:0]   img_rd = 3'b000;
   reg [2:0]   img_wr = 3'b000;
   reg [0:7]   wb_reg_q;

   wire [7:0]  sector;
   wire [7:0]  cmd;

   wire [7:0]  data_pos;
   wire [7:0]  data_write_d;
   wire	       data_write_strobe;
   wire	       data_read_strobe;
   wire	       header_read_strobe;
   wire	       data_transfer_read_strobe;
   wire	       data_transfer_write_strobe;
   reg	       data_is_header;
   reg [0:7]   header_data;
   reg	       data_transfer_ack = 1'b0;

   reg [0:7]   sector_buffer[0:255];
   reg [0:7]   sector_buffer_data;

   wire	       dsk1_byte_clk;
   wire	       dsk1_header_clk;
   wire [5:0]  dsk1_track;
   wire [4:0]  dsk1_sector;
   wire	       dsk1_ip;
   wire	       dsk1_ready;
   wire	       dsk1_ds;
   wire	       dsk2_byte_clk;
   wire	       dsk2_header_clk;
   wire [5:0]  dsk2_track;
   wire [4:0]  dsk2_sector;
   wire	       dsk2_ip;
   wire	       dsk2_ready;
   wire	       dsk2_ds;
   wire	       dsk3_byte_clk;
   wire	       dsk3_header_clk;
   wire [5:0]  dsk3_track;
   wire [4:0]  dsk3_sector;
   wire	       dsk3_ip;
   wire	       dsk3_ready;
   wire	       dsk3_ds;

   reg tr00;
   reg ip;
   reg byte_clk;
   reg header_clk;
   reg sector_header_match;

   assign led = dskpgena;

   assign wdsel = dskpgena && memen && (a[0:11] == 12'h5ff);
   assign d1c = dsel1 & dvena;
   assign d2c = dsel2 & dvena;
   assign d3c = dsel3 & dvena;

   assign q_select = dskpgena && (a[0:2] == 3'b010);
   assign cru_select = (a[0:7] == 8'h11);
   assign dsr_select = q_select && memen && !we;

   assign q = (a[0:11] == 12'h5ff ? ~ddb : dsr_rom_data);
   assign ready = ~wdsel | ~waiten | wait_completed;

   assign readaddr = (dsr_select ? a[3:15] : wb_adr_i[1:13]);
   assign wb_dat_o = ( wb_adr_i[0] ?
		       ( wb_adr_i[1] ? wb_reg_q : sector_buffer_data )
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
	3'b000: cruin <= hld;
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
	   ena_count <= 24'd7896000; // 2.632 s, from K=0.28, RT=200k, Cext=47u
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
   end // always @ (posedge clk)

   /* u28 */
   fdc1771 #(.SECTOR_SIZE_CODE(2'd1))
   floppy_controller(.clk(clk), .clk_3mhz_en(clk_3mhz_en), .mr(reset),
		     .dal_in(~d), .dal_out(ddb), .a(a[13:14]), .cs(wdsel),
		     .re(wdsel & ~a[15] & ~a[12] & ~we),
		     .we(wdsel & ~a[15] & a[12] & we),
		     .irq(intrq), .drq(drq),
		     .hld(hld), .hlt(hlt),

		     .tr00(tr00), .ip(ip), .wprt(|(img_wp & {d3c, d2c, d1c})),
		     .ready(dvena), .wd(), .wg(), .dirc(dirc), .step(step),
		     .byte_clk(byte_clk), .header_clk(header_clk),
		     .sector_header_match(sector_header_match),

		     .data_pos(data_pos), .data_write_d(data_write_d),
		     .data_write_strobe(data_write_strobe),
		     .data_read_d(data_is_header ? header_data :
				  sector_buffer_data),
		     .data_read_strobe(data_read_strobe),
		     .header_read_strobe(header_read_strobe),
		     .data_transfer_read_strobe(data_transfer_read_strobe),
		     .data_transfer_write_strobe(data_transfer_write_strobe),
		     .data_transfer_ack(data_transfer_ack),
		     .track(), .sector(sector), .cmd(cmd));

   fdc1771_mockdrive dsk1(.clk(clk), .clk_3mhz_en(clk_3mhz_en),
			  .byte_clk(dsk1_byte_clk),
			  .header_clk(dsk1_header_clk),
			  .track(dsk1_track), .sector(dsk1_sector),
			  .ip(dsk1_ip), .ready(dsk1_ready), .ds(dsk1_ds),
			  .sel(d1c), .step(step), .dir(~dirc),
			  .byte_clk_next(dsk2_byte_clk),
			  .header_clk_next(dsk2_header_clk),
			  .track_next(dsk2_track), .sector_next(dsk2_sector),
			  .ip_next(dsk2_ip), .ds_next(dsk2_ds),
			  .load_mounted(img_mounted[0]),
			  .load_ds(img_ds), .load_dd(img_dd),
			  .load_sps(img_sps), .load_strobe(img_strobe[0]));

   fdc1771_mockdrive dsk2(.clk(clk), .clk_3mhz_en(clk_3mhz_en),
			  .byte_clk(dsk2_byte_clk),
			  .header_clk(dsk2_header_clk),
			  .track(dsk2_track), .sector(dsk2_sector),
			  .ip(dsk2_ip), .ready(dsk2_ready), .ds(dsk2_ds),
			  .sel(d2c), .step(step), .dir(~dirc),
			  .byte_clk_next(dsk3_byte_clk),
			  .header_clk_next(dsk3_header_clk),
			  .track_next(dsk3_track), .sector_next(dsk3_sector),
			  .ip_next(dsk3_ip), .ds_next(dsk3_ds),
			  .load_mounted(img_mounted[1]),
			  .load_ds(img_ds), .load_dd(img_dd),
			  .load_sps(img_sps), .load_strobe(img_strobe[1]));

   fdc1771_mockdrive dsk3(.clk(clk), .clk_3mhz_en(clk_3mhz_en),
			  .byte_clk(dsk3_byte_clk),
			  .header_clk(dsk3_header_clk),
			  .track(dsk3_track), .sector(dsk3_sector),
			  .ip(dsk3_ip), .ready(dsk3_ready), .ds(dsk3_ds),
			  .sel(d3c), .step(step), .dir(~dirc),
			  .byte_clk_next(1'b0), .header_clk_next(1'b0),
			  .track_next(6'd0), .sector_next(5'd0),
			  .ip_next(1'b0), .ds_next(1'd0),
			  .load_mounted(img_mounted[2]),
			  .load_ds(img_ds), .load_dd(img_dd),
			  .load_sps(img_sps), .load_strobe(img_strobe[2]));

   always @(posedge clk) begin
      tr00 <= (dsk1_track == 6'd0);
      ip <= dsk1_ip;
      byte_clk <= dsk1_byte_clk;
      header_clk <= dsk1_header_clk;
      sector_header_match <= (dsk1_header_clk && (dsk1_sector == sector));
   end


   /* Sector buffer */
   always @(posedge clk) begin
      // Read port
      if (data_read_strobe || (wb_cyc_i && wb_stb_i && !wb_we_i &&
			       wb_adr_i[0:1] == 2'b10))
	sector_buffer_data <= sector_buffer[( data_read_strobe ?
					      data_pos : wb_adr_i[6:13] )];

      // Write port
      if (data_write_strobe || (wb_cyc_i && wb_stb_i && wb_we_i &&
				wb_sel_i[0] && wb_adr_i[0:1] == 2'b10))
	sector_buffer[( data_write_strobe ?
			data_pos : wb_adr_i[6:13] )] <= ( data_write_strobe ?
							  data_write_d :
							  wb_dat_i );
   end

   /* Header */
   always @(posedge clk) begin
      data_is_header <= 1'b0;
      if (header_read_strobe) begin
	 data_is_header <= 1'b1;
	 header_data <= 8'h00;
	 case (data_pos[2:0])
	   3'b000: header_data[7 -: 6] <= dsk1_track;
	   3'b001: header_data[7] <= sidsel & dsk1_ds;
	   3'b010: header_data[7 -: 5] <= dsk1_sector;
	   3'b011: header_data[7] <= 1'b1; // sector size
	   default: ;
	 endcase // case (data_pos[2:0])
      end
   end


   /* Service processor interface */

   always @(posedge clk) begin
      // Wishbone handshake
      if (!wb_cyc_i || !wb_stb_i || wb_ack_o)
	wb_ack_o <= 1'b0;
      else if (!wb_adr_i[0])
	wb_ack_o <= wb_we_i || !dsr_select;
      else if (!wb_adr_i[1])
	wb_ack_o <= !( wb_we_i ? data_write_strobe : data_read_strobe );
      else
	wb_ack_o <= 1'b1;
   end

   always @(*) begin
      wb_reg_q <= 8'h00;
      case (wb_adr_i[10:13])
	4'b0000: begin
	   wb_reg_q[1:3] <= img_mounted[2:0];
	   wb_reg_q[5:7] <= img_wp[2:0];
	end
	4'b0001: begin
	   wb_reg_q[1:3] <= img_rd[2:0];
	   wb_reg_q[5:7] <= img_wr[2:0];
	end
	4'b0010: wb_reg_q[7] <= data_transfer_ack;
	4'b0011: wb_reg_q <= { img_ds, img_dd, 1'b0, img_sps };
	4'b0100: wb_reg_q[1:7] <= { dsk1_track, sidsel };
	4'b0101: wb_reg_q <= sector;
	4'b0110: wb_reg_q <= cmd;
	default: ;
      endcase // case (wb_adr_i[10:13])
   end // always @ (*)

   always @(posedge clk) begin
      img_strobe <= 3'b000;
      if (data_transfer_read_strobe)
	img_rd <= { dsel3, dsel2, dsel1 };
      if (data_transfer_write_strobe)
	img_wr <= { dsel3, dsel2, dsel1 };
      if (wb_cyc_i && wb_stb_i && wb_we_i &&
		   wb_ack_o && wb_sel_i[0] && wb_adr_i[0:1] == 2'b11)
	case (wb_adr_i[10:13])
	  4'b0000: begin
	     img_strobe[2:0] <= img_mounted[2:0] ^ wb_dat_i[1:3];
	     img_mounted[2:0] <= wb_dat_i[1:3];
	     img_wp[2:0] <= wb_dat_i[5:7];
	  end
	  4'b0010: begin
	     data_transfer_ack <= wb_dat_i[7];
	     if (wb_dat_i[7] && !data_transfer_ack) begin
		img_rd <= 3'b000;
		img_wr <= 3'b000;
	     end
	  end
	  4'b0011: begin
	     img_ds <= wb_dat_i[0];
	     img_dd <= wb_dat_i[1];
	     img_sps <= wb_dat_i[3:7];
	  end
	endcase // case (wb_adr_i[10:13])
   end // always @ (posedge clk)

endmodule // peb_fdc
