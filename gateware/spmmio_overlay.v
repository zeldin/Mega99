module spmmio_overlay(input             clk,
		      input		reset,

		      input [0:12]	adr,
		      input		cs,
		      input [0:3]	sel,
		      input		we,
		      input [0:31]	d,
		      output [0:31]	q,
		      output		ack,

		      input		pixel_clock,
		      input		vsync,
		      input		hsync,
		      output reg [0:3]	color);

   parameter integer num_windows = 4;

   reg [0:9] xcnt;
   reg [0:9] ycnt;
   reg	     hdisp_en, vdisp_en;

   reg [0:7] xadj;
   reg [0:7] yadj;

   reg [0:7] pixel_shiftreg;
   reg [0:7] pixel_color;
   reg [0:7] display_pixels;
   reg [0:7] display_color;
   reg	     display_load;
   reg	     display_loaded;
   reg	     frame_start;
   reg	     line_start;

   reg [0:3]  window_enabled;
   wire [0:3] window_active;

   reg [0:7]  memory0 [0:4095];
   reg [0:7]  memory1 [0:4095];
   reg [0:7]  memory2 [0:4095];
   reg [0:7]  memory3 [0:4095];
   reg [0:31]  mem_read;
   wire [0:11] mem_read_addr;
   wire [0:11] mem_write_addr;
   wire [0:12] window_addr;
   reg [0:12]  display_mem_addr;
   wire	       cpu_mem_read;
   reg	       mem_read_ack;
   reg [0:31]  reg_data;

   assign cpu_mem_read = cs && adr[0] == 1'b0 && !we;
   assign ack = ((adr[0] == 1'b0 && !we) ? mem_read_ack : cs);
   assign q = (mem_read_ack ? mem_read : reg_data);

   assign mem_read_addr = (display_load ? display_mem_addr[0:11] : adr[1:12]);
   assign mem_write_addr = adr[1:12];

   generate
      if (num_windows < 1 || num_windows > 4)
	initial $fatal(0, "num_windows must be between 1 and 4");
   endgenerate

   wire [0:(64*num_windows-1)] window_readback;
   wire [0:1] max_window;
   assign max_window = num_windows - 1;

   genvar window_id;
   generate
      for (window_id = 0; window_id < num_windows; window_id = window_id + 1)
	begin : WINDOW
	   reg active;
	   reg active_line;
	   reg [0:5] y0;
	   reg [0:5] y1;
	   reg [0:6] x0;
	   reg [0:6] x1;
	   reg [0:12] base;
	   reg [0:12] lineoffs;
	   reg [0:12] current;
	   reg [0:12] last;

	   wire [0:12] addr_out;
	   wire [0:12] addr_in;
	   wire [0:1]  my_color;
	   assign my_color = window_id;

	   assign window_active[window_id] = active;
	   assign window_readback[(64*window_id) +: 64] =
		    { 2'b00, y0, 1'b0, x0, 2'b00, y1, 1'b0, x1,
		      2'b00, base, 1'b0, 2'b00, lineoffs, 1'b0 };

	   assign addr_out = (active ? current : addr_in );
	   if (window_id == 0)
	     assign window_addr = addr_out;
	   else
	     assign WINDOW[window_id-1].addr_in = addr_out;
	   if (window_id == num_windows - 1)
	     assign addr_in = 13'h0000;

	   always @(posedge clk) begin
	      if (pixel_clock) begin
		 if (active && xcnt[7:9] == 3'b111)
		   current <= current + 13'd1;
		 if (hdisp_en && xcnt[7:9] == 3'b000)
		   active <= active_line &&
			     (xcnt[0:6] >= x0) && (xcnt[0:6] < x1);
		 if (line_start) begin
		    if (active_line)
		      current <= last;
		    if (active_line && ycnt[6:9] == 4'b1111)
		      last <= last + lineoffs;
		    active <= 1'b0;
		    active_line <= vdisp_en && window_enabled[window_id] &&
				   (ycnt[0:5] >= y0) && (ycnt[0:5] < y1);

		 end
		 if (frame_start) begin
		    current <= base;
		    last <= base;
		 end
		 if (reset) begin
		    active <= 1'b0;
		    active_line <= 1'b0;
		 end
	      end

	      if (cs && adr[0] == 1'b1 && we &&
		  adr[9:12] == { 1'b0, window_id, 1'b0 }) begin
		 if (sel[0])
		   y0 <= d[7 -: 6];
		 if (sel[1])
		   x0 <= d[15 -: 7];
		 if (sel[2])
		   y1 <= d[23 -: 6];
		 if (sel[3])
		   x1 <= d[31 -: 7];
	      end
	      if (cs && adr[0] == 1'b1 && we &&
		  adr[9:12] == { 1'b0, window_id, 1'b1 }) begin
		 if (sel[0])
		   base[0:5] <= d[2:7];
		 if (sel[1])
		   base[6:12] <= d[8:14];
		 if (sel[2])
		   lineoffs[0:5] <= d[18:23];
		 if (sel[3])
		   lineoffs[6:12] <= d[24:30];
	      end
	   end
	end
   endgenerate

   always @(posedge clk) begin

      display_load <= 1'b0;

      if (pixel_clock) begin

	 frame_start <= 1'b0;
	 line_start <= 1'b0;

	 if (hdisp_en && xcnt != ~10'd0)
	   xcnt <= xcnt + 10'd1;

	 if (hsync && hdisp_en) begin
	    line_start <= 1'b1;
	    xcnt <= ~{ 2'b00, xadj };
	    hdisp_en <= 1'b0;
	    if (vdisp_en && ycnt != ~10'd0)
	      ycnt <= ycnt + 10'd1;
	    if (vsync && vdisp_en) begin
	       frame_start <= 1'b1;
	       ycnt <= ~{ 2'b00, yadj };
	       vdisp_en <= 1'b0;
	    end
	    if (!vsync && !vdisp_en) begin
	       if (|ycnt)
		 ycnt <= ycnt + 1;
	       else
		 vdisp_en <= 1'b1;
	    end
	 end

	 if (!hsync && !hdisp_en) begin
	    if (|xcnt)
	      xcnt <= xcnt + 1;
	    else
	      hdisp_en <= 1'b1;
	 end

	 color <= 4'd0;

	 if (hdisp_en && vdisp_en) begin
	    if (pixel_shiftreg[0])
	      color <= pixel_color[0:3];
	    else
	      color <= pixel_color[4:7];
	    pixel_shiftreg <= { pixel_shiftreg[1:7], 1'b0 };
	    case (xcnt[7:9])
	      3'b000: begin
		 display_pixels <= 8'h00;
		 display_color <= 8'h00;
	      end
	      3'b001: begin
		 display_mem_addr <= window_addr;
		 display_load <= |window_active;
	      end
	      3'b100: display_load <= |window_active;
	      3'b111: begin
		 pixel_shiftreg <= display_pixels;
		 pixel_color <= display_color;
	      end
	    endcase // case (xcnt[7:9])
	 end else // if (hdisp_en && vdisp_en)
	   pixel_color <= 8'h00;

	 if (reset) begin
	    xcnt <= ~10'd0;
	    ycnt <= ~10'd0;
	    hdisp_en <= 1'b1;
	    vdisp_en <= 1'b1;
	    xadj <= 8'd63;
	    yadj <= 8'd81;
	    pixel_shiftreg <= 8'h00;
	    window_enabled <= 4'd0000;
	    frame_start <= 1'b0;
	    line_start <= 1'b0;
	 end
      end // if (pixel_clock)

      if (display_loaded) begin
	 if (xcnt[7])
	   display_pixels <= (ycnt[8] ?
			      (ycnt[9] ? mem_read[24:31] : mem_read[16:23])
			      : (ycnt[9] ? mem_read[8:15] : mem_read[0:7]));
	 else if (display_mem_addr[12]) begin
	    display_color <= mem_read[16:23];
	    display_mem_addr[0:11] <= { 2'b00, mem_read[24:31], ycnt[6:7] };
	 end else begin
	    display_color <= mem_read[0:7];
	    display_mem_addr[0:11] <= { 2'b00, mem_read[8:15], ycnt[6:7] };
	 end
      end

      mem_read_ack <= 1'b0;
      if (display_load || cpu_mem_read) begin
	 mem_read[0:7] <= memory0[mem_read_addr];
	 mem_read[8:15] <= memory1[mem_read_addr];
	 mem_read[16:23] <= memory2[mem_read_addr];
	 mem_read[24:31] <= memory3[mem_read_addr];
	 mem_read_ack <= !display_load;
      end
      display_loaded <= display_load;

      if (cs && adr[0] == 1'b1 && we && sel[0])
	case (adr[9:12])
	   4'h8: xadj <= d[0:7];
	endcase // case (adr[9:12])

      if (cs && adr[0] == 1'b1 && we && sel[1])
	case (adr[9:12])
	   4'h8: yadj <= d[8:15];
	endcase // case (adr[9:12])

      if (cs && adr[0] == 1'b1 && we && sel[3])
	case (adr[9:12])
	   4'h8: window_enabled <= d[28:31];
	endcase // case (adr[9:12])

      if (cs && adr[0] == 1'b0 && we) begin
	 if (sel[0])
	   memory0[mem_write_addr] <= d[0 +: 8];
	 if (sel[1])
	   memory1[mem_write_addr] <= d[8 +: 8];
	 if (sel[2])
	   memory2[mem_write_addr] <= d[16 +: 8];
	 if (sel[3])
	   memory3[mem_write_addr] <= d[24 +: 8];
      end

   end // always @ (posedge clk)

   always @(*) begin
      reg_data <= 32'h00000000;
      if (adr[0] == 1'b1) begin
	 if (adr[9] == 1'b0) begin
	    if (adr[10:11] <= max_window)
	      reg_data <= window_readback[(32*adr[10:12]) +: 32];
	 end
	 else
	   case (adr[10:12])
	     3'h0: begin
		reg_data[0:7] <= xadj;
		reg_data[8:15] <= yadj;
		reg_data[28:31] <= window_enabled;
	     end
	   endcase // case (adr[9:12])
      end
   end

endmodule // spmmio_overlay
