#include "global.h"
#include "mem.h"
#include "regs.h"
#include "embedfile.h"

static uint32_t read_icap_reg(uint32_t reg)
{
  reg &= 0x1f;
  for (;;) {
    uint32_t current_reg = REGS_MISC.icap_reg;
    if ((current_reg & 0x80000000U))
      continue;
    if (current_reg == reg)
      break;
    REGS_MISC.icap_reg = reg;
  }
  return REGS_MISC.icap_value;
}

static bool match_filename(const char *fn1, const char *fn2)
{
  const char *fn2end = fn2+32;
  while (fn2 < fn2end) {
    char c = *fn1++;
    char x = c ^ *fn2++;
    if (x) {
      if (x != 0x20 || c < 0x40)
	return false;
    } else if (!c)
      return true;
  }
  return !*fn1;
}

const void *embedfile_find(const char *filename, uint32_t *len)
{
  uint32_t wbstar = read_icap_reg(0x10);
  if ((wbstar & 0x007fff) != 0x0010 || wbstar >= 0x100000)
    return NULL;
  const uint8_t *slot = QSPI + ((wbstar - 0x10) << 8);
  if (memcmp(slot, "MEGA65BITSTREAM0", 16))
    return NULL;
  uint32_t embed_offs =
    slot[115] | (slot[116] << 8) | (slot[117] << 16) | (slot[118] << 24);
  for (unsigned i=slot[114]; i>0; --i) {
    if (!embed_offs || embed_offs >= 0x800000)
      break;
    uint32_t next =
      slot[embed_offs] | (slot[embed_offs+1] << 8) |
      (slot[embed_offs+2] << 16) | (slot[embed_offs+3] << 24);
    if (match_filename(filename, slot+embed_offs+8)) {
      if (len)
	*len = slot[embed_offs+4] | (slot[embed_offs+5] << 8) |
	  (slot[embed_offs+6] << 16) | (slot[embed_offs+7] << 24);
      return slot+embed_offs+40;
    }
    embed_offs = next;
  }
  return NULL;
}
