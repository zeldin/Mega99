struct mmio_regs_misc {
  uint32_t leds;
  uint16_t enable;
  uint16_t reset;
  uint32_t led1_rgb;
  uint32_t led2_rgb;
  uint32_t led3_rgb;
  uint32_t led4_rgb;
  uint32_t icap_value;
  uint32_t icap_reg;
};

#define REGS_MISC (*(volatile struct mmio_regs_misc *)(void *)0xff000000)

#define REGS_MISC_LEDS_RED   UINT32_C(0x02)
#define REGS_MISC_LEDS_GREEN UINT32_C(0x01)

#define REGS_MISC_ENABLE_RAM32K UINT16_C(0x80)
#define REGS_MISC_ENABLE_FDC    UINT16_C(0x40)
#define REGS_MISC_ENABLE_VSP    UINT16_C(0x20)
#define REGS_MISC_ENABLE_1KSP   UINT16_C(0x10)
#define REGS_MISC_ENABLE_JOYSWP UINT16_C(0x08)
#define REGS_MISC_ENABLE_TIPI   UINT16_C(0x04)
#define REGS_MISC_ENABLE_TIPI_INTERNAL      UINT16_C(0x02)
#define REGS_MISC_ENABLE_TIPI_CRUADDR_MASK  UINT16_C(0xF000)
#define REGS_MISC_ENABLE_TIPI_CRUADDR_SHIFT 12u

#define REGS_MISC_RESET_CPU UINT16_C(0x80)
#define REGS_MISC_RESET_PSI UINT16_C(0x40)
#define REGS_MISC_RESET_VDP UINT16_C(0x20)
#define REGS_MISC_RESET_SGC UINT16_C(0x10)
#define REGS_MISC_RESET_VSP UINT16_C(0x08)

struct mmio_regs_sdcard {
  uint16_t ctrl;
  uint16_t cmd;
  uint8_t crc7;
  uint8_t sd_select;
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

#define REGS_UART_STATUS_RXVALID UINT8_C(2)
#define REGS_UART_STATUS_TXREADY UINT8_C(1)

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
  uint8_t pad2;
  uint16_t synth_key_high;
  uint32_t synth_key_low;
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

struct mmio_regs_tipi {
  union {
    struct {
      uint32_t status;
      uint32_t control;
    };
    struct {
      uint16_t status_flags;
      uint8_t tc;
      uint8_t td;
      uint16_t control_flags;
      uint8_t rc;
      uint8_t rd;
    };
  };
};

#define REGS_TIPI (*(volatile struct mmio_regs_tipi *)(void *)0xff060000)
