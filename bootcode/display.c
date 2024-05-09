#include "global.h"
#include "display.h"

#define VDPRAM ((uint8_t *)(void *)0x80000000)
#define VDPREG (VDPRAM+0x4000)
#define FLUSH do { __asm__("" : : : "memory"); } while(0)

#define SCREENPOS(y, x) (((y) << 5) | (x))


static const uint8_t font_8x8[] = {
#include "font_8x8.h"
};

static const uint8_t vdpregs[] = {
  0x00, 0x00, 0x00, 0x0c, 0x01, 0x06, 0x01, 0x0b
};

static uint8_t xpt, ypt;

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
  xpt = ypt = 0;
}

void display_putc(char c)
{
  if (c == '\n')
    xpt = 32;
  else
    VDPRAM[SCREENPOS(ypt, xpt++)] = c;
  if (xpt >= 32) {
    xpt = 0;
    if (++ypt >= 24) {
      __builtin_memcpy(VDPRAM+SCREENPOS(0, 0),
		       VDPRAM+SCREENPOS(1, 0),
		       23*32);
      __builtin_memset(VDPRAM+SCREENPOS(23, 0), 0, 32);
      ypt = 23;
    }
  }
}

void display_puts(const char *str)
{
  while(*str)
    display_putc(*str++);
}

void display_puthex(uint32_t v)
{
  unsigned i;
  for(i=0; i<8; i++) {
    unsigned d = v >> 28;
    v <<= 4;
    display_putc((d < 10? d + '0' : d + ('A'-10)));
  }
}

void display_vprintf(const char *fmt, va_list va)
{
  char c;
  while ((c = *fmt++))
    if (c == '%')
      switch ((c = *fmt++)) {
      case 0: return;
      case '%': display_putc(c); break;
      case 's': display_puts(va_arg(va, const char *)); break;
      case 'x': display_puthex(va_arg(va, uint32_t)); break;
      }
    else
      display_putc(c);
}

void display_printf(const char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  display_vprintf(fmt, va);
  va_end(va);
}
