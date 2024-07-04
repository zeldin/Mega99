module tms5200_crom(input        clk,
		    input	 clk_en,
		    input [8:0]	 addr,
		    input	 addr_en,
		    output [7:0] out);

   reg [5:0] clamped_addr;
   reg [7:0] data [0:51];
   reg [7:0] compl_data;
   reg	     data_en;
   
   assign out = ~compl_data;

   initial $readmemh("tms5200_chirp_rom.hex", data);
   
   always @(posedge clk)
     if (clk_en) begin

	if (addr_en) begin
	   clamped_addr <= ( addr <= 9'd51 ? addr[5:0] : 9'd51 );
	   data_en <= 1'b1;
	end else
	  data_en <= 1'b0;
	if (data_en)
	  compl_data <= data[clamped_addr];
     end

endmodule // tms5200_crom
