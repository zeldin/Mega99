module spmmio_iommu(input	  clk,
		    input	  reset,
		    input [0:9]	  adr,
		    input	  cs,
		    input [0:3]	  sel,
		    input	  we,
		    input [0:31]  d,
		    output [0:31] q,
		    output reg	  ack,
		    input	  cyc,
		    input	  dma_we,
		    input [0:9]	  virtpage,
		    output [2:20] physpage,
		    input	  virtstb,
		    output	  physstb,
		    output	  virtack,
		    input	  physack,
		    output	  validpage,
		    output [0:15] pattern);

   reg [0:31] descriptors [0:1023];
   reg [0:31] descriptor;
   reg	      descriptor_loaded;
   wire	      page_writable;

   assign q = descriptor;

   assign validpage = descriptor[1];
   assign physpage = descriptor[2:20];
   assign pattern = descriptor[16:31];
   assign page_writable = descriptor[31];

   assign physstb = cyc && virtstb && descriptor_loaded && validpage &&
		    (page_writable || !dma_we);
   assign virtack = cyc && virtstb && descriptor_loaded &&
		    (physack || !physstb);

   always @(posedge clk)
     if (reset) begin
	ack <= 1'b0;
	descriptor_loaded <= 1'b0;
     end else begin
	if ((cs && !we && !cyc) || (cyc && virtstb && !descriptor_loaded))
	  begin
	     descriptor <= descriptors[(cyc ? virtpage : adr)];
	     if (cyc)
	       descriptor_loaded <= 1'b1;
	  end
	if (virtack || !virtstb || !cyc)
	  descriptor_loaded <= 1'b0;
	if (cs && we && ack) begin
	   if (sel[0]) descriptors[adr][0:7] <= d[0:7];
	   if (sel[1]) descriptors[adr][8:15] <= d[8:15];
	   if (sel[2]) descriptors[adr][16:23] <= d[16:23];
	   if (sel[3]) descriptors[adr][24:31] <= d[24:31];
	end
	ack <= (!ack && cs && (we || !cyc));
   end

endmodule // spmmio_iommu
