module tms6100_vsm(input  clk,
		   input  clk_en,
		   input  m0,
		   input  m1,
		   input  add8,
		   input  add4,
		   input  add2,
		   input  add1,
		   output data_out,

		   // ROM access wishbone slave
		   input [17:0] wb_adr_i,
		   input [7:0]  wb_dat_i,
		   output [7:0] wb_dat_o,
		   input	wb_we_i,
		   input [0:0]  wb_sel_i,
		   input	wb_stb_i,
		   output reg   wb_ack_o,
		   input	wb_cyc_i);

   parameter vsm_size = 16384;

   reg [7:0]  rom_data;
   reg [7:0]  prefetch_data;
   reg [7:0]  shift_reg;
   reg [17:0] rom_addr;
   reg [7:0]  rom[0:(vsm_size-1)];

   reg do_prefetch = 1'b0;
   reg prefetch_done = 1'b0;
   reg do_branch = 1'b0;
   reg [2:0] bitcnt = 3'b000;
   reg [2:0] load_pointer = 3'b000;

   assign data_out = shift_reg[0];
   assign wb_dat_o = rom_data;

   always @(posedge clk) begin
      if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0])
	rom[wb_adr_i] <= wb_dat_i;
      wb_ack_o <= wb_cyc_i && wb_stb_i && !wb_ack_o &&
		  (wb_we_i || !do_prefetch);
      if (prefetch_done)
	prefetch_data <= rom_data;
      prefetch_done <= do_prefetch;
      if (do_prefetch || (wb_cyc_i && wb_stb_i && !wb_we_i))
	rom_data <= rom[(do_prefetch ? rom_addr : wb_adr_i)];
      if (do_prefetch) begin
	 rom_addr <= rom_addr + 18'd1;
	 do_prefetch <= 1'b0;
      end

      if (do_branch) begin
	 if (do_prefetch && !prefetch_done)
	   do_prefetch <= 1'b1;
	 if (prefetch_done && !do_prefetch) begin
	    rom_addr[7:0] <= prefetch_data;
	    rom_addr[13:8] <= rom_data[5:0];
	    do_branch <= 1'b0;
	    do_prefetch <= 1'b1;
	 end
      end
      
      if (clk_en)
	case ({ m0, m1 })
	  2'b00: ; // Idle
	  2'b01: begin // Load Address
	     case (load_pointer)
	       3'b000: rom_addr[3:0] <= { add8, add4, add2, add1 };
	       3'b001: rom_addr[7:4] <= { add8, add4, add2, add1 };
	       3'b010: rom_addr[11:8] <= { add8, add4, add2, add1 };
	       3'b011: rom_addr[15:12] <= { add8, add4, add2, add1 };
	       3'b100: rom_addr[17:16] <= { add2, add1 };
	     endcase // case (load_pointer)
	     if (load_pointer != 3'b111)
	       load_pointer <= load_pointer + 3'b001;
	     bitcnt <= 3'b111;
	  end
	  2'b10: begin // Read
	     load_pointer <= 3'b000;
	     if (bitcnt == 3'b000)
	       shift_reg <= prefetch_data;
	     else
	       shift_reg <= { 1'b0, shift_reg[7:1] };
	     if (bitcnt == 3'b111)
		do_prefetch <= 1'b1;
	     bitcnt <= bitcnt + 3'b001;
	  end
	  2'b11: begin // Read and Branch
	     do_branch <= 1'b1;
	     do_prefetch <= 1'b1;
	     prefetch_done <= 1'b0;
	     bitcnt <= 3'b000;
	  end
	endcase // case ({ m0, m1 })

   end // always @ (posedge clk)

endmodule // tms6100_vsm
