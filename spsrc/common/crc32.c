#include "global.h"
#include "crc32.h"

uint32_t crc32(const uint8_t *data, uint32_t size)
{
  uint32_t r = ~0;
  const uint8_t *end = data + size;
  while(data < end) {
    r ^= *data++;
    for(unsigned i = 0; i < 8; i++) {
      uint32_t t = ~((r&1) - 1);
      r = (r>>1) ^ (0xEDB88320u & t);
    }
  }
  return ~r;
}
