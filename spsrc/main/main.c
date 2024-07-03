#include "global.h"
#include "mem.h"
#include "regs.h"
#include "uart.h"
#include "display.h"

void main()
{
  REGS_MISC.reset = 0xf;
  REGS_MISC.reset = 0xd; // Release VDP from reset

  display_init();

  REGS_MISC.leds = 1u;

  REGS_MISC.reset = 0xf;  
  __builtin_memset(VDPRAM, 0, 0x1000);
  REGS_MISC.reset = 0xd;

  uart_puts("Starting TMS9900\n");
  REGS_MISC.reset = 0x0;
}
