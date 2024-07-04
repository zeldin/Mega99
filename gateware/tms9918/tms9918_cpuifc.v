module tms9918_cpuifc(input reset,
		      input clk,

		      // To CPU
		      input [0:7]	cd,
		      output [0:7]	cq,
		      input		csr,
		      input		csw,
		      input		mode,
		      
		      // To VDP
		      output [0:2]	reg_addr,
		      output [0:7]	reg_wdata,
		      output		reg_wstrobe,
		      input [0:7]	reg_rdata,
		      output reg	reg_rstrobe,
		      
		      // To VDPRAM
		      output reg	vdp_read,
		      output		vdp_write,
		      output reg [0:13]	vdp_addr,
		      output [0:7]	vdp_wdata,
		      input [0:7]	vdp_rdata,
		      input		vdp_read_ready);

   reg [0:7]  read_ahead;
   reg	      first_byte_flag;
   reg	      vdp_read_complete;

   assign cq = (mode ? reg_rdata : read_ahead);
   assign reg_addr = cd[5:7];
   assign reg_wdata = vdp_addr[6:13];
   assign reg_wstrobe = (csw && mode && first_byte_flag && cd[0:1] == 2'b10);
   assign vdp_write = (csw && !mode);
   assign vdp_wdata = cd;
     
   always @(posedge clk)
     if (reset) begin
	reg_rstrobe <= 1'b0;
	vdp_read <= 1'b0;
	vdp_addr <= 14'h0000;
	read_ahead <= 8'h00;
	first_byte_flag <= 1'b0;
	vdp_read_complete <= 1'b0;
     end else begin

	// Autoincrement on write or read completion
	if (vdp_write)
	   vdp_addr <= vdp_addr + 14'd1;
	if (vdp_read_complete) begin
	   read_ahead <= vdp_rdata;
	   vdp_addr <= vdp_addr + 14'd1;
	end   

	vdp_read_complete <= 1'b0;
	if (vdp_read && vdp_read_ready) begin
	   vdp_read <= 1'b0;
	   vdp_read_complete <= 1'b1;
	end

	// Read operations
	reg_rstrobe <= 1'b0;
 	if (csr) begin
	   first_byte_flag <= 1'b0;
	   if (mode)
	     // Assert rstrobe on the cycle following csr, since that is when
	     // reg_rdata is actually consumed
	     reg_rstrobe <= 1'b1;
	   else
	     // Trigger next read ahead
	     vdp_read <= 1'b1;
	end

	// Write operations
	if (csw) begin
	   if (!mode)
	     first_byte_flag <= 1'b0;
	   else if (!first_byte_flag) begin
	      vdp_addr[6:13] <= cd;
	      first_byte_flag <= 1'b1;
	   end else begin
	      vdp_addr[0:5] <= cd[2:7];
	      if (cd[0:1] == 2'b00)
		// First read ahead
		vdp_read <= 1'b1;
	      first_byte_flag <= 1'b0;
	   end
	end

     end // else: !if(reset)

endmodule // tms9918_cpuifc
