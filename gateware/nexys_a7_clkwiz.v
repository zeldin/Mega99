module nexys_a7_clkwiz(output clk_mem,
		       output clk_sys,
		       output clk_ref,
		       output locked,
		       input  clk_in1);

   wire b_clk_in1;
   wire	clk_fb;
   wire	u_clk_mem;
   wire	u_clk_sys;
   wire	u_clk_ref;
   wire	u_clk_fb_pll;
   wire	b_clk_fb_pll;

   IBUF ibuf_clk_in1(.I(clk_in1), .O(b_clk_in1));

   MMCME2_ADV
     #(.BANDWIDTH            ("OPTIMIZED"),
       .CLKOUT4_CASCADE      ("FALSE"),
       .COMPENSATION         ("ZHOLD"),
       .STARTUP_WAIT         ("FALSE"),
       .DIVCLK_DIVIDE        (2),
       .CLKFBOUT_MULT_F      (23.625),
       .CLKFBOUT_PHASE       (0.000),
       .CLKFBOUT_USE_FINE_PS ("FALSE"),
       .CLKOUT0_DIVIDE_F     (5.500),
       .CLKOUT0_PHASE        (0.000),
       .CLKOUT0_DUTY_CYCLE   (0.500),
       .CLKOUT0_USE_FINE_PS  ("FALSE"),
       .CLKOUT1_DIVIDE       (11),
       .CLKOUT1_PHASE        (0.000),
       .CLKOUT1_DUTY_CYCLE   (0.500),
       .CLKOUT1_USE_FINE_PS  ("FALSE"),
       .CLKIN1_PERIOD        (10.000))
   mmcm_adv0
     (.CLKFBOUT            (clk_fb),
      .CLKFBOUTB           (),
      .CLKOUT0             (u_clk_mem),
      .CLKOUT0B            (),
      .CLKOUT1             (u_clk_sys),
      .CLKOUT1B            (),
      .CLKOUT2             (),
      .CLKOUT2B            (),
      .CLKOUT3             (),
      .CLKOUT3B            (),
      .CLKOUT4             (),
      .CLKOUT5             (),
      .CLKOUT6             (),
      .CLKFBIN             (clk_fb),
      .CLKIN1              (b_clk_in1),
      .CLKIN2              (1'b0),
      .CLKINSEL            (1'b1),
      .DADDR               (7'h0),
      .DCLK                (1'b0),
      .DEN                 (1'b0),
      .DI                  (16'h0),
      .DO                  (),
      .DRDY                (),
      .DWE                 (1'b0),
      .PSCLK               (1'b0),
      .PSEN                (1'b0),
      .PSINCDEC            (1'b0),
      .PSDONE              (),
      .LOCKED              (locked),
      .CLKINSTOPPED        (),
      .CLKFBSTOPPED        (),
      .PWRDWN              (1'b0),
      .RST                 (1'b0));

   PLLE2_ADV
     #(.BANDWIDTH            ("OPTIMIZED"),
       .COMPENSATION         ("ZHOLD"),
       .STARTUP_WAIT         ("FALSE"),
       .DIVCLK_DIVIDE        (1),
       .CLKFBOUT_MULT        (10),
       .CLKFBOUT_PHASE       (0.000),
       .CLKOUT0_DIVIDE       (5),
       .CLKOUT0_PHASE        (0.000),
       .CLKOUT0_DUTY_CYCLE   (0.500),
       .CLKIN1_PERIOD        (10.000))
   plle2_adv0
     (.CLKFBOUT            (u_clk_fb_pll),
      .CLKOUT0             (u_clk_ref),
      .CLKOUT1             (),
      .CLKOUT2             (),
      .CLKOUT3             (),
      .CLKOUT4             (),
      .CLKOUT5             (),
      .CLKFBIN             (b_clk_fb_pll),
      .CLKIN1              (b_clk_in1),
      .CLKIN2              (1'b0),
      .CLKINSEL            (1'b1),
      .DADDR               (7'h0),
      .DCLK                (1'b0),
      .DEN                 (1'b0),
      .DI                  (16'h0),
      .DO                  (),
      .DRDY                (),
      .DWE                 (1'b0),
      .LOCKED              (),
      .PWRDWN              (1'b0),
      .RST                 (1'b0));

   BUFG bufg_clkf(.I(u_clk_fb_pll), .O(b_clk_fb_pll));

   BUFG bufg_clk_mem(.I(u_clk_mem), .O(clk_mem));
   BUFG bufg_clk_sys(.I(u_clk_sys), .O(clk_sys));
   BUFG bufg_clk_ref(.I(u_clk_ref), .O(clk_ref));

endmodule // nexys_a7_clkwiz
