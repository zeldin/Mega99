#include <stdint.h>

struct mmio_regs_misc {
  uint32_t leds;
};

#define REGS_MISC (*(volatile struct mmio_regs_misc *)(void *)0xff000000)
