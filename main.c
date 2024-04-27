#include <stdint.h>

#include "spr.h"

#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)
#define FLUSH do { __asm__("" : : : "memory"); } while(0)

#define TICKS_PER_SEC 53693175u

static const uint8_t font_8x8[] = {
#include "font_8x8.h"
};

static const uint8_t vdpregs[] = {
  0x00, 0x00, 0x00, 0x0c, 0x01, 0x06, 0x01, 0x0b
};

static void printhex(uint8_t *p, uint32_t v)
{
  unsigned i;
  for(i=0; i<8; i++) {
    unsigned d = v >> 28;
    v <<= 4;
    *p++ = (d < 10? d + '0' : d + ('A'-10));
  }
}

void main()
{
  VDPREG[1] = 0;
  FLUSH;
  __builtin_memset(VDPRAM, 0, 0x1000);
  __builtin_memset(VDPRAM+0x300, 0x10, 32);
  __builtin_memcpy(VDPRAM+0x900, font_8x8, sizeof(font_8x8));
  __builtin_memcpy(VDPRAM, "Good morning world!", 19);
  VDPRAM[0x300] = 0xd0;
  __builtin_memcpy(VDPREG+0, vdpregs, sizeof(vdpregs));
  FLUSH;
  VDPREG[1] = 0x40;
  FLUSH;

  or1k_mtspr(OR1K_SPR_TICK_TTMR_ADDR, 0xc0000000u);
  uint32_t last_timer = or1k_mfspr(OR1K_SPR_TICK_TTCR_ADDR);
  uint32_t count = 0;
  for (;;) {
    uint32_t timer = or1k_mfspr(OR1K_SPR_TICK_TTCR_ADDR);
    if ((timer-last_timer) >= TICKS_PER_SEC) {
      count++;
      last_timer += TICKS_PER_SEC;
    }
    printhex(VDPRAM+64, count);
  }

}
