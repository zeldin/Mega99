module grom_storage_dma(input	      clk,
			input	      reset,

			input [0:3]   prefetch_grom_set,
			input [0:15]  prefetch_grom_addr,
			input	      do_prefetch,
			output	      prefetch_complete,
			output [0:7]  prefetch_data,

			// GROM access DMA master
			output [0:19] dma_adr,
			input [0:31]  dma_dat,
			output	      dma_stb,
			input	      dma_ack,
			output reg    dma_cyc);

   reg [0:19] fetched_addr;
   reg [0:31] fetched_data;
   reg	      fetched_data_valid = 1'b0;

   assign dma_adr = { prefetch_grom_set, prefetch_grom_addr[0:13], 2'b00 };
   assign dma_stb = dma_cyc;

   assign prefetch_complete = (fetched_data_valid && fetched_addr == dma_adr);
   assign prefetch_data = (prefetch_grom_addr[14] ?
			   (prefetch_grom_addr[15] ?
			    fetched_data[24:31] : fetched_data[16:23]) :
			   (prefetch_grom_addr[15] ?
			    fetched_data[8:15] : fetched_data[0:7]));

   always @(posedge clk)
     if (reset) begin
	fetched_data_valid <= 1'b0;
	dma_cyc <= 1'b0;
     end else if (dma_cyc && dma_ack) begin
	fetched_addr <= dma_adr;
	fetched_data <= dma_dat;
	fetched_data_valid <= 1'b1;
	dma_cyc <= 1'b0;
     end else if (do_prefetch && !prefetch_complete)
       dma_cyc <= 1'b1;

endmodule // grom_storage_dma
