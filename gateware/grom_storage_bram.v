module grom_storage_bram(input		  clk,

			 input [0:3]	  prefetch_grom_set,
			 input [0:15]	  prefetch_grom_addr,
			 input		  do_prefetch,
			 output		  prefetch_complete,
			 output [0:7]	  prefetch_data,

			 // GROM access wishbone slave
			 input [0:15]	  wb_adr_i,
			 input [0:7]	  wb_dat_i,
			 output reg [0:7] wb_dat_o,
			 input		  wb_we_i,
			 input [0:0]	  wb_sel_i,
			 input		  wb_stb_i,
			 output		  wb_ack_o,
			 input		  wb_cyc_i);

   localparam NUM_GROMS = 8;

   wire [0:2]  grom_id;
   wire [0:13] prefetch_page_addr;

   assign grom_id = prefetch_grom_addr[0:2];
   assign prefetch_page_addr = { grom_id, prefetch_grom_addr[5:15] };

   reg [0:7]  grom_page0_byte;
   reg [0:7]  grom_page1_byte;
   reg [0:7]  grom_page2_byte;
   reg [0:2]  grom_page_active;
   reg	      wb_read_complete;

   assign prefetch_complete = 1'b1;
   assign prefetch_data = (grom_page_active[0] ? grom_page0_byte : 8'h00) |
			  (grom_page_active[1] ? grom_page1_byte : 8'h00) |
			  (grom_page_active[2] ? grom_page2_byte : 8'h00);

   assign wb_ack_o = (wb_cyc_i && wb_stb_i && wb_we_i) || wb_read_complete;

   wire [0:13] wb_page_addr;

   assign wb_page_addr = { wb_adr_i[0:2], wb_adr_i[5:15] };

   reg [0:7] grom_page0[0:(2048*NUM_GROMS-1)];
   reg [0:7] grom_page1[0:(2048*NUM_GROMS-1)];
   reg [0:7] grom_page2[0:(2048*NUM_GROMS-1)];

   initial begin
      grom_page_active <= 3'b000;
      wb_read_complete <= 1'b0;
   end

   always @(*)
     case (wb_adr_i[3:4])
       2'b00: wb_dat_o = grom_page0_byte;
       2'b01: wb_dat_o = grom_page1_byte;
       2'b10: wb_dat_o = grom_page2_byte;
       2'b11: wb_dat_o = grom_page1_byte | grom_page2_byte;
       default: wb_dat_o = 8'h00;
     endcase // case (wb_adr_i[3:4])

   always @(posedge clk) begin

      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0])
	case (wb_adr_i[3:4])
	  2'b00: grom_page0[wb_page_addr] <= wb_dat_i;
	  2'b01: grom_page1[wb_page_addr] <= wb_dat_i;
	  2'b10: grom_page2[wb_page_addr] <= wb_dat_i;
	  default: ;
	endcase // case (wb_adr_i[3:4])

      if (do_prefetch ||
	  (wb_cyc_i && wb_stb_i && !wb_we_i && !wb_read_complete)) begin
	 grom_page0_byte <= grom_page0[do_prefetch ?
				       prefetch_page_addr : wb_page_addr];
	 grom_page1_byte <= grom_page1[do_prefetch ?
				       prefetch_page_addr : wb_page_addr];
	 grom_page2_byte <= grom_page2[do_prefetch ?
				       prefetch_page_addr : wb_page_addr];
      end

      if (wb_read_complete)
	wb_read_complete <= 1'b0;
      else
	wb_read_complete <= (wb_cyc_i && wb_stb_i && !wb_we_i && !do_prefetch);

      if (do_prefetch) begin
	 if (grom_id < NUM_GROMS)
	   grom_page_active <= { prefetch_grom_addr[3:4] == 2'b00,
				 prefetch_grom_addr[4] == 1'b1,
				 prefetch_grom_addr[3] == 1'b1 };
	 else
	   grom_page_active <= 3'b000;
      end

   end

endmodule // grom_storage_bram
