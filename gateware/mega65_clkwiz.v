module mega65_clkwiz(output clk_sys,        /* 107.38635 MHz */
		     output clk_sys_phi90,  /* as above but 90° phase delay */
		     output clk_hdmi,       /* 21.47727 MHz */
		     output clk_hdmi_x10,   /* 214.7727 MHz */
		     output clk_pcm,        /* 12.288 MHz */
		     output locked,
		     output locked_pcm,
		     input  clk_in1);

   wire b_clk_in1;
   wire	clk_fb;
   wire	u_clk_sys;
   wire	u_clk_sys_phi90;
   wire	u_clk_hdmi;
   wire	u_clk_hdmi_x10;
   wire	u_clk_pcm;
   wire	clk_fb_pcm;

   IBUF ibuf_clk_in1(.I(clk_in1), .O(b_clk_in1));


   /* 100 MHz -> 107.38635 MHz */

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
       .CLKOUT2_DIVIDE       (55),
       .CLKOUT2_PHASE        (0.000),
       .CLKOUT2_DUTY_CYCLE   (0.500),
       .CLKOUT2_USE_FINE_PS  ("FALSE"),
       .CLKOUT3_DIVIDE       (11),
       .CLKOUT3_PHASE        (135.000), /* 135 gives more slack than 90 */
       .CLKOUT3_DUTY_CYCLE   (0.500),
       .CLKOUT3_USE_FINE_PS  ("FALSE"),
       .CLKIN1_PERIOD        (10.000))
   mmcm_adv0
     (.CLKFBOUT            (clk_fb),
      .CLKFBOUTB           (),
      .CLKOUT0             (u_clk_hdmi_x10),
      .CLKOUT0B            (),
      .CLKOUT1             (u_clk_sys),
      .CLKOUT1B            (),
      .CLKOUT2             (u_clk_hdmi),
      .CLKOUT2B            (),
      .CLKOUT3             (u_clk_sys_phi90),
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


  /* 100 MHz -> 12.288 MHz */

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (5),
    .CLKFBOUT_MULT_F      (48.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (78.125),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (10.000))
  mmcm_adv1
   (
    .CLKFBOUT            (clk_fb_pcm),
    .CLKFBOUTB           (),
    .CLKOUT0             (u_clk_pcm),
    .CLKOUT0B            (),
    .CLKOUT1             (),
    .CLKOUT1B            (),
    .CLKOUT2             (),
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (),
    .CLKOUT5             (),
    .CLKOUT6             (),
    .CLKFBIN             (clk_fb_pcm),
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
    .LOCKED              (locked_pcm),
    .CLKINSTOPPED        (),
    .CLKFBSTOPPED        (),
    .PWRDWN              (1'b0),
    .RST                 (1'b0));


   BUFG bufg_clk_sys(.I(u_clk_sys), .O(clk_sys));
   BUFG bufg_clk_sys_phi90(.I(u_clk_sys_phi90), .O(clk_sys_phi90));
   BUFG bufg_clk_hdmi(.I(u_clk_hdmi), .O(clk_hdmi));
   BUFG bufg_clk_hdmi_x10(.I(u_clk_hdmi_x10), .O(clk_hdmi_x10));
   BUFG bufg_clk_pcm(.I(u_clk_pcm), .O(clk_pcm));

endmodule // mega65_clkwiz
