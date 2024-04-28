#include <stdint.h>

#include "timer.h"
#include "display.h"
#include "regs.h"

void main()
{
  timer_init();
  display_init();

  REGS_MISC.leds = 1u;

  display_printf("Good %s world!\n\n", "morning");

  uint32_t last_sdctrl = ~0;
  for (;;) {
    uint32_t sdctrl = REGS_SDCARD.ctrl;
    if (sdctrl != last_sdctrl) {
      last_sdctrl = sdctrl;
      display_printf("%x\n", sdctrl);
    }
  }

}
