module peb(input            clk,
	   input	    clk_3mhz_en,
	   input	    reset,

	   input [0:15]	    a,
	   input [0:7]	    d,
	   output [0:7]	    q,
	   input	    memen,
	   input	    dbin,
	   input	    we,
	   input	    cruclk,
	   output	    cruin,
	   output	    ready,

	   input [0:22]	    wb_adr_i,
	   input [0:7]	    wb_dat_i,
	   output reg [0:7] wb_dat_o,
	   input	    wb_we_i,
	   input [0:0]	    wb_sel_i,
	   input	    wb_stb_i,
	   output reg	    wb_ack_o,
	   input	    wb_cyc_i);

   wire	      q_select_fdc;
   wire	      q_select_ram32k;
   wire       cru_select_fdc;
   wire [0:7] q_fdc;
   wire [0:7] q_ram32k;
   wire	      cruin_fdc;
   wire	      ready_fdc;
   wire	      ready_ram32k;
   reg	      wb_stb_fdc;
   wire [0:7] wb_dat_fdc;
   wire	      wb_ack_fdc;

   assign q = (q_select_fdc ? q_fdc : 8'hff) &
	      (q_select_ram32k ? q_ram32k : 8'hff);
   assign cruin = (cru_select_fdc ? cruin_fdc : 1'b0);
   assign ready = ready_fdc & ready_ram32k;

   always @(*) begin
      wb_dat_o <= 8'h00;
      wb_ack_o <= 1'b0;
      wb_stb_fdc <= 1'b0;
      case (wb_adr_i[0 +: 3])
	3'h0:
	  case (wb_adr_i[3 +: 4])
	    4'h0: begin
	       wb_stb_fdc <= wb_stb_i;
	       wb_dat_o <= wb_dat_fdc;
	       wb_ack_o <= wb_ack_fdc;
	    end
	    default: ;
	  endcase // case (wb_adr_i[3 +: 4])
	default: ;
      endcase // case (wb_adr_i[0 +: 3])
   end

   peb_ram32k ram32k(.clk(clk), .reset(reset),
		     .a(a), .d(d), .q(q_ram32k), .q_select(q_select_ram32k),
		     .memen(memen), .we(we), .ready(ready_ram32k));

   peb_fdc fdc(.clk(clk), .clk_3mhz_en(clk_3mhz_en), .reset(reset),
	       .a(a), .d(d), .q(q_fdc), .q_select(q_select_fdc),
	       .memen(memen), .we(we), .cruclk(cruclk), .cruin(cruin_fdc),
	       .cru_select(cru_select_fdc), .ready(ready_fdc), .led(),
	       .wb_adr_i(wb_adr_i[22 -: 14]), .wb_dat_i(wb_dat_i),
	       .wb_dat_o(wb_dat_fdc), .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
	       .wb_stb_i(wb_stb_fdc), .wb_ack_o(wb_ack_fdc),
	       .wb_cyc_i(wb_cyc_i));

endmodule // peb
