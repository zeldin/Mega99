#include <stdint.h>
#include <stddef.h>

#include "display.h"

#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)
#define FLUSH do { __asm__("" : : : "memory"); } while(0)

static const uint8_t font_8x8[] = {
#include "font_8x8.h"
};

static const uint8_t vdpregs[] = {
  0x00, 0x00, 0x00, 0x0c, 0x01, 0x06, 0x01, 0x0b
};

void display_init(void)
{
  VDPREG[1] = 0;
  FLUSH;
  __builtin_memset(VDPRAM, 0, 0x1000);
  __builtin_memset(VDPRAM+0x300, 0x10, 32);
  __builtin_memcpy(VDPRAM+0x900, font_8x8, sizeof(font_8x8));
  VDPRAM[0x300] = 0xd0;
  __builtin_memcpy(VDPREG+0, vdpregs, sizeof(vdpregs));
  FLUSH;
  VDPREG[1] = 0x40;
}

void printstrn(uint32_t offs, const char *s, size_t n)
{
  __builtin_memcpy(VDPRAM+offs, s, n);
}
  
void printhex(uint32_t offs, uint32_t v)
{
  unsigned i;
  uint8_t *p = VDPRAM+offs;
  for(i=0; i<8; i++) {
    unsigned d = v >> 28;
    v <<= 4;
    *p++ = (d < 10? d + '0' : d + ('A'-10));
  }
}
