struct mmio_regs_misc {
  uint32_t leds;
};

#define REGS_MISC (*(volatile struct mmio_regs_misc *)(void *)0xff000000)

struct mmio_regs_sdcard {
  uint32_t ctrl;
  uint32_t cmd;
  uint16_t crc16;
};

#define REGS_SDCARD (*(volatile struct mmio_regs_sdcard *)(void *)0xff010000)
