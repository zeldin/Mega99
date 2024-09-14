module tms9918_vdp(input             reset,
		   input	     clk, // Enabled cycles should give
		   input	     clk_en, // pixel clock, 5.3693175 MHz

		   // Video output
		   output reg	     sync_h,
		   output reg	     sync_v,
		   output reg	     cburst,
		   output reg [0:3]  color,
		   output reg	     color_en,
		   output	     extvideo,

		   // VDP RAM read port
		   // -----------------
		   // When vdp_read and clk_en are both high, that starts
		   // a read cycle.  The data should be available in
		   // vdp_rdata during the _next_ cycle in which clk_en is
		   // high.  vdp_raddr remains stable up to and including
		   // that cycle, but vdp_read will have been deasserted
		   // in other to not start a new read cycle.
		   output reg [0:13] vdp_raddr,
		   input [0:7]	     vdp_rdata,
		   output reg	     vdp_read,

		   // Register access port
		   // --------------------
		   // Registers can be read/written any cycle, without
		   // having to consider clk_en
		   input [0:2]	     reg_addr,
		   input [0:7]	     reg_wdata,
		   input	     reg_wstrobe,
		   output [0:7]	     reg_rdata,
		   input	     reg_rstrobe,

		   // Interrupt
		   output	     int_pending
		   );


   // Screen display parameters, datasheet page 3-8 table 3-3

   localparam [0:8] HACTIVE = 256;
   localparam [0:8] RBORDER = 15;
   localparam [0:8] RBLANKING = 8;
   localparam [0:8] HSYNC = 26;
   localparam [0:8] LBLANKING1 = 2;
   localparam [0:8] COLORBURST = 14;
   localparam [0:8] LBLANKING2 = 8;
   localparam [0:8] LBORDER = 13;

   localparam [0:8] VACTIVE = 192;
   localparam [0:8] BBORDER = 24;
   localparam [0:8] BBLANKING = 3;
   localparam [0:8] VSYNC = 3;
   localparam [0:8] TBLANKING = 13;
   localparam [0:8] TBORDER = 27;

   // Internal parameters

   localparam [0:8] HLATENCY = 8;  // hpos to pixel data available latency, < LBORDER
   localparam NSPRITES = 4;
   
   // Derived parameters

   localparam [0:8] HTOTAL = HACTIVE + RBORDER + RBLANKING + HSYNC + LBLANKING1 +
		    COLORBURST + LBLANKING2 + LBORDER;
   localparam [0:8] HACTIVE_START = HLATENCY;
   localparam [0:8] RBORDER_START = HACTIVE_START + HACTIVE;
   localparam [0:8] RBLANKING_START = RBORDER_START + RBORDER;
   localparam [0:8] HSYNC_START = RBLANKING_START + RBLANKING;
   localparam [0:8] LBLANKING1_START = HSYNC_START + HSYNC;
   localparam [0:8] COLORBURST_START = LBLANKING1_START + LBLANKING1;
   localparam [0:8] LBLANKING2_START = COLORBURST_START + COLORBURST;
   localparam [0:8] LBORDER_START = LBLANKING2_START + LBLANKING2;

   localparam [0:8] VTOTAL = VACTIVE + BBORDER + BBLANKING + VSYNC + TBLANKING +
		    TBORDER;
   localparam [0:8] VACTIVE_START = 0;
   localparam [0:8] BBORDER_START = VACTIVE_START + VACTIVE;
   localparam [0:8] BBLANKING_START = BBORDER_START + BBORDER;
   // Note: VSYNC and top blanking/border are at "negative" coordinates
   //       to support sprite bleed-in
   localparam [0:8] VSYNC_START = 9'h000 - (VSYNC + TBLANKING + TBORDER);
   localparam [0:8] TBLANKING_START = VSYNC_START + VSYNC;
   localparam [0:8] TBORDER_START = TBLANKING_START + TBLANKING;

   // Internal variables
   reg [0:8]  hpos;
   reg [0:8]  vpos;
   reg [0:7]  pattern_bits;
   reg [0:7]  pattern_color;
   reg [0:7]  next_pattern_name; 
   reg [0:7]  next_pattern_color;
   reg [0:9]  textpos;
   reg [0:6]  textpossave;
   reg [0:5]  textsave;
   reg	      sprite_attr_line;
   reg	      new_sprite;
   reg [0:3]  new_sprite_voffs;

   
   // Register 0
   reg	      m3;
   reg	      ev;

   // Register 1
   reg	      k16;
   reg	      blank;
   reg	      ie;
   reg	      m1;
   reg	      m2;
   reg	      size;
   reg	      mag;

   // Register 2
   reg [0:3]  ntb;

   // Register 3
   reg [0:7]  ctb;

   // Register 4
   reg [0:2]  pgb;

   // Register 5
   reg [0:6]  sab;

   // Register 6
   reg [0:2]  spgb;

   // Register 7
   reg [0:3]  color1;
   reg [0:3]  color0;

   // Status register
   reg	      f;
   reg	      s5;
   reg	      c;
   reg [0:4]  sn5;


   assign reg_rdata = { f, s5, c, sn5 };
   assign int_pending = f & ie;
   assign extvideo = (ev && color == 0);

   task automatic sprite_ymatch (input [0:7] spr_vpos,
				 output reg [0:3] line,
				 output reg valid);
      reg [0:7] offset;
      begin
	 offset = vpos[1:8] - spr_vpos;
	 if (mag)
	   offset = { 1'b0, offset[0:6] };
	 line <= offset[4:7];
	 valid <= (offset < (size ? 8'd16 : 8'd8));
      end
   endtask // sprite_ymatch

   wire [0:NSPRITES]   next_in_turn;
   wire [0:NSPRITES-1] sprvalid;
   wire [0:4]	       sprnum[0:NSPRITES-1];
   wire [0:7]	       sprname[0:NSPRITES-1];
   wire [0:3]	       sprvoffs[0:NSPRITES-1];
   wire [0:3]	       color_chain[0:NSPRITES];
   wire [0:NSPRITES]   sprpixel;
   wire [0:NSPRITES]   sprcoinc;
   
   assign next_in_turn[0] = 1'b1;
   assign color_chain[NSPRITES] = (pattern_bits[0] ?
				   pattern_color[0:3] : pattern_color[4:7]);
   assign sprpixel[NSPRITES] = 1'b0;
   assign sprcoinc[NSPRITES] = 1'b0;

   genvar sprite_id;
   generate
      for (sprite_id = 0; sprite_id < NSPRITES; sprite_id=sprite_id+1)
	begin : SPRITE
	   reg        valid;
	   reg        active;
	   reg [0:3]  voffs;
	   reg [0:4]  num;
	   reg [0:7]  hoffs;
	   reg [0:7]  name;
	   reg [0:3]  color;
	   reg	      early_clock;
	   reg	      clock_started;
	   reg [0:15] pattern;
	   reg	      pixel;

	   assign sprvalid[sprite_id] = valid;
	   assign next_in_turn[sprite_id+1] = valid;
	   assign sprnum[sprite_id] = num;
	   assign sprname[sprite_id] = name;
	   assign sprvoffs[sprite_id] = voffs;
	   assign color_chain[sprite_id] = (pixel && (|color)?
					    color : color_chain[sprite_id+1]);
	   assign sprpixel[sprite_id] = pixel | sprpixel[sprite_id+1];
	   assign sprcoinc[sprite_id] = pixel & sprpixel[sprite_id+1];
	   
	   always @(posedge clk)
	     if (clk_en) begin
		if (clock_started) begin
		   if (hoffs != 0)
		     hoffs <= hoffs - 8'd1;
		   else begin
		      pixel <= pattern[0];
		      pattern <= { pattern[1:15], 1'b0 };
		      hoffs[7] <= mag;
		   end
		end
		if (hpos == RBORDER_START) begin
		   clock_started <= 1'b0;
		   pixel <= 1'b0;
		   active <= valid;
		end
		if (valid && hpos >= HACTIVE && hpos[8] == 1'b1 &&
		    hpos[6:7] == sprite_id) begin
		   if (hpos < (HACTIVE+4*8))
		     case (hpos[4:5])
		       2'b01: hoffs <= vdp_rdata;
		       2'b10: name <= vdp_rdata;
		       2'b11: begin
			  early_clock <= vdp_rdata[0];
			  color <= vdp_rdata[4:7];
		       end
		     endcase // case (hpos[4:5])
		   else if (hpos < (HACTIVE+6*8))
		     case (hpos[5])
		       1'b0: pattern[0:7] <= vdp_rdata;
		       1'b1: pattern[8:15] <= (size? vdp_rdata : 8'h00);
		     endcase // case (hpos[5])
		end // if (valid && hpos >= HACTIVE &&...
		if (hpos == (HTOTAL-2-(32-HACTIVE_START)))
		  clock_started <= active && early_clock;
		if (hpos == (HACTIVE_START-2))
		  clock_started <= active;
		if (hpos == 0)
		  valid <= 1'b0;
		if (new_sprite && next_in_turn[sprite_id] && !valid) begin
		   valid <= 1'b1;
		   voffs <= new_sprite_voffs;
		   num <= hpos[1:5];
		end
	     end
	end
   endgenerate
   
   // Memory cycle generator
   always @(*) begin
      vdp_read = 1'b0;
      vdp_raddr = 14'h0000;

      if (hpos < HACTIVE) begin
	 // Main graphics fetch
	 vdp_read = (vpos < VACTIVE ? 1'b1 : 1'b0);
	 if (m1) begin
	    // Text mode
	    if (hpos[7])
	      vdp_raddr = { pgb, next_pattern_name, vpos[6:8] };// Pattern
	    else
	      vdp_raddr = { ntb, textpos }; // Name
	    // Only do double-fetch on every 4 text characters
	    if (!hpos[6] && textpos[8:9] != 2'b00)
	      vdp_read = 1'b0;
	    // First and last charbox are blank
	    if (hpos[1:5] == 5'd0 || hpos[1:5] == 5'd31)
	      vdp_read = 1'b0;
	 end else begin
	    case (hpos[6:7])
	      2'b00: // Sprite attribute fetch
		begin
		   vdp_raddr = { sab, hpos[1:5], 2'b00 };
		   vdp_read = sprite_attr_line;
		end
	      2'b01: // Name table fetch
		vdp_raddr = { ntb, vpos[1:5], hpos[1:5] };
	      2'b10: // Color fetch
		begin
		   vdp_raddr = { ctb, 1'b0, next_pattern_name[0:4] }; // Gfx I
		   if (m3) begin
		      // Graphics II
		      vdp_raddr[1:2] = vdp_raddr[1:2] & vpos[1:2];
		      vdp_raddr[3:10] = next_pattern_name;
		      vdp_raddr[11:13] = vpos[6:8];
		   end
		   if (m2)
		     vdp_read = 1'b0; // No color table in Multicolor mode
		end
	      2'b11: // Pattern fetch
		begin
		   vdp_raddr = { pgb, next_pattern_name, vpos[6:8] }; // Gfx I
		   if (m3)
		     // Graphics II
		     vdp_raddr[1:2] = vdp_raddr[1:2] & vpos[1:2];
		   if (m2)
		     // Multicolor
		     vdp_raddr[11:13] = vpos[4:6];
		end
	    endcase // case (hpos[6:7])
	 end
      end else if (hpos < (HACTIVE+6*8)) begin // if (hpos < HACTIVE)
	 vdp_read = sprvalid[hpos[6:7]];
	 // Sprite attribute/pattern fetch
	 if (hpos[3]) begin
	    // Pattern
	    vdp_raddr = { spgb, sprname[hpos[6:7]], 3'b000 };
	    if (size) begin
	       vdp_raddr[9] = hpos[5];
	       vdp_raddr[10:13] = sprvoffs[hpos[6:7]][0:3];
	    end else begin
	       vdp_raddr[11:13] = sprvoffs[hpos[6:7]][1:3];
	       if(hpos[5])
		 vdp_read = 1'b0;
	    end
	 end else begin
	    // Attribute
	    vdp_raddr = { sab, sprnum[hpos[6:7]], hpos[4:5] };
	    if (hpos[4:5] == 2'b00)
	      vdp_read = 1'b0; // Vpos already fetched
	 end
      end

      if (reset || blank == 1'b0 || hpos[8])
	// Read cycle starts on even pixel, and ends on odd pixel
	vdp_read = 1'b0;

      if (!k16)
	vdp_raddr[0:1] = 2'b00;
   end

   always @(posedge clk) begin

      // Register access, available every clk cycle
      
      if (reset) begin
	 m3 <= 1'b0;
	 ev <= 1'b0;
	 k16 <= 1'b0;
	 blank <= 1'b0;
	 ie <= 1'b0;
	 m1 <= 1'b0;
	 m2 <= 1'b0;
	 size <= 1'b0;
	 mag <= 1'b0;

	 ntb <= 4'h0;
	 ctb <= 8'h00;
	 pgb <= 3'h0;
	 sab <= 7'h00;
	 spgb <= 3'h0;

	 color1 <= 4'h0;
	 color0 <= 4'h0;

	 sn5 <= 5'd0;

      end else if (reg_wstrobe) // if (reset)
	case (reg_addr)
	  3'b000: begin // Register 0
	     m3 <= reg_wdata[6];
	     ev <= reg_wdata[7];
	  end
	  3'b001: begin // Register 1
	     k16 <= reg_wdata[0];
	     blank <= reg_wdata[1];
	     ie <= reg_wdata[2];
	     m1 <= reg_wdata[3];
	     m2 <= reg_wdata[4];
	     size <= reg_wdata[6];
	     mag <= reg_wdata[7];
	  end
 	  3'b010: ntb <= reg_wdata[4:7]; // Register 2
	  3'b011: ctb <= reg_wdata[0:7]; // Register 3
	  3'b100: pgb <= reg_wdata[5:7]; // Register 4
	  3'b101: sab <= reg_wdata[1:7]; // Register 5
	  3'b110: spgb <= reg_wdata[5:7]; // Register 6
	  3'b111: begin // Register 7
	     color1 <= reg_wdata[0:3];
	     color0 <= reg_wdata[4:7];
	  end
 	endcase // case (reg_addr)

      if (reset || reg_rstrobe) begin
	 f <= 1'b0;
	 s5 <= 1'b0;
	 c <= 1'b0;
      end

      if (!reset && clk_en) begin
	 if (hpos == HSYNC_START-1 && vpos == BBORDER_START-1)
	   // End of active display interrupt
	   f <= 1'b1;
	 if (!s5 || reg_rstrobe) begin
	    if (blank == 1'b0 || m1)
	      // Sprites disabled
	      sn5 <= 5'd31;
	    else begin
	       // Fifth sprite number & flag
	       if (sprite_attr_line && hpos < HACTIVE)
		 sn5 <= hpos[1:5];
	       if (new_sprite && next_in_turn[NSPRITES] && (!f || reg_rstrobe))
		 s5 <= 1'b1;
	    end
	 end
	 if (vpos >= VACTIVE_START && vpos < BBORDER_START &&
	     hpos >= HACTIVE_START && hpos < RBORDER_START &&
	     blank == 1'b1 && |sprcoinc)
	   // Coincidence flag
	   c <= 1'b1;
      end

   end

   always @(posedge clk) begin

      // Pixel generation, only active on pixel clock (clk_en == 1)
      
      if (reset && clk_en) begin
	 hpos <= HSYNC_START;
         vpos <= VSYNC_START;
	 sync_h <= 1'b0;
	 sync_v <= 1'b0;
	 cburst <= 1'b0;
	 color <= 4'h0;
	 pattern_bits <= 8'h00;
	 pattern_color <= 8'h00;
	 textpos <= 10'h000;
	 new_sprite = 1'b0;
	 color_en <= 1'b0;

      end else if(clk_en) begin

	 sync_h <= (hpos >= HSYNC_START && hpos < LBLANKING1_START);
	 sync_v <= (vpos >= VSYNC_START && vpos < TBLANKING_START);

	 if (vpos >= BBLANKING_START && vpos < TBORDER_START) begin
	    // vertical blanking
	    cburst <= 1'b0;
	    color <= 4'h0;
	    color_en <= 1'b0;
	 end else begin
	    cburst <= (hpos >= COLORBURST_START && hpos < LBLANKING2_START);
	    color_en <= 1'b1;
	    if (hpos >= RBLANKING_START && hpos < LBORDER_START) begin
	       // horizontal blanking
	       color <= 4'h0;
	       color_en <= 1'b0;
	    end else if (vpos >= VACTIVE_START && vpos < BBORDER_START &&
		     hpos >= HACTIVE_START && hpos < RBORDER_START &&
		     blank == 1'b1)
	      // main display
	      color <= ((|color_chain[0])? color_chain[0] : color0);
	    else
	      // border
	      color <= color0;
	 end

	 pattern_bits <= { pattern_bits[1:7], 1'b0 };

	 new_sprite = 1'b0;
	 if (sprite_attr_line && !m1 && hpos < HACTIVE && hpos[6:8] == 3'b001)
	   // Sprite VPOS attribute
	   if (vdp_rdata == 8'hD0)
	     sprite_attr_line <= 1'b0;
	   else
	     sprite_ymatch(vdp_rdata, new_sprite_voffs, new_sprite);

	 if (vpos < VACTIVE && hpos < HACTIVE) begin
	    if (m1) begin
	       // Text mode
	       if (hpos[1:5] != 5'd0 && hpos[1:5] != 5'd31) begin
		  if (hpos[7:8] == 2'b01)
		    next_pattern_name <= vdp_rdata;
		  if (hpos[6:8] == 3'b111)
		    pattern_color <= { color1, color0 };
		  if (hpos[6:8] == 3'b111)
		    case (textpos[8:9])
		      2'b01: pattern_bits <= { textsave, vdp_rdata[0:1] };
		      2'b10: pattern_bits <= { textsave[2:5], vdp_rdata[0:3] };
		      2'b11: pattern_bits <= { textsave[4:5], vdp_rdata[0:5] };
		    endcase // case (textpos[8:9])
		  if (hpos[7:8] == 2'b11 &&
		      (hpos[6] == 1'b1 || (textpos[8:9] == 2'b00))) begin
		     textsave <= vdp_rdata[0:5];
		     textpos <= textpos + 10'd1;
		  end
	       end
	    end else
	      case (hpos[6:8])
		3'b011:
		  next_pattern_name <= vdp_rdata;
		3'b101:
		  next_pattern_color <= vdp_rdata;
		3'b111:
		  if (m2) begin
		     // Multicolor
		     pattern_bits <= 8'hf0;
		     pattern_color <= vdp_rdata;
		  end else begin
		     // Graphics I / II
		     pattern_bits <= vdp_rdata;
		     pattern_color <= next_pattern_color;
		  end
	      endcase // case (hpos[6:8])
	 end

	 if (hpos == 0)
	   textpossave <= textpos[0:6];
	 if (hpos == HACTIVE && vpos[6:8] != 3'b111)
	   textpos <= { (vpos[0]? 7'h00 : textpossave), 3'b000 };

	 if (hpos == HSYNC_START-1) begin
	    // Next line has sprite attributes if it is in the range
	    // -1 to VACTIVE-1, which means the current line is in the
	    // range -2 to VACTIVE-2
	    sprite_attr_line <= (&vpos[0:7] || vpos < VACTIVE-1);

	    if (vpos == BBLANKING_START + BBLANKING - 1)
	      vpos <= VSYNC_START;
	    else
	      vpos <= vpos + 9'd1;
	 end // if (hpos == HSYNC_START)

	 if (hpos == HTOTAL - 1)
	   hpos <= 9'd0;
	 else
	   hpos <= hpos + 9'd1;
	 
      end

   end
   
   
endmodule // tms9918_vdp
