#include "global.h"
#include "timer.h"
#include "display.h"
#include "sdcard.h"
#include "regs.h"

void main()
{
  timer_init();
  display_init();

  REGS_MISC.leds = 1u;

  display_printf("Good %s world!\n\n", "morning");

  uint32_t last_sdstatus = ~0;
  for (;;) {
    uint32_t sdstatus = sdcard_status();
    if ((sdstatus & 4u) || sdstatus != last_sdstatus) {
      last_sdstatus = sdstatus;
      display_printf("%x\n", sdstatus);
      if ((sdstatus & 5u) == 5u)
	sdcard_activate();
    }
  }

}
