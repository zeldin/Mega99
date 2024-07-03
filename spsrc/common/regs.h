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

struct mmio_regs_uart {
  uint16_t baudrate;
  uint8_t status;
  uint8_t tx_data;
  uint8_t rx_data;
  uint8_t pad1;
  uint16_t pad2;
};

#define REGS_UART (*(volatile struct mmio_regs_uart *)(void *)0xff020000)
