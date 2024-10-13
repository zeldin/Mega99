## Clock signal (100MHz)
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]

create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK100MHZ]

create_generated_clock -name clk_sys [get_pins clkgen/mmcm_adv0/CLKOUT2]
create_generated_clock -name clk_pcm [get_pins clkgen/mmcm_adv1/CLKOUT0]

# General purpose LEDs on mother board
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports LED_R]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports LED_G]

# Reset button on the side of the machine(?) connected to main FPGA on R4, not via MAX10
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports RESET_BTN]

# C65 Keyboard
#
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports KB_IO0]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports KB_IO1]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports KB_IO2]
# Place Keyboard close to I/O pins
create_pblock pblock_kbd0
add_cells_to_pblock pblock_kbd0 [get_cells mk1com]
resize_pblock pblock_kbd0 -add {SLICE_X0Y225:SLICE_X15Y243}

# Joystick port A
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports FA_DOWN]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports FA_UP]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports FA_LEFT]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports FA_RIGHT]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports FA_FIRE]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports FA_DOWN_O]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports FA_UP_O]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports FA_LEFT_O]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports FA_RIGHT_O]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports FA_FIRE_O]

# Joystick port B
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports FB_DOWN]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports FB_UP]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports FB_LEFT]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports FB_RIGHT]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports FB_FIRE]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports FB_DOWN_O]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports FB_UP_O]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports FB_LEFT_O]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports FB_RIGHT_O]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports FB_FIRE_O]

##VGA Connector

set_property -dict {PACKAGE_PIN AA9 IOSTANDARD LVCMOS33} [get_ports VDAC_CLK]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports VDAC_SYNC_N]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports VDAC_BLANK_N]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports VDAC_PSAVE_N]

set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {VGA_R[0]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {VGA_R[1]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {VGA_R[2]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {VGA_R[3]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {VGA_R[4]}]
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports {VGA_R[5]}]
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS33} [get_ports {VGA_R[6]}]
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports {VGA_R[7]}]

set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[0]}]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[1]}]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS33} [get_ports {VGA_G[2]}]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS33} [get_ports {VGA_G[3]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS33} [get_ports {VGA_G[4]}]
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[5]}]
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS33} [get_ports {VGA_G[6]}]
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS33} [get_ports {VGA_G[7]}]

set_property -dict {PACKAGE_PIN W10 IOSTANDARD LVCMOS33} [get_ports {VGA_B[0]}]
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33} [get_ports {VGA_B[1]}]
set_property -dict {PACKAGE_PIN AB12 IOSTANDARD LVCMOS33} [get_ports {VGA_B[2]}]
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports {VGA_B[3]}]
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS33} [get_ports {VGA_B[4]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports {VGA_B[5]}]
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS33} [get_ports {VGA_B[6]}]
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS33} [get_ports {VGA_B[7]}]

set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS33} [get_ports VGA_HS]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports VGA_VS]

# HDMI output
############## HDMIOUT define##################
set_property PACKAGE_PIN Y1 [get_ports TXC_N]
set_property IOSTANDARD TMDS_33 [get_ports TXC_N]
set_property PACKAGE_PIN W1 [get_ports TXC_P]
set_property IOSTANDARD TMDS_33 [get_ports TXC_P]

set_property PACKAGE_PIN AB1 [get_ports {TX_N[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TX_N[0]}]
set_property PACKAGE_PIN AA1 [get_ports {TX_P[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TX_P[0]}]

set_property PACKAGE_PIN AB2 [get_ports {TX_N[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TX_N[1]}]
set_property PACKAGE_PIN AB3 [get_ports {TX_P[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TX_P[1]}]

set_property PACKAGE_PIN AB5 [get_ports {TX_N[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TX_N[2]}]
set_property PACKAGE_PIN AA5 [get_ports {TX_P[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TX_P[2]}]

set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS33} [get_ports SCL_A]
set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS33} [get_ports SDA_A]
set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS33} [get_ports LS_OE]

# HDMI buffer things
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports HPD_A]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports HIZ_EN]

# Audio DAC
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports AUDIO_LRCLK]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports AUDIO_SDATA]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports AUDIO_BCLK]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports AUDIO_MCLK]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports AUDIO_PDN]
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports AUDIO_SMUTE]
set_property -dict {PACKAGE_PIN L6 IOSTANDARD LVCMOS33} [get_ports AUDIO_SCL]
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports AUDIO_SDA]

## Hyper RAM
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports H_CLK]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[0]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[1]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[3]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[4]}]
set_property -dict {PACKAGE_PIN A19 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[5]}]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[6]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports {DQ[7]}]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS33 PULLUP FALSE SLEW FAST DRIVE 16} [get_ports RWDS]
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS33 PULLUP FALSE} [get_ports H_RES]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS33 PULLUP FALSE} [get_ports CS0]
# Place HyperRAM close to I/O pins
create_pblock pblock_hyperram
add_cells_to_pblock pblock_hyperram [get_cells hr_wrapper/hr]
resize_pblock pblock_hyperram -add {SLICE_X0Y186:SLICE_X35Y224}
resize_pblock pblock_hyperram -add {SLICE_X8Y175:SLICE_X23Y186}

set tPCB    0.1  ; # assume 15mm @ 150mm/ns VoP, and that trace lengths are matched

# 100MHz HyperRAM timings
set tCKDmax  5.5  ; # clock to data valid, max
set tCKDImin 0.0  ; # clock to data invalid, min

set hyperram_inputs {DQ[*] RWDS}

# read timing
set_input_delay  -max [expr $tPCB+$tCKDmax]  -reference_pin [get_ports H_CLK] [get_ports $hyperram_inputs]
set_input_delay  -min [expr $tPCB+$tCKDImin] -reference_pin [get_ports H_CLK] [get_ports $hyperram_inputs]


##USB-RS232 Interface
#
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports UART_TXD]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports UART_RXD]


##Micro SD Connector (x2 on r2 PCB)
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports SD1_CD]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports SD1_SCK]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports SD1_CMD]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports SD1_DAT[0]]
set_property -dict {PACKAGE_PIN H3 IOSTANDARD LVCMOS33} [get_ports SD1_DAT[1]]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports SD1_DAT[2]]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports SD1_DAT[3]]
# set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports SD2_CD]
# set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports SD2_WP]
# set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports SD2_SCK]
# set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports SD2_CMD]
# set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports SD2_DAT[0]]
# set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports SD2_DAT[1]]
# set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports SD2_DAT[2]]
# set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports SD2_DAT[3]]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]


set_max_delay 10.0 -datapath_only -from [get_clocks clk_sys] -to [get_clocks clk_pcm]
set_max_delay 2.0 -datapath_only -from [get_cells audio_encoder/cnt_reg[7]] -to [get_cells audio_encoder/lrclk_cdc_reg[0]]
