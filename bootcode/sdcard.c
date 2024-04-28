#include <stdint.h>

#include "timer.h"
#include "regs.h"
#include "sdcard.h"

uint32_t sdcard_status(void)
{
  uint32_t ctrl = REGS_SDCARD.ctrl;
  if ((ctrl & 0xcu)) {
    /* Inserted or removed, wait for bounce to settle */
    uint32_t time0 = timer_read();
    uint32_t time_last = time0;
    for (;;) {
      uint32_t t = timer_read();
      if ((ctrl & 0xcu))
	REGS_SDCARD.ctrl = ctrl | 0xcu;
      ctrl = REGS_SDCARD.ctrl;
      if ((ctrl & 0xcu)) {
	time_last = t;
	if ((t - time0) >= MS_TO_TICKS(100)) {
	  // The card failed to debounce, just report card extracted
	  ctrl = 0;
	  break;
	}
      } else if((t - time_last) >= MS_TO_TICKS(20))
	// Debounce complete
	break;
    }
    ctrl |= 4u;
  }
  if (!(ctrl & 1u))
    // Mask WP if no card inserted
    ctrl &= ~2u;
  return ctrl & 7u;
}
