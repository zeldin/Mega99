module spmmio(input             clk,
	      input		reset,

	      input [0:23]	adr_i,
	      input		stb_i,
	      input		cyc_i,
	      input [0:3]	sel_i,
	      input		we_i,
	      input [0:31]	dat_i,
	      output reg	ack_o,
	      output reg [0:31]	dat_o,

	      output		led_red,
	      output		led_green);

   reg	       stb_misc;
   wire [0:31] dat_misc;

   always @(*) begin
      ack_o <= stb_i;
      dat_o <= 32'h00000000;

      stb_misc <= 1'b0;
      case (adr_i[0:7])
	8'h00: begin
	   stb_misc <= stb_i;
	   dat_o <= dat_misc;
	end
      endcase // case (adr_i[0:7])
   end

   spmmio_misc misc(.clk(clk), .reset(reset),
		    .adr(adr_i[20:23]), .cs(cyc_i && stb_misc),
		    .sel(sel_i), .we(we_i), .d(dat_i), .q(dat_misc),

		    .led_red(led_red), .led_green(led_green));

endmodule // spmmio
