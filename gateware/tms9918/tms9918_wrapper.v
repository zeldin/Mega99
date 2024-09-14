module tms9918_wrapper(input reset,
		       input	    clk, // Enabled cycles should give
		       input	    clk_en, // pixel clock, 5.3693175 MHz
		       input	    clk_en_next, // value of clk_en next cycle

		       // Video output
		       output	    sync_h,
		       output	    sync_v,
		       output	    cburst,
		       output [0:3] color,
		       output       color_en,
		       output	    extvideo,

		       // CPU interface
		       input [0:7]  cd,
		       output [0:7] cq,
		       input	    csr,
		       input	    csw,
		       input	    mode,
		       output	    int_pending,

		       // VDP RAM and register wishbone slave
		       input [0:14] wb_adr_i,
		       input [0:7]  wb_dat_i,
		       output [0:7] wb_dat_o,
		       input	    wb_we_i,
		       input [0:0]  wb_sel_i,
		       input	    wb_stb_i,
		       output	    wb_ack_o,
		       input	    wb_cyc_i,

		       // Debug monitoring of CPU VDP address
		       output [0:13] debug_vdp_addr);

   wire [0:13] vaddr;
   wire [0:7]  vdata;
   wire	       vread;

   wire [0:2]  raddr;
   wire [0:7]  rwdata;
   wire	       rwrite;
   wire [0:7]  rrdata;
   wire	       rread;

   wire	       cvread;
   wire	       cvwrite;
   wire [0:13] cvaddr;
   wire [0:7]  cvwdata;
   wire [0:7]  cvrdata;
   wire        cvr_ready;

   wire [0:7]  wb_dat_o_ram;
   wire        wb_ack_o_ram;
   wire	       wb_reg_write;
   wire	       cpuifc_regw_master;

   assign wb_dat_o = (wb_adr_i[0] ? rrdata : wb_dat_o_ram);
   assign wb_ack_o = (wb_adr_i[0] ? !(rwrite && wb_we_i && wb_sel_i[0]) :
		      wb_ack_o_ram);
   assign wb_reg_write = (wb_we_i && wb_sel_i[0] &&
			  wb_adr_i[0] && wb_stb_i && wb_cyc_i);
   assign cpuifc_regw_master = (rwrite || !wb_reg_write);
   
   assign debug_vdp_addr = cvaddr;

   tms9918_vdp vdp(.reset(reset), .clk(clk), .clk_en(clk_en),
		   .sync_h(sync_h), .sync_v(sync_v), .cburst(cburst),
		   .color(color), .color_en(color_en), .extvideo(extvideo),
		   .vdp_raddr(vaddr), .vdp_rdata(vdata), .vdp_read(vread),
		   .reg_addr((cpuifc_regw_master? raddr : wb_adr_i[12:14])),
		   .reg_wdata((cpuifc_regw_master? rwdata : wb_dat_i)),
		   .reg_wstrobe(rwrite || wb_reg_write),
		   .reg_rdata(rrdata), .reg_rstrobe(rread),
		   .int_pending(int_pending));

   tms9918_cpuifc cpuifc(.reset(reset), .clk(clk),
			 .cd(cd), .cq(cq), .csr(csr), .csw(csw),
			 .mode(mode), .reg_addr(raddr),
			 .reg_wdata(rwdata), .reg_wstrobe(rwrite),
			 .reg_rdata(rrdata), .reg_rstrobe(rread),
			 .vdp_read(cvread), .vdp_write(cvwrite),
			 .vdp_addr(cvaddr), .vdp_wdata(cvwdata),
			 .vdp_rdata(cvrdata), .vdp_read_ready(cvr_ready));

   tms9918_vdpram vdpram(.clk(clk),
			 .clk_en_vdp(clk_en), .clk_en_vdp_next(clk_en_next),
			 .vdp_read(vread), .vdp_raddr(vaddr), .vdp_rdata(vdata),
			 .cpu_read(cvread), .cpu_write(cvwrite),
			 .cpu_addr(cvaddr), .cpu_wdata(cvwdata),
			 .cpu_rdata(cvrdata), .cpu_read_ready(cvr_ready),
			 .wb_adr_i(wb_adr_i[1:14]), .wb_dat_i(wb_dat_i),
			 .wb_dat_o(wb_dat_o_ram), .wb_we_i(wb_we_i),
			 .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_i && !wb_adr_i[0]),
			 .wb_ack_o(wb_ack_o_ram), .wb_cyc_i(wb_cyc_i));
   
endmodule // tms9918_wrapper
