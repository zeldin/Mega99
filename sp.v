module sp(input         clk,
	  input		reset,
	  output [0:23]	wb_adr_o,
	  output [0:7]	wb_dat_o,
	  input [0:7]	wb_dat_i,
	  output	wb_we_o,
	  output [0:0]	wb_sel_o,
	  output	wb_stb_o,
	  input		wb_ack_i,
	  output	wb_cyc_o,

	  output	tp_valid,
	  output [0:31]	tp_pc,
	  output [0:31]	tp_insn);

   wire [0:31] or1k_i_adr;
   wire	       or1k_i_stb;
   wire	       or1k_i_cyc;
   wire [0:3]  or1k_i_sel;
   wire	       or1k_i_we;
   wire [0:2]  or1k_i_cti;
   wire [0:1]  or1k_i_bte;
   wire [0:31] or1k_i_dato;
   wire	       or1k_i_err;
   reg	       or1k_i_ack;
   wire [0:31] or1k_i_dati;
   wire	       or1k_i_rty;

   wire [0:31] or1k_d_adr;
   wire	       or1k_d_stb;
   wire	       or1k_d_cyc;
   wire [0:3]  or1k_d_sel;
   wire	       or1k_d_we;
   wire [0:2]  or1k_d_cti;
   wire [0:1]  or1k_d_bte;
   wire [0:31] or1k_d_dato;
   wire	       or1k_d_err;
   reg	       or1k_d_ack;
   wire [0:31] or1k_d_dati;
   wire	       or1k_d_rty;

   wire [0:31] or1k_irq;

   reg [0:1]   db_subaddr;
   reg [0:31]  db_shiftreg;

   reg [0:31]  boot_rom[0:2047];
   reg [0:31]  boot_rom_data;

   assign or1k_irq = 32'd0;

   assign or1k_i_err = 1'b0;
   assign or1k_i_dati = boot_rom_data;
   assign or1k_i_rty = 1'b0;
   
   assign or1k_d_err = 1'b0;
   assign or1k_d_dati = db_shiftreg;
   assign or1k_d_rty = 1'b0;

   assign wb_adr_o = { or1k_d_adr[8:29], db_subaddr };
   assign wb_dat_o = ( db_subaddr[0] ?
	       ( db_subaddr[1] ? or1k_d_dato[24:31] : or1k_d_dato[16:23] ) :
	       ( db_subaddr[1] ? or1k_d_dato[8:15] : or1k_d_dato[0:7] ) );
   assign wb_we_o  = or1k_d_we;
   assign wb_sel_o = or1k_d_sel[db_subaddr];
   assign wb_stb_o = or1k_d_stb && !or1k_d_ack;
   assign wb_cyc_o = or1k_d_cyc;

   initial $readmemh("or1k_boot_code.hex", boot_rom);

   always @(posedge clk) begin
      if (reset || or1k_i_ack)
	or1k_i_ack <= 1'b0;
      else if (or1k_i_cyc && or1k_i_stb) begin
	 boot_rom_data <= boot_rom[or1k_i_adr[19:29]];
	 or1k_i_ack <= 1'b1;
      end

      if (reset || or1k_d_ack) begin
	 or1k_d_ack <= 1'b0;
	 db_subaddr <= 2'b00;
      end else if (wb_ack_i) begin
	 db_shiftreg <= { db_shiftreg[8:31], wb_dat_i };
	 if (db_subaddr == 2'b11)
	   or1k_d_ack <= 1'b1;
	 db_subaddr <= db_subaddr + 2'd1;
      end
   end

   mor1kx #(.OPTION_OPERAND_WIDTH(32), .BUS_IF_TYPE("WISHBONE32"),
	    .FEATURE_TRACEPORT_EXEC("ENABLED"))
   or1k (.clk(clk), .rst(reset),

	 .iwbm_adr_o(or1k_i_adr), .iwbm_stb_o(or1k_i_stb),
	 .iwbm_cyc_o(or1k_i_cyc), .iwbm_sel_o(or1k_i_sel),
	 .iwbm_we_o(or1k_i_we), .iwbm_cti_o(or1k_i_cti),
	 .iwbm_bte_o(or1k_i_bte), .iwbm_dat_o(or1k_i_dato),
	 .iwbm_err_i(or1k_i_err), .iwbm_ack_i(or1k_i_ack),
	 .iwbm_dat_i(or1k_i_dati), .iwbm_rty_i(or1k_i_rty),

	 .dwbm_adr_o(or1k_d_adr), .dwbm_stb_o(or1k_d_stb),
	 .dwbm_cyc_o(or1k_d_cyc), .dwbm_sel_o(or1k_d_sel),
	 .dwbm_we_o(or1k_d_we), .dwbm_cti_o(or1k_d_cti),
	 .dwbm_bte_o(or1k_d_bte), .dwbm_dat_o(or1k_d_dato),
	 .dwbm_err_i(or1k_d_err), .dwbm_ack_i(or1k_d_ack),
	 .dwbm_dat_i(or1k_d_dati), .dwbm_rty_i(or1k_d_rty),

	 .irq_i(irq_i),

	 .du_addr_i(16'h0000), .du_stb_i(1'b0), .du_dat_i(32'h00000000),
	 .du_we_i(1'b0), .du_dat_o(), .du_ack_o(),
	 .du_stall_i(1'b0), .du_stall_o(),

	 .traceport_exec_valid_o(tp_valid),
	 .traceport_exec_pc_o(tp_pc),
	 .traceport_exec_jb_o(),
	 .traceport_exec_jal_o(),
	 .traceport_exec_jr_o(),
	 .traceport_exec_jbtarget_o(),
	 .traceport_exec_insn_o(tp_insn),
	 .traceport_exec_wbdata_o(),
	 .traceport_exec_wbreg_o(),
	 .traceport_exec_wben_o(),

	 .multicore_coreid_i(32'd0), .multicore_numcores_i(32'd1),

	 .snoop_adr_i(32'h00000000), .snoop_en_i(1'b0));

endmodule // sp
