#include "global.h"
#include "reset.h"
#include "regs.h"
#include "timer.h"

static void reset_change(uint32_t mask, uint32_t value)
{
  uint32_t old_reset = REGS_MISC.reset;
  value = (value & mask) | (old_reset & ~mask);
  if (value != old_reset) {
    uint32_t t, t0 = timer_read();
    do {
      t = timer_read() - t0;
    } while (t < US_TO_TICKS(100));
    REGS_MISC.reset = value;
  }
}

void reset_set_vdp(bool assert)
{
  reset_change(UINT32_C(0x20), (assert? ~UINT32_C(0) : UINT32_C(0)));
}

void reset_set_other(bool assert)
{
  reset_change(UINT32_C(0xdf), (assert? ~UINT32_C(0) : UINT32_C(0)));
}
