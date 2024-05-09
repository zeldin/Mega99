struct mmio_regs_misc {
  uint32_t leds;
  uint32_t reset;
};

#define REGS_MISC (*(volatile struct mmio_regs_misc *)(void *)0xff000000)

struct mmio_regs_sdcard {
  uint16_t ctrl;
  uint16_t cmd;
  uint8_t crc7;
  uint8_t pad;
  uint16_t crc16;
};

#define REGS_SDCARD (*(volatile struct mmio_regs_sdcard *)(void *)0xff010000)
