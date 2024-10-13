module fdc1771_mockdrive(input        clk,
			 input	      clk_3mhz_en,

			 output	      ready,
			 output	      byte_clk,
			 output	      header_clk,
			 output [5:0] track,
			 output [4:0] sector,
			 output	      ip,
			 output	      ds,

			 input	      sel,
			 input	      step,
			 input	      dir,
			 input	      byte_clk_next,
			 input	      header_clk_next,
			 input [5:0]  track_next,
			 input [4:0]  sector_next,
			 input	      ip_next,
			 input	      ds_next,

			 input	      load_mounted,
			 input	      load_ds,
			 input	      load_dd,
			 input [4:0]  load_sps,
			 input	      load_strobe);

   localparam MAX_TRACK = 6'd40;

   reg	      byte_clk_reg;
   reg	      header_clk_reg;
   reg	      ip_reg;
   reg	      mounted_reg;
   reg	      ds_reg;
   reg	      dd_reg;
   reg [4:0]  sps_reg;
   reg [5:0]  track_reg = 6'd0;
   reg [4:0]  sector_reg;
   reg [7:0]  byte_clk_cnt = 8'd0;
   reg [8:0]  sector_byte_cnt = 9'd0;
   reg	      step_last;

   assign ready = mounted_reg;
   assign byte_clk = (sel ? byte_clk_reg : byte_clk_next);
   assign header_clk = (sel ? header_clk_reg : header_clk_next);
   assign track = (sel ? track_reg : track_next);
   assign sector = (sel ?
		    (sector_reg == sps_reg ? 5'd0 : sector_reg) : sector_next);
   assign ip = (sel ? ip_reg : ip_next);
   assign ds = (sel ? ds_reg : ds_next);

   /* Track step */
   always @(posedge clk) begin
      if (step_last && !step) begin
	 if (dir && track_reg != 6'd63)
	   track_reg <= track_reg + 6'd1;
	 if (!dir && track_reg != 6'd0)
	   track_reg <= track_reg - 6'd1;
      end
      step_last <= step;
   end

   /* Image load */
   always @(posedge clk)
     if (load_strobe) begin
	mounted_reg <= load_mounted;
	ds_reg <= load_ds;
	dd_reg <= load_dd;
	sps_reg <= load_sps;
     end

   /* Byte clock */
   always @(posedge clk) begin
      byte_clk_reg <= 1'b0;
      if (clk_3mhz_en) begin
	 if (|byte_clk_cnt)
	   byte_clk_cnt <= byte_clk_cnt - 8'd1;
	 else begin
	    byte_clk_cnt <= (dd_reg ? 8'd93 : 8'd186);
	    byte_clk_reg <= mounted_reg;
	 end
      end
   end

   /* Index and sector header */
   always @(posedge clk) begin
      header_clk_reg <= 1'b0;
      ip_reg <= 1'b0;
      if (byte_clk_reg) begin
	 sector_byte_cnt <= sector_byte_cnt + 9'd1;
	 if (sector_reg == sps_reg) begin
	    if (sector_byte_cnt == 9'd8)
	      ip_reg <= 1'b1;
	    if (sector_byte_cnt == (dd_reg ? 9'd131 : 9'd251)) begin
	       sector_reg <= 5'd0;
	       sector_byte_cnt <= 9'd0;
	    end
	 end else begin
	    if (sector_byte_cnt == 9'd8)
	      header_clk_reg <= 1'b1;
	    if (sector_byte_cnt == (dd_reg ? 9'd350 : 9'd324)) begin
	       sector_byte_cnt <= 9'd0;
	       sector_reg <= sector_reg + 5'd1;
	    end
	 end
      end
      if (load_strobe)
	sector_reg <= 5'd0;
   end

endmodule // fdc1771_mockdrive
