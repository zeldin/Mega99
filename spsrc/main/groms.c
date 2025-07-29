#include "global.h"
#include "regs.h"
#include "mem.h"
#include "groms.h"

#if GROMS_USE_DMA

#define NUM_GROMS 128

static uint16_t grom_base[NUM_GROMS], grom_alloced[NUM_GROMS];

static __attribute__((aligned(0x800))) uint8_t grom_data[NUM_GROMS][0x2000];

uint8_t *groms_allocate_grom(uint16_t sets, uint16_t base)
{
  groms_free_grom_range(sets, base, 0x2000);
  if (!sets)
    return NULL;
  unsigned i;
  for (i=0; i<NUM_GROMS; i++)
    if (!grom_alloced[i]) {
      grom_alloced[i] = sets;
      grom_base[i] = base;
      unsigned set = 0;
      while (sets) {
	if ((sets & 1u)) {
	  unsigned offs;
	  for (offs = 0; offs < 0x2000; offs += 0x800)
	    REGS_IOMMU_DESCRIPTOR(set, base+offs) =
	      (uintptr_t)&grom_data[i][offs];
	}
	set++;
	sets >>= 1;
      }
      memset(grom_data[i], 0, sizeof(grom_data[i]));
      return &grom_data[i][0];
    }
  return NULL;
}

void groms_free_grom_range(uint16_t sets, uint16_t base, size_t size)
{
  unsigned i;
  for (i=0; i<NUM_GROMS; i++)
    if (grom_base[i] >= base && grom_base[i]-base+0x1fffu < size)
      grom_alloced[i] &= ~sets;
  while (size > 0) {
    uint16_t sets_left = sets;
    unsigned set = 0;
    while (sets_left) {
      if ((sets_left & 1u))
	REGS_IOMMU_DESCRIPTOR(set, base) = 0;
      set++;
      sets_left >>= 1;
    }
    base += 0x0800;
    if (size < 0x0800)
      break;
    size -= 0x0800;
  }
}

void groms_update_garbage(uint8_t *grom)
{
  unsigned i;
  for (i=0; i<0x800; i++)
    grom[0x1800+i] = grom[0x800+i] | grom[0x1000+i];
}

void groms_init(void)
{
  memset(grom_alloced, 0, sizeof(grom_alloced));
}

#else

uint8_t *groms_allocate_grom(uint16_t sets, uint16_t base)
{
  return GROM(base>>13);
}

void groms_free_grom_range(uint16_t sets, uint16_t base, size_t size)
{
  memset(GROM(base>>13), 0, size);
}

void groms_update_garbage(uint8_t *grom)
{
}

void groms_init(void)
{
}

#endif
