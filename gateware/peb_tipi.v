module peb_tipi(input        clk,
		input	     reset,
		input	     enable,
		input [0:3]  crubase,

		input [0:15] a,
		input [0:7]  d,
		output [0:7] q,
		output	     q_select,
		input	     memen,
		input	     we,
		input	     cruclk,
		output reg   cruin,
		output	     cru_select,
		output	     ready,
		output	     led,
		
		input	     r_clk,
		input	     r_rt,
		input	     r_le,
		output	     r_reset,
		input	     r_dout,
		output	     r_din,
		input	     r_dc,

		// ROM access wishbone slave
		input [0:14] wb_adr_i,
		input [0:7]  wb_dat_i,
		output [0:7] wb_dat_o,
		input	     wb_we_i,
		input [0:0]  wb_sel_i,
		input	     wb_stb_i,
		output reg   wb_ack_o,
		input	     wb_cyc_i);

   // Real TIPI has 32K ROM, but less than 4K is used, so let's be frugal...
   parameter DSR_ROM_SIZE_K = 4;

   reg [0:5] r_clk_cdc = 6'd0;
   reg	     r_rt_cdc;
   reg	     r_le_cdc;
   reg	     r_dout_cdc;
   reg	     r_dc_cdc;
   reg	     tick = 1'b0;

   reg [0:7] shift_dout = 8'h00;
   reg [0:7] shift_din = 8'h00;
   reg	     parity_dout = 1'b0;
   reg	     r_din_dly = 1'b0;

   reg [0:7] latch_tc = 8'h00;
   reg [0:7] latch_td = 8'hab;
   reg [0:7] latch_rc = 8'h00;
   reg [0:7] latch_rd = 8'h00;

   reg	     dsr_enable = 1'b0;
   reg	     rpi_enable = 1'b0;
   reg [1:0] dsr_bank = 2'b00;

   wire	       dsr_select;
   wire	       reg_select;
   reg [0:7]   reg_data;
   reg [0:7]   dsr_rom [0:(DSR_ROM_SIZE_K*1024-1)];
   reg [0:7]   dsr_rom_data;
   wire [0:14] readaddr;

   assign q_select = dsr_enable && (a[0:2] == 3'b010);
   assign cru_select = enable && (a[0:3] == 4'h1) && (a[4:7] == crubase);
   assign dsr_select = q_select && memen && !we;
   assign reg_select = (a[0:11] == 12'h5ff && a[12]);
   assign readaddr = (dsr_select ? { dsr_bank, a[3:15] } : wb_adr_i[0:14] );
   assign q = (reg_select ? reg_data : dsr_rom_data);
   assign ready = 1'b1;
   assign led = dsr_enable;
   assign wb_dat_o = dsr_rom_data;
   
   assign r_reset = ~rpi_enable;
   assign r_din = (r_rt_cdc ? r_din_dly : parity_dout ^ shift_dout[7]);

   always @(*) begin
      cruin <= 1'b0;
      case (a[13:14])
	2'b00: cruin <= dsr_enable;
	2'b01: cruin <= rpi_enable;
	2'b10: cruin <= dsr_bank[0];
	2'b11: cruin <= dsr_bank[1];
      endcase // case (a[13:14])
   end // always @ (*)

   always @(posedge clk)
     if (reset || !enable) begin
	dsr_enable <= 1'b0;
	rpi_enable <= 1'b0;
	dsr_bank <= 2'b00;
     end else if (cruclk && cru_select)
       case (a[13:14])
	 2'b00: dsr_enable <= a[15];
	 2'b01: rpi_enable <= a[15];
	 2'b10: dsr_bank[0] <= a[15];
	 2'b11: dsr_bank[1] <= a[15];
       endcase // case (a[13:14])
 
   always @(posedge clk)
     if (q_select && memen && !we)
       case (a[13:15])
	 3'b001: reg_data <= latch_rc;
	 3'b011: reg_data <= latch_rd;
	 3'b101: reg_data <= latch_tc;
	 3'b111: reg_data <= latch_td;
	 default: reg_data <= 8'h00;
       endcase // case (a[13:15])

   always @(posedge clk)
     if (q_select && memen && we && reg_select)
       case (a[13:15])
	 3'b101: latch_tc <= d;
	 3'b111: latch_td <= d;
       endcase // case (a[13:15])

   always @(posedge clk) begin
      // Read port
      if (dsr_select || (wb_cyc_i && wb_stb_i && !wb_we_i))
	dsr_rom_data <= dsr_rom[readaddr];
      // Write port
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && wb_sel_i[0] &&
	  wb_adr_i[0:14] < DSR_ROM_SIZE_K*1024)
	dsr_rom[wb_adr_i[0:14]] <= wb_dat_i;
   end

   always @(posedge clk) begin
      // Wishbone handshake
      if (!wb_cyc_i || !wb_stb_i || wb_ack_o)
	wb_ack_o <= 1'b0;
      else
	wb_ack_o <= wb_we_i || !dsr_select;
   end

   always @(posedge clk) begin
      tick <= 1'b0;
      if (r_clk_cdc[0:3] == 4'b0001) begin
	 tick <= 1'b1;
	 r_rt_cdc <= r_rt;
	 r_le_cdc <= r_le;
	 r_dout_cdc <= r_dout;
	 r_dc_cdc <= r_dc;
      end
      r_clk_cdc <= { r_clk_cdc[1:5], r_clk };
   end

   always @(posedge clk) // posedge r_clk
     if (tick) begin
	if (r_le_cdc) begin
	   /* Latch cycle */
	   shift_din <= (r_dc_cdc ? latch_td : latch_tc);
	   if (!r_rt_cdc && r_dc_cdc)
	     latch_rd <= shift_dout;
	   if (!r_rt_cdc && !r_dc_cdc)
	     latch_rc <= shift_dout;
	end else begin
	   /* Shift cycle */
	   parity_dout <= parity_dout ^ shift_dout[0] ^ shift_dout[7];
	   shift_dout <= { shift_dout[1:7], r_dout_cdc };
	   r_din_dly <= shift_din[0];
	   shift_din <= { shift_din[1:7], ^shift_din };
	end // else: !if(r_le_cdc)
     end // if (tick)

endmodule // peb_tipi
