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

struct mmio_regs_overlay {
  struct {
    uint8_t y0;
    uint8_t x0;
    uint8_t y1;
    uint8_t x1;
    uint16_t base;
    uint16_t lineoffs;
  } window[4];
  uint8_t xadj;
  uint8_t yadj;
  uint16_t control;
};

#define REGS_OVERLAY (*(volatile struct mmio_regs_overlay *)(void *)0xff03ff00)

#define OVERLAY ((uint8_t *)(void *)0xff030000)

struct mmio_regs_keyboard {
  uint16_t keycode;
  uint16_t pad;
  uint8_t block;
};

#define REGS_KEYBOARD (*(volatile struct mmio_regs_keyboard *)(void *)0xff040000)

struct mmio_regs_tape {
  uint16_t control;
  uint16_t sample_rate;
  uint16_t head, tail;
  uint16_t memsize;
  uint16_t pad;
  uint16_t fifo_read;
};

#define REGS_TAPE (*(volatile struct mmio_regs_tape *)(void *)0xff05ff00)

#define TAPE_SAMPLES ((uint8_t *)(void *)0xff050000)
