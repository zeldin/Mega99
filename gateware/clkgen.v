module clkgen(input      ext_reset_in,
	      input	 clk,             // multiple of 10.738635 MHz
	      input	 cpu_turbo,
	      
	      output	 reset_out,
	      output	 vdp_clk_en,      // VDP pixel clock, 5.3693175 MHz
	      output	 vdp_clk_en_next,
	      output	 vga_clk_en,      // VGA pixel clock, 10.738635 MHz
	      output	 overlay_clk_en,  // Overlay pixel clock, 21.47727 MHz
	      output     sgc_clk_en,      // SGC clock, 3.579545 MHz
	      output reg cpu_clk_en,
	      output	 clk_3mhz_en,     // Peripheral clock, 3 MHz
	      output reg grom_clk_en,     // GROM clock, 447.443125 kHz
	      output reg vsp_clk_en       // VSP clock, 160 kHz
	      );

   // clk rate is this number times 10.738635 MHz
   parameter integer vdp_clk_multiplier = 1;
   // clk rate is this number times 3 MHz
   parameter integer cpu_clk_multiplier = 1;
   // clk rate is this number times 160 kHz
   parameter integer vsp_clk_multiplier = 1;
   // set to 1 to geneate overlay_clk_en
   parameter integer generate_overlay_clk_en = 0;

   localparam vdp_n = vdp_clk_multiplier * 2;
   localparam vga_n = vdp_clk_multiplier;
   localparam cpu_n = cpu_clk_multiplier;
   localparam sgc_n = vdp_clk_multiplier * 3;

   reg [0:4]     reset_cnt;
   reg	         init_done;
   reg [1:vdp_n] vdp_divisor;
   reg [1:vga_n] vga_divisor;
   reg [1:cpu_n] cpu_divisor;
   reg [1:sgc_n] sgc_divisor;
   reg [0:2]	 grom_cnt;
   reg [0:9]	 vsp_cnt;

   assign reset_out = ~reset_cnt[0];
   assign vdp_clk_en = vdp_divisor[1];
   assign vdp_clk_en_next = vdp_divisor[2];
   assign vga_clk_en = vga_divisor[1];
   assign clk_3mhz_en = cpu_divisor[1];
   assign sgc_clk_en = sgc_divisor[1];

   generate
      if (generate_overlay_clk_en)
	if (vdp_clk_multiplier % 2) begin
	   initial $fatal("vdp_clk_multiplier must be even for overlay");
	   assign overlay_clk_en = 1'b0;
	end else begin
	   localparam overlay_n = vdp_clk_multiplier / 2;
	   reg [1:overlay_n] overlay_divisor;
	   assign overlay_clk_en = overlay_divisor[1];
	   always @(posedge clk)
	     if (!init_done)
	       overlay_divisor <= { 1'b1, {overlay_n-1{1'b0}} };
	     else
	       overlay_divisor <= { overlay_divisor[2:overlay_n], overlay_divisor[1] };
	end
      else
	assign overlay_clk_en = 1'b0;
   endgenerate
   
   initial reset_cnt = 5'd0;
   initial init_done = 1'b0;

   always @(posedge clk)
     if (!init_done) begin
	vdp_divisor <= { 1'b1, {(vdp_n-1){1'b0}} };
	vga_divisor <= { 1'b1, {(vga_n-1){1'b0}} };
        cpu_divisor <= { 1'b1, {(cpu_n-1){1'b0}} };
        sgc_divisor <= { 1'b1, {(sgc_n-1){1'b0}} };
        cpu_clk_en <= 1'b1;
        grom_clk_en <= 1'b1;
        grom_cnt <= 3'b000;
        vsp_clk_en <= 1'b1;
        vsp_cnt <= 10'd0;
	reset_cnt <= 5'd0;
	init_done <= 1'b1;
     end else begin
	if (ext_reset_in)
	  reset_cnt <= 5'd0;
	else if (reset_out && clk_3mhz_en)
	  reset_cnt <= reset_cnt + 5'd1;

	if (cpu_turbo) begin
	   cpu_clk_en <= 1'b1;
	   grom_clk_en <= 1'b1;
	end else begin
	   cpu_clk_en <= cpu_divisor[2];
	   grom_clk_en <= sgc_divisor[2] && (grom_cnt == 3'b111);
	end
	if (sgc_divisor[2])
	  grom_cnt <= grom_cnt + 3'b001;
	vsp_clk_en <= 1'b0;
	if (vsp_cnt == (vsp_clk_multiplier - 1)) begin
	     vsp_clk_en <= 1'b1;
	     vsp_cnt <= 10'd0;
	  end else
	    vsp_cnt <= vsp_cnt + 10'd1;
	vdp_divisor <= { vdp_divisor[2:vdp_n], vdp_divisor[1] };
	vga_divisor <= { vga_divisor[2:vga_n], vga_divisor[1] };
	cpu_divisor <= { cpu_divisor[2:cpu_n], cpu_divisor[1] };
	sgc_divisor <= { sgc_divisor[2:sgc_n], sgc_divisor[1] };
     end

endmodule // clkgen
