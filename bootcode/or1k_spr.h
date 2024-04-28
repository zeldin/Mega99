#include <stdint.h>

static inline void or1k_mtspr (uint32_t spr, uint32_t value)
{
  __asm__ __volatile__ ("l.mtspr\t\t%0,%1,0": : "r" (spr), "r" (value));
}

static inline uint32_t or1k_mfspr (uint32_t spr) {
  uint32_t value;
  __asm__ __volatile__ ("l.mfspr\t\t%0,%1,0" : "=r" (value) : "r" (spr));
  return value;
}

#define OR1K_SPR_TICK_TTMR_ADDR  0x5000u
#define OR1K_SPR_TICK_TTCR_ADDR  0x5001u
