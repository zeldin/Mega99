module spmem(input         clk,
	     input	   reset,

	     input [1:31]  sp_i_adr,
	     input	   sp_i_stb,
	     input	   sp_i_cyc,
	     input [0:3]   sp_i_sel,
	     input	   sp_i_we,
	     input [0:2]   sp_i_cti,
	     input [0:1]   sp_i_bte,
	     input [0:31]  sp_i_dato,
	     output 	   sp_i_ack,
	     output [0:31] sp_i_dati,

	     input [1:31]  sp_d_adr,
	     input	   sp_d_stb,
	     input	   sp_d_cyc,
	     input [0:3]   sp_d_sel,
	     input	   sp_d_we,
	     input [0:2]   sp_d_cti,
	     input [0:1]   sp_d_bte,
	     input [0:31]  sp_d_dato,
	     output 	   sp_d_ack,
	     output [0:31] sp_d_dati,

	     output [2:31] xmem_adr_o,
	     output	   xmem_stb_o,
	     output	   xmem_cyc_o,
	     output [0:3]  xmem_sel_o,
	     output	   xmem_we_o,
	     output [0:31] xmem_dat_o,
	     input	   xmem_ack_i,
	     input [0:31]  xmem_dat_i);

   parameter boot_mem_init_file = "";

   wire xmem_i_access;
   wire xmem_d_access;
   reg	xmem_d_in_progress;

   reg [0:7]   boot_mem0[0:2047];
   reg [0:7]   boot_mem1[0:2047];
   reg [0:7]   boot_mem2[0:2047];
   reg [0:7]   boot_mem3[0:2047];
   reg [0:31]  boot_mem_data;
   reg	       boot_mem_i_ack;
   reg	       boot_mem_d_ack;
   wire	       boot_mem_i_access;
   wire	       boot_mem_d_access;

   assign xmem_i_access = (!reset && sp_i_cyc && sp_i_stb && !sp_i_we &&
			   sp_i_adr[1] == 1'b1 && !xmem_d_in_progress);
   assign xmem_d_access = (!reset && sp_d_cyc && sp_d_stb &&
			   sp_d_adr[1] == 1'b1);

   assign sp_i_ack = (xmem_i_access ? xmem_ack_i : boot_mem_i_ack);
   assign sp_d_ack = (xmem_d_access && !xmem_i_access ? xmem_ack_i : boot_mem_d_ack);

   assign xmem_adr_o = { (xmem_i_access ? sp_i_adr[2:29] : sp_d_adr[2:29]), 2'b00 };
   assign xmem_stb_o = xmem_i_access || xmem_d_access;
   assign xmem_cyc_o = xmem_i_access || xmem_d_access;
   assign xmem_sel_o = sp_d_sel;
   assign xmem_we_o = sp_d_we && !xmem_i_access;
   assign xmem_dat_o = sp_d_dato;

   assign boot_mem_i_access = (!reset && !boot_mem_i_ack &&
			       sp_i_cyc && sp_i_stb && !sp_i_we &&
			       sp_i_adr[1] == 1'b0);
   assign boot_mem_d_access = (!reset && !boot_mem_d_ack &&
			       sp_d_cyc && sp_d_stb && !sp_d_we &&
			       sp_d_adr[1] == 1'b0);
   assign sp_i_dati = (sp_i_adr[1] ? xmem_dat_i : boot_mem_data);
   assign sp_d_dati = (sp_d_adr[1] ? xmem_dat_i : boot_mem_data);

   initial $readmemh({boot_mem_init_file, "0.hex"}, boot_mem0);
   initial $readmemh({boot_mem_init_file, "1.hex"}, boot_mem1);
   initial $readmemh({boot_mem_init_file, "2.hex"}, boot_mem2);
   initial $readmemh({boot_mem_init_file, "3.hex"}, boot_mem3);

   always @(posedge clk) begin

      if (xmem_d_access && !xmem_i_access)
	xmem_d_in_progress <= 1'b1;
      if (reset || xmem_ack_i)
	xmem_d_in_progress <= 1'b0;

      if (boot_mem_i_access || boot_mem_d_access)
	boot_mem_data <= {
          boot_mem0[boot_mem_i_access ? sp_i_adr[19:29] : sp_d_adr[19:29]],
          boot_mem1[boot_mem_i_access ? sp_i_adr[19:29] : sp_d_adr[19:29]],
          boot_mem2[boot_mem_i_access ? sp_i_adr[19:29] : sp_d_adr[19:29]],
          boot_mem3[boot_mem_i_access ? sp_i_adr[19:29] : sp_d_adr[19:29]]
	};

      if (reset || boot_mem_i_ack)
	boot_mem_i_ack <= 1'b0;
      else if (sp_i_adr[1] == 1'b0) begin
	 if (sp_i_cyc && sp_i_stb)
	   boot_mem_i_ack <= 1'b1;
      end

      if (reset || boot_mem_d_ack)
	 boot_mem_d_ack <= 1'b0;
      else if (sp_d_adr[1] == 1'b0) begin
	 if (sp_d_cyc && sp_d_stb &&
	     (sp_d_we || !boot_mem_i_access)) begin
	    if (sp_d_we) begin
	       if (sp_d_sel[0])
		 boot_mem0[sp_d_adr[19:29]] <= sp_d_dato[0:7];
	       if (sp_d_sel[1])
		 boot_mem1[sp_d_adr[19:29]] <= sp_d_dato[8:15];
	       if (sp_d_sel[2])
		 boot_mem2[sp_d_adr[19:29]] <= sp_d_dato[16:23];
	       if (sp_d_sel[3])
		 boot_mem3[sp_d_adr[19:29]] <= sp_d_dato[24:31];
	    end
	    boot_mem_d_ack <= 1'b1;
	 end
      end

   end // always @ (posedge clk)

endmodule // spmem
