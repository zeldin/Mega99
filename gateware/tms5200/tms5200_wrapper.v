module tms5200_wrapper(input        reset,
		       input	    clk, // Enabled cycles should give
		       input	    clk_en, // ROMCLK clock, 160 kHz

		       input [0:7]  dd,
		       output [0:7] dq,
		       input	    rs,
		       input	    ws,
		       output	    rdy,
		       output       int,
		   
		       output [0:(audio_bits-1)] audioout,

		       // ROM access wishbone slave
		       input [0:17] wb_adr_i,
		       input [0:7]  wb_dat_i,
		       output [0:7] wb_dat_o,
		       input	    wb_we_i,
		       input [0:0]  wb_sel_i,
		       input	    wb_stb_i,
		       output       wb_ack_o,
		       input	    wb_cyc_i);

   parameter audio_bits = 8;
   parameter vsm_size = 16384;

   wire	      t11, io;
   wire [0:3] add_out;
   wire	      add8_in;
   wire       m0, m1;

   tms5200_vsp vsp(.reset(reset), .clk(clk), .clk_en(clk_en),
		   .t11(t11), .io(io),
		   .dd(dd), .dq(dq), .rs(rs), .ws(ws), .rdy(rdy), .int(int),
		   .add_out(add_out), .add8_in(add8_in), .m0(m0), .m1(m1),
		   .promout());

   tms6100_vsm #(.vsm_size(vsm_size))
   vsm(.clk(clk), .clk_en(clk_en), .m0(m0), .m1(m1),
       .add8(add_out[0]), .add4(add_out[1]),
       .add2(add_out[2]), .add1(add_out[3]),
       .data_out(add8_in),
       .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
       .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i), .wb_stb_i(wb_stb_i),
       .wb_ack_o(wb_ack_o), .wb_cyc_i(wb_cyc_i));

   tms5200_dac #(.audio_bits(audio_bits))
   dac(.clk(clk), .clk_en(clk_en),
       .t11(t11), .io(io), .audioout(audioout));

endmodule // tms5200_wrapper

