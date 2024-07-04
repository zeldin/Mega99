module tms9918_vdpram(input clk,

		      // VDP read port
		      input	   clk_en_vdp,
		      input	   clk_en_vdp_next, // value of clk_en_vdp next clk cycle
		      input	   vdp_read,
		      input [0:13] vdp_raddr,
		      output [0:7] vdp_rdata,

		      // CPU read/write port
		      input	   cpu_read,
		      input	   cpu_write,
		      input [0:13] cpu_addr,
		      input [0:7]  cpu_wdata,
		      output [0:7] cpu_rdata,
		      output	   cpu_read_ready,
		      
		      // Wishbone read/write access port
		      input [0:13] wb_adr_i,
		      input [0:7]  wb_dat_i,
		      output [0:7] wb_dat_o,
		      input	   wb_we_i,
		      input [0:0]  wb_sel_i,
		      input	   wb_stb_i,
		      output reg   wb_ack_o,
		      input	   wb_cyc_i);

   reg [0:7] vdpram_mem[0:16383];
   reg [0:7] rdata;
   reg	     vdp_read_latch;

   assign vdp_rdata = rdata;
   assign wb_dat_o = rdata;
   assign cpu_rdata = rdata;
   
   wire	     vdp_read_cycle;
   wire	     wb_read_cycle;
   wire	     wb_write_cycle;

   assign vdp_read_cycle = clk_en_vdp_next &&
			   (vdp_read_latch || (clk_en_vdp && vdp_read));
   assign wb_read_cycle = wb_cyc_i && wb_stb_i && !wb_we_i && !wb_ack_o;
   assign wb_write_cycle = wb_cyc_i && wb_stb_i && wb_we_i && !wb_ack_o;
   assign cpu_read_ready = !vdp_read_cycle;
   
   always @(posedge clk) begin

      wb_ack_o <= 1'b0;

      // Write port
      if (cpu_write || (wb_write_cycle && wb_sel_i[0]))
	vdpram_mem[(cpu_write ? cpu_addr : wb_adr_i)]
	  <= (cpu_write? cpu_wdata : wb_dat_i);

      if (!cpu_write && wb_write_cycle)
	wb_ack_o <= 1'b1;

      
      // Read port
      if (vdp_read_cycle || cpu_read || wb_read_cycle)
	rdata <= vdpram_mem[(vdp_read_cycle ? vdp_raddr :
			     (cpu_read ? cpu_addr : wb_adr_i))];

      if (!vdp_read_cycle && !cpu_read && wb_read_cycle)
	wb_ack_o <= 1'b1;


      // Delay VDP read if next cycle is not a VDP cycle
      if (clk_en_vdp_next)
	vdp_read_latch <= 1'b0;
      else if (clk_en_vdp && vdp_read)
	vdp_read_latch <= 1'b1;

   end

endmodule // tms9918_vdpram
