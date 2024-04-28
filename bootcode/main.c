#include <stdint.h>

#include "timer.h"
#include "display.h"
#include "regs.h"

void main()
{
  timer_init();
  display_init();

  printstrn(SCREENPOS(0, 0), "Good morning world!", 19);

  uint32_t last_timer = timer_read();
  uint32_t count = 0;
  for (;;) {
    uint32_t timer = timer_read();
    if ((timer-last_timer) >= S_TO_TICKS(1u)) {
      count++;
      last_timer += S_TO_TICKS(1u);
    }
    printhex(SCREENPOS(2, 0), count);
    REGS_MISC.leds = (count & 1u) | 2u;
  }

}
