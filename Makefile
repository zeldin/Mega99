
MOR1KXPATH = mor1kx/rtl/verilog

GATEWARE = gateware

COMMON_SOURCES  = $(GATEWARE)/mainboard.v
COMMON_SOURCES += $(GATEWARE)/clkgen.v
COMMON_SOURCES += $(GATEWARE)/address_decoder.v
COMMON_SOURCES += $(GATEWARE)/multiplexer.v
COMMON_SOURCES += $(GATEWARE)/keymatrix.v
COMMON_SOURCES += $(GATEWARE)/groms.v
COMMON_SOURCES += $(GATEWARE)/cartridge_rom.v
COMMON_SOURCES += $(GATEWARE)/console_rom.v
COMMON_SOURCES += $(GATEWARE)/scratchpad_ram.v
COMMON_SOURCES += $(GATEWARE)/peb.v
COMMON_SOURCES += $(GATEWARE)/peb_ram32k.v
COMMON_SOURCES += $(GATEWARE)/peb_fdc.v

COMMON_SOURCES += $(GATEWARE)/tms9900/tms9900_cpu.v
COMMON_SOURCES += $(GATEWARE)/tms9900/tms9901_psi.v
COMMON_SOURCES += $(GATEWARE)/tms9918/tms9918_vdp.v
COMMON_SOURCES += $(GATEWARE)/tms9918/tms9918_scandoubler.v
COMMON_SOURCES += $(GATEWARE)/tms9918/tms9918_color_to_rgb.v
COMMON_SOURCES += $(GATEWARE)/tms9918/tms9918_vdpram.v
COMMON_SOURCES += $(GATEWARE)/tms9918/tms9918_cpuifc.v
COMMON_SOURCES += $(GATEWARE)/tms9918/tms9918_wrapper.v
COMMON_SOURCES += $(GATEWARE)/tms9919/tms9919_sgc.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_bstack.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_chirp_rom.hex
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_crom.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_dac.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_fifo.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_kstack.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_multiplier.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_parameter_rom.hex
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_pram.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_prom.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_vsp.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms5200_wrapper.v
COMMON_SOURCES += $(GATEWARE)/tms5200/tms6100_vsm.v
COMMON_SOURCES += $(GATEWARE)/fdc1771/fdc1771.v
COMMON_SOURCES += $(GATEWARE)/fdc1771/fdc1771_mockdrive.v

COMMON_SOURCES += $(GATEWARE)/sp.v
COMMON_SOURCES += $(GATEWARE)/spmem.v
COMMON_SOURCES += $(GATEWARE)/spmmio.v
COMMON_SOURCES += $(GATEWARE)/spmmio_misc.v
COMMON_SOURCES += $(GATEWARE)/spmmio_sdcard.v
COMMON_SOURCES += $(GATEWARE)/spmmio_uart.v
COMMON_SOURCES += $(GATEWARE)/spmmio_overlay.v
COMMON_SOURCES += $(GATEWARE)/spmmio_keyboard.v
COMMON_SOURCES += $(GATEWARE)/spmmio_tape.v
COMMON_SOURCES += $(GATEWARE)/icap_wrapper.v
COMMON_SOURCES += $(GATEWARE)/qspi_controller.v

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

BOOTHEX  = or1k_boot_code.hex

MEGA65R6_SOURCES  = $(GATEWARE)/mega99_mega65r6_top.v
MEGA65R6_SOURCES += $(GATEWARE)/mega65_clkwiz.v
MEGA65R6_SOURCES += $(GATEWARE)/hyperram_wrapper.v
MEGA65R6_SOURCES += $(GATEWARE)/hyperram.v
MEGA65R6_SOURCES += $(GATEWARE)/artix7_hyperphy.v
MEGA65R6_SOURCES += $(GATEWARE)/keyboard_mk1.v
MEGA65R6_SOURCES += $(GATEWARE)/kbdmk1com.v
MEGA65R6_SOURCES += $(GATEWARE)/ak4432_audio.v
MEGA65R6_SOURCES += $(GATEWARE)/tmds_10to1ddr.v
MEGA65R6_SOURCES += $(GATEWARE)/hdmi/vga_to_hdmi.vhdl
MEGA65R6_SOURCES += $(GATEWARE)/hdmi/hdmi_tx_encoder.vhdl
MEGA65R6_SOURCES += $(GATEWARE)/hdmi/types_pkg.vhdl

MEGA65R6_SOURCES += vivado/mega99_mega65r6.xdc


MEGA65R3_SOURCES  = $(GATEWARE)/mega99_mega65r3_top.v
MEGA65R3_SOURCES += $(GATEWARE)/mega65_clkwiz.v
MEGA65R3_SOURCES += $(GATEWARE)/hyperram_wrapper.v
MEGA65R3_SOURCES += $(GATEWARE)/hyperram.v
MEGA65R3_SOURCES += $(GATEWARE)/artix7_hyperphy.v
MEGA65R3_SOURCES += $(GATEWARE)/keyboard_mk1.v
MEGA65R3_SOURCES += $(GATEWARE)/kbdmk1com.v
MEGA65R3_SOURCES += $(GATEWARE)/max10_reset_button.v
MEGA65R3_SOURCES += $(GATEWARE)/ak4432_audio.v
MEGA65R3_SOURCES += $(GATEWARE)/sigmadelta.v
MEGA65R3_SOURCES += $(GATEWARE)/tmds_10to1ddr.v
MEGA65R3_SOURCES += $(GATEWARE)/hdmi/vga_to_hdmi.vhdl
MEGA65R3_SOURCES += $(GATEWARE)/hdmi/hdmi_tx_encoder.vhdl
MEGA65R3_SOURCES += $(GATEWARE)/hdmi/types_pkg.vhdl

MEGA65R3_SOURCES += vivado/mega99_mega65r3.xdc


NEXYS_A7_SOURCES  = $(GATEWARE)/mega99_nexys_a7_top.v
NEXYS_A7_SOURCES += $(GATEWARE)/nexys_a7_clkwiz.v
NEXYS_A7_SOURCES += $(GATEWARE)/nexys_a7_mig_wrapper.v
NEXYS_A7_SOURCES += $(GATEWARE)/cdc_flag.v
NEXYS_A7_SOURCES += $(GATEWARE)/ps2com.v
NEXYS_A7_SOURCES += $(GATEWARE)/keyboard_ps2.v
NEXYS_A7_SOURCES += $(GATEWARE)/sigmadelta.v

NEXYS_A7_SOURCES += vivado/mega99_nexys_a7.xdc
NEXYS_A7_SOURCES += vivado/nexys_a7_mig.prj


VIVADO ?= ./vivado_wrapper

CORETOOL ?= coretool

CORE_VERSION = 1.5

EMBEDDED_FILES = mega99sp.bin

default : mega99sp.bin mega65r6

all : mega99sp.bin mega65r6 mega65r3 nexys_a7-50t nexys_a7-100t

mega65r6: mega99_r6.cor

mega65r3: mega99_r3.cor

nexys_a7-50t: proj/mega99_nexys_a7-50t.runs/impl_1/mega99_nexys_a7_top.bit

nexys_a7-100t: proj/mega99_nexys_a7-100t.runs/impl_1/mega99_nexys_a7_top.bit


%.keep_wbstar.bit : %.bit
	$(PYTHON) fix_bitstream.py $< $@

mega99_r6.cor : proj/mega99_mega65r6.runs/impl_1/mega99_mega65r6_top.keep_wbstar.bit $(EMBEDDED_FILES)
	$(CORETOOL) -B $@ -F -t mega65r6 -b $< -n Mega99 -v $(CORE_VERSION) --add-files $(EMBEDDED_FILES)

mega99_r3.cor : proj/mega99_mega65r3.runs/impl_1/mega99_mega65r3_top.keep_wbstar.bit $(EMBEDDED_FILES)
	$(CORETOOL) -B $@ -F -t mega65r3 -b $< -n Mega99 -v $(CORE_VERSION) --add-files $(EMBEDDED_FILES)

proj/mega99_mega65r6.runs/impl_1/mega99_mega65r6_top.bit : proj/mega99_mega65r6.xpr vivado/build.tcl $(COMMON_SOURCES) $(MOR1KX_SOURCES) $(MEGA65R6_SOURCES) $(BOOTHEX)
	$(VIVADO) -mode batch -source vivado/build.tcl proj/mega99_mega65r6.xpr

proj/mega99_mega65r3.runs/impl_1/mega99_mega65r3_top.bit : proj/mega99_mega65r3.xpr vivado/build.tcl $(COMMON_SOURCES) $(MOR1KX_SOURCES) $(MEGA65R3_SOURCES) $(BOOTHEX)
	$(VIVADO) -mode batch -source vivado/build.tcl proj/mega99_mega65r3.xpr

proj/mega99_mega65r6.xpr : vivado/mega99_mega65r6.tcl | $(BOOTHEX)
	@rm -rf proj/mega99_mega65r6.*
	$(VIVADO) -mode batch -source vivado/mega99_mega65r6.tcl

proj/mega99_mega65r3.xpr : vivado/mega99_mega65r3.tcl | $(BOOTHEX)
	@rm -rf proj/mega99_mega65r3.*
	$(VIVADO) -mode batch -source vivado/mega99_mega65r3.tcl


proj/mega99_nexys_a7%.runs/impl_1/mega99_nexys_a7_top.bit : proj/mega99_nexys_a7%.xpr vivado/build.tcl $(COMMON_SOURCES) $(MOR1KX_SOURCES) $(NEXYS_A7_SOURCES) $(BOOTHEX)
	$(VIVADO) -mode batch -source vivado/build.tcl proj/mega99_nexys_a7$*.xpr

proj/mega99_nexys_a7-50t.xpr : vivado/mega99_nexys_a7.tcl | $(BOOTHEX)
	@rm -rf proj/mega99_nexys_a7-50t.*
	$(VIVADO) -mode batch -source vivado/mega99_nexys_a7.tcl -tclargs --project_name mega99_nexys_a7-50t --part xc7a50ticsg324-1L

proj/mega99_nexys_a7-100t.xpr : vivado/mega99_nexys_a7.tcl | $(BOOTHEX)
	@rm -rf proj/mega99_nexys_a7-100t.*
	$(VIVADO) -mode batch -source vivado/mega99_nexys_a7.tcl -tclargs --project_name mega99_nexys_a7-100t --part xc7a100tcsg324-1


TOOLCHAIN_DIR = $(CURDIR)/build/toolchain
TCSTAMP = $(TOOLCHAIN_DIR)/.stamp
export PATH := $(TOOLCHAIN_DIR)/bin:${PATH}

SP_OBJCOPY_BIN = or1k-elf-objcopy -O binary
SP_AR = or1k-elf-ar rc
SP_CC = or1k-elf-gcc
SP_CFLAGS = -std=c23 -ffunction-sections -fdata-sections \
	-mcmov -msext -msfimm -mshftimm -mror -mrori -funsigned-char \
	-I spsrc/common -DTICKS_PER_SEC=108000000u

SP_BOOT_CFLAGS = $(SP_CFLAGS) -Os -fno-move-loop-invariants \
	-ffreestanding -finline-stringops -DBOOTCODE
SP_BOOT_LDSCRIPT = spsrc/boot/main.lds
SP_BOOT_LDFLAGS = -nostartfiles -nodefaultlibs -Wl,--no-warn-rwx-segments \
	-Wl,--defsym,__stack=0x4000,-T,$(SP_BOOT_LDSCRIPT) \
	-Wl,--gc-sections,-eboot,-Map,$@.map

SP_BOOT_SRCS  = boot/entry.S
SP_BOOT_SRCS += boot/main.c
SP_BOOT_SRCS += common/display.c
SP_BOOT_SRCS += common/uart.c
SP_BOOT_SRCS += common/sdcard.c
SP_BOOT_SRCS += common/fatfs.c
SP_BOOT_SRCS += common/strerr.c
SP_BOOT_SRCS += common/embedfile.c

SP_MAIN_CFLAGS = $(SP_CFLAGS) -O2 -I spsrc/minizip-ng
SP_MAIN_LDFLAGS = -Wl,--section-start=.vectors=0x40000000,-Ttext=0x40002000 \
	-Wl,-z,max-page-size=0x10,--gc-sections,-Map,$@.map

SP_MAIN_SRCS  = main/main.c
SP_MAIN_SRCS += main/newlib_stubs.c
SP_MAIN_SRCS += main/board.S
SP_MAIN_SRCS += main/zipfile.c
SP_MAIN_SRCS += main/rpk.c
SP_MAIN_SRCS += main/tape.c
SP_MAIN_SRCS += main/fdc.c
SP_MAIN_SRCS += main/overlay.c
SP_MAIN_SRCS += main/keyboard.c
SP_MAIN_SRCS += main/menu.c
SP_MAIN_SRCS += main/reset.c
SP_MAIN_SRCS += common/display.c
SP_MAIN_SRCS += common/uart.c
SP_MAIN_SRCS += common/sdcard.c
SP_MAIN_SRCS += common/fatfs.c
SP_MAIN_SRCS += common/yxml.c
SP_MAIN_SRCS += common/strerr.c
SP_MAIN_SRCS += common/embedfile.c

SP_MZ_CFLAGS = -DMZ_ZIP_NO_MAIN -DMZ_ZIP_NO_CRYPTO -DMZ_ZIP_NO_ENCRYPTION \
	-DMZ_ZIP_NO_COMPRESSION -DHAVE_ZLIB -I $(SP_ZLIB_BUILD)

SP_MZ_SRCS  = mz_zip.c
SP_MZ_SRCS += mz_strm.c
SP_MZ_SRCS += mz_strm_mem.c
SP_MZ_SRCS += mz_strm_buf.c
SP_MZ_SRCS += mz_strm_zlib.c

SP_BOOT_BUILD = build/spboot
SP_MAIN_BUILD = build/spmain
SP_MZ_BUILD   = build/minizip-ng
SP_ZLIB_BUILD = build/zlib-ng

SP_BOOT_OBJS = $(addprefix $(SP_BOOT_BUILD)/,$(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SP_BOOT_SRCS))))
SP_MAIN_OBJS = $(addprefix $(SP_MAIN_BUILD)/,$(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SP_MAIN_SRCS))))
SP_MZ_OBJS = $(addprefix $(SP_MZ_BUILD)/,$(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SP_MZ_SRCS))))

PYTHON = python

.DELETE_ON_ERROR:

or1k_boot_code.hex : $(SP_BOOT_BUILD)/or1k_boot_code.bin
	$(PYTHON) genhex.py -o or1k_boot_code.hex $<

$(SP_BOOT_BUILD)/or1k_boot_code.bin : $(SP_BOOT_BUILD)/or1k_boot_code.elf | $(TCSTAMP)
	$(SP_OBJCOPY_BIN) $< $@

$(SP_BOOT_BUILD)/or1k_boot_code.elf : $(SP_BOOT_OBJS) $(SP_BOOT_LDSCRIPT) | $(TCSTAMP)
	$(SP_CC) $(SP_BOOT_CFLAGS) $(SP_BOOT_LDFLAGS) -o $@ $(SP_BOOT_OBJS)

$(SP_BOOT_BUILD)/%.o : spsrc/%.S | $(TCSTAMP)
	@mkdir -p $(@D)
	$(SP_CC) $(SP_BOOT_CFLAGS) -MMD -c -o $@ $<

$(SP_BOOT_BUILD)/%.o : spsrc/%.c | $(TCSTAMP)
	@mkdir -p $(@D)
	$(SP_CC) $(SP_BOOT_CFLAGS) -MMD -c -o $@ $<

mega99sp.bin : $(SP_MAIN_BUILD)/mega99sp.elf | $(TCSTAMP)
	$(SP_OBJCOPY_BIN) $< $@

$(SP_MAIN_BUILD)/mega99sp.elf : $(SP_MAIN_OBJS) $(SP_MZ_BUILD)/libminizip-ng.a $(SP_ZLIB_BUILD)/libz-ng.a $(SP_ZLIB_BUILD)/libz-ng.a | $(TCSTAMP)
	$(SP_CC) $(SP_MAIN_CFLAGS) $(SP_MAIN_LDFLAGS) -o $@ $(SP_MAIN_OBJS) $(SP_MZ_BUILD)/libminizip-ng.a $(SP_ZLIB_BUILD)/libz-ng.a

$(SP_MAIN_BUILD)/%.o : spsrc/%.S | $(TCSTAMP)
	@mkdir -p $(@D)
	$(SP_CC) $(SP_MAIN_CFLAGS) -MMD -c -o $@ $<

$(SP_MAIN_BUILD)/%.o : spsrc/%.c | $(TCSTAMP)
	@mkdir -p $(@D)
	$(SP_CC) $(SP_MAIN_CFLAGS) -MMD -c -o $@ $<

$(SP_MZ_BUILD)/libminizip-ng.a : $(SP_MZ_OBJS) | $(TCSTAMP)
	$(SP_AR) $@ $(SP_MZ_OBJS)

$(SP_MZ_BUILD)/%.o : spsrc/minizip-ng/%.c $(SP_ZLIB_BUILD)/zlib-ng.h | $(TCSTAMP)
	@mkdir -p $(@D)
	$(SP_CC) $(SP_MAIN_CFLAGS) $(SP_MZ_CFLAGS) -MMD -c -o $@ $<

$(SP_ZLIB_BUILD)/zlib-ng.h :
	@mkdir -p $(@D)
	cd $(@D) && CHOST=or1k-elf CC="$(SP_CC)" CFLAGS="$(SP_CFLAGS) -U__INT32_TYPE__ -D__INT32_TYPE__=int" $(CURDIR)/spsrc/zlib-ng/configure --static --without-gzfileops

$(SP_ZLIB_BUILD)/libz-ng.a :
	cd $(@D) && make libz-ng.a

$(TOOLCHAIN_DIR)/.stamp :
	./toolchain.sh $(TOOLCHAIN_DIR)
	touch $@

-include $(SP_BOOT_OBJS:.o=.d)
-include $(SP_MAIN_OBJS:.o=.d)
