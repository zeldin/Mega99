// Improved FIFO with no flapping BL

module tms5200_fifo(input       clk,
		    input	clk_en,
		    input [0:7]	df,
		    input	wbyt,
		    input	bytr,
		    input	clr,
		    input	shift,
		    output	fifdso,
		    output	be,
		    output	bl,
		    output	bf);

   wire [0:15] entry_inuse;
   
   genvar i;
   generate
      for (i=0; i<16; i=i+1) begin : ENTRY
	 reg [0:7]  data;
	 wire [0:7] prev_data;
	 reg	    inuse;
	 wire	    prev_inuse;
	 wire	    next_inuse;
	 assign entry_inuse[i] = inuse;
	 if (i == 0) begin
	    assign prev_data = df;
	    assign prev_inuse = wbyt;
	 end else begin
	    assign prev_data = ENTRY[i-1].data;
	    assign prev_inuse = ENTRY[i-1].inuse;
	    assign ENTRY[i-1].next_inuse = inuse;
	 end
	 if (i == 15) begin
	    assign fifdso = data[7];
	    assign next_inuse = !bytr;
	 end
	 always @(posedge clk)
	   if (clk_en) begin

	      if (bytr || (wbyt & !inuse))
		data <= (prev_inuse ? prev_data : df);
	      else if (i == 15 && shift)
		data <= { 1'b0, data[0:6] };

	      if (clr)
		inuse <= 1'b0;
	      else begin
		 if (wbyt && !bytr)
		   inuse <= next_inuse;
		 if (bytr && !wbyt)
		   inuse <= prev_inuse;
	      end
	   end
       end // block: ENTRY
   endgenerate

   assign be = !entry_inuse[15];
   assign bl = !entry_inuse[8];
   assign bf = entry_inuse[0];
   
endmodule // tms5200_fifo
