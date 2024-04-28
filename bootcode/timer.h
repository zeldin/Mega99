#include <stdint.h>

#ifdef __or1k__

#include "or1k_spr.h"

static inline void timer_init(void)
{
  or1k_mtspr(OR1K_SPR_TICK_TTMR_ADDR, 0xc0000000u);
}

static uint32_t timer_read(void)
{
  return or1k_mfspr(OR1K_SPR_TICK_TTCR_ADDR);
}

#endif

#define S_TO_TICKS(n) ((n) * TICKS_PER_SEC)
#define MS_TO_TICKS(n) ((uint32_t)(((uint64_t)(n)) * TICKS_PER_SEC / 1000u))
#define US_TO_TICKS(n) ((uint32_t)(((uint64_t)(n)) * TICKS_PER_SEC / 1000000u))
