
MOR1KXPATH = mor1kx/rtl/verilog

COMMON_SOURCES  = mainboard.v
COMMON_SOURCES += clkgen.v
COMMON_SOURCES += address_decoder.v
COMMON_SOURCES += multiplexer.v
COMMON_SOURCES += keymatrix.v
COMMON_SOURCES += groms.v
COMMON_SOURCES += cartridge_rom.v
COMMON_SOURCES += console_rom.v
COMMON_SOURCES += scratchpad_ram.v

COMMON_SOURCES += tms9900/tms9900_cpu.v
COMMON_SOURCES += tms9900/tms9901_psi.v
COMMON_SOURCES += tms9918/tms9918_vdp.v
COMMON_SOURCES += tms9918/tms9918_scandoubler.v
COMMON_SOURCES += tms9918/tms9918_color_to_rgb.v
COMMON_SOURCES += tms9918/tms9918_vdpram.v
COMMON_SOURCES += tms9918/tms9918_cpuifc.v
COMMON_SOURCES += tms9918/tms9918_wrapper.v
COMMON_SOURCES += tms9919/tms9919_sgc.v

COMMON_SOURCES += sp.v
COMMON_SOURCES += spmem.v
COMMON_SOURCES += spmmio.v
COMMON_SOURCES += spmmio_misc.v
COMMON_SOURCES += spmmio_sdcard.v
COMMON_SOURCES += spmmio_uart.v

MOR1KX_SOURCES  = $(MOR1KXPATH)/mor1kx-defines.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx-sprs.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_utils.vh
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_branch_predictor_gshare.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_branch_predictor_simple.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_branch_predictor_saturation_counter.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_branch_prediction.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_bus_if_wb32.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_cache_lru.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_cfgrs.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_cpu_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_cpu.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_ctrl_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_dcache.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_decode_execute_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_decode.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_execute_alu.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_execute_ctrl_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_fetch_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_icache.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_lsu_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_pcu.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_pic.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_rf_cappuccino.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_simple_dpram_sclk.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_store_buffer.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_ticktimer.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx.v
MOR1KX_SOURCES += $(MOR1KXPATH)/mor1kx_wb_mux_cappuccino.v

BOOTHEX  = or1k_boot_code0.hex
BOOTHEX += or1k_boot_code1.hex
BOOTHEX += or1k_boot_code2.hex
BOOTHEX += or1k_boot_code3.hex

NEXYS_A7_SOURCES  = mega99_top_a7.v
NEXYS_A7_SOURCES += clkwiz_a7.v
NEXYS_A7_SOURCES += mig_wrapper_nexys.v
NEXYS_A7_SOURCES += cdc_flag.v
NEXYS_A7_SOURCES += ps2com.v
NEXYS_A7_SOURCES += keyboard_ps2.v
NEXYS_A7_SOURCES += sigmadelta.v

NEXYS_A7_SOURCES += vivado/mega99_nexys_a7.xdc
NEXYS_A7_SOURCES += vivado/mig_a.prj


VIVADO ?= ./vivado_wrapper

nexys_a7-50t: proj/mega99_nexys_a7-50t.runs/impl_1/mega99_top_a7.bit

nexys_a7-100t: proj/mega99_nexys_a7-100t.runs/impl_1/mega99_top_a7.bit


proj/mega99_nexys_a7%.runs/impl_1/mega99_top_a7.bit : proj/mega99_nexys_a7%.xpr vivado/build.tcl $(COMMON_SOURCES) $(MOR1KX_SOURCES) $(NEXYS_A7_SOURCES) $(BOOTHEX)
	$(VIVADO) -mode batch -source vivado/build.tcl proj/mega99_nexys_a7$*.xpr

proj/mega99_nexys_a7-50t.xpr : vivado/mega99_nexys_a7.tcl | $(BOOTHEX)
	@rm -rf proj/mega99_nexys_a7-50t.*
	$(VIVADO) -mode batch -source vivado/mega99_nexys_a7.tcl -tclargs --project_name mega99_nexys_a7-50t --part xc7a50ticsg324-1L

proj/mega99_nexys_a7-100t.xpr : vivado/mega99_nexys_a7.tcl | $(BOOTHEX)
	@rm -rf proj/mega99_nexys_a7-100t.*
	$(VIVADO) -mode batch -source vivado/mega99_nexys_a7.tcl -tclargs --project_name mega99_nexys_a7-100t --part xc7a100tcsg324-1



SP_OBJCOPY_BIN = or1k-elf-objcopy -O binary
SP_CC = or1k-elf-gcc
SP_CFLAGS = -std=c23 -ffunction-sections -fdata-sections \
	-mcmov -msext -msfimm -mshftimm -funsigned-char \
	-ffreestanding -finline-stringops \
	-I spsrc/common -DTICKS_PER_SEC=53693175u

SP_BOOT_CFLAGS = $(SP_CFLAGS) -Os -fno-move-loop-invariants
SP_BOOT_LDSCRIPT = spsrc/boot/main.lds
SP_BOOT_LDFLAGS = -nostartfiles -nodefaultlibs -Wl,--no-warn-rwx-segments \
	-Wl,--defsym,__stack=0x2000,-T,$(SP_BOOT_LDSCRIPT),--gc-sections,-eboot

SP_BOOT_SRCS  = boot/entry.S
SP_BOOT_SRCS += boot/main.c
SP_BOOT_SRCS += common/display.c
SP_BOOT_SRCS += common/uart.c
SP_BOOT_SRCS += common/sdcard.c
SP_BOOT_SRCS += common/fatfs.c

SP_MAIN_CFLAGS = $(SP_CFLAGS) -O2
SP_MAIN_LDFLAGS = -nostartfiles -nodefaultlibs \
	-Wl,-Ttext=0x40000000,--gc-sections,-estart

SP_MAIN_SRCS  = main/entry.S
SP_MAIN_SRCS += main/main.c
SP_MAIN_SRCS += common/display.c
SP_MAIN_SRCS += common/uart.c
SP_MAIN_SRCS += common/sdcard.c
SP_MAIN_SRCS += common/fatfs.c

SP_BOOT_BUILD = build/spboot
SP_MAIN_BUILD = build/spmain

SP_BOOT_OBJS = $(addprefix $(SP_BOOT_BUILD)/,$(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SP_BOOT_SRCS))))
SP_MAIN_OBJS = $(addprefix $(SP_MAIN_BUILD)/,$(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SP_MAIN_SRCS))))

PYTHON = python

.DELETE_ON_ERROR:

or1k_boot_code0.hex : $(SP_BOOT_BUILD)/or1k_boot_code.bin
	$(PYTHON) genhex.py -o or1k_boot_code.hex -n 4 $<

or1k_boot_code1.hex or1k_boot_code2.hex or1k_boot_code3.hex : or1k_boot_code0.hex

$(SP_BOOT_BUILD)/or1k_boot_code.bin : $(SP_BOOT_BUILD)/or1k_boot_code.elf
	$(SP_OBJCOPY_BIN) $< $@

$(SP_BOOT_BUILD)/or1k_boot_code.elf : $(SP_BOOT_OBJS) $(SP_BOOT_LDSCRIPT)
	$(SP_CC) $(SP_BOOT_CFLAGS) $(SP_BOOT_LDFLAGS) -o $@ $(SP_BOOT_OBJS)

$(SP_BOOT_BUILD)/%.o : spsrc/%.S
	@mkdir -p $(@D)
	$(SP_CC) $(SP_BOOT_CFLAGS) -MMD -c -o $@ $<

$(SP_BOOT_BUILD)/%.o : spsrc/%.c
	@mkdir -p $(@D)
	$(SP_CC) $(SP_BOOT_CFLAGS) -MMD -c -o $@ $<

mega99sp.bin : $(SP_MAIN_BUILD)/mega99sp.elf
	$(SP_OBJCOPY_BIN) $< $@

$(SP_MAIN_BUILD)/mega99sp.elf : $(SP_MAIN_OBJS)
	$(SP_CC) $(SP_MAIN_CFLAGS) $(SP_MAIN_LDFLAGS) -o $@ $(SP_MAIN_OBJS)

$(SP_MAIN_BUILD)/%.o : spsrc/%.S
	@mkdir -p $(@D)
	$(SP_CC) $(SP_MAIN_CFLAGS) -MMD -c -o $@ $<

$(SP_MAIN_BUILD)/%.o : spsrc/%.c
	@mkdir -p $(@D)
	$(SP_CC) $(SP_MAIN_CFLAGS) -MMD -c -o $@ $<

-include $(SP_BOOT_OBJS:.o=.d)
-include $(SP_MAIN_OBJS:.o=.d)
