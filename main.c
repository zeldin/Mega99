#include <stdint.h>

#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)

static const uint8_t font_8x8[] = {
#include "font_8x8.h"
};

static const uint8_t vdpregs[] = {
  0x00, 0x00, 0x00, 0x0c, 0x01, 0x06, 0x01, 0x0b
};

void main()
{
  VDPREG[1] = 0;
  __builtin_memset(VDPRAM, 0, 0x1000);
  __builtin_memset(VDPRAM+0x300, 0x10, 32);
  __builtin_memcpy(VDPRAM+0x900, font_8x8, sizeof(font_8x8));
  __builtin_memcpy(VDPRAM, "Good morning world!", 19);
  VDPRAM[0x300] = 0xd0;
  __builtin_memcpy(VDPREG+0, vdpregs, sizeof(vdpregs));
  VDPREG[1] = 0x40;
}
