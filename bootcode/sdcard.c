#include <stdint.h>

#include "timer.h"
#include "regs.h"
#include "sdcard.h"

#include "display.h"

#define SPI_SPEED(n) ((TICKS_PER_SEC+(2u*(n)-1u)) / (2u*(n)) - 1u)

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

static void sdcard_deselect(void)
{
  unsigned i;
  for (i=0; i<20; i++) {
    REGS_SDCARD.cmd = 0x1ffu;
    while ((REGS_SDCARD.cmd & 0x100u))
      ;
  }
}

static uint8_t sdcard_sendbyte(uint8_t byte)
{
  REGS_SDCARD.cmd = 0x1100u | byte;
  while ((REGS_SDCARD.cmd & 0x100u))
    ;
  return REGS_SDCARD.cmd;
}

static uint8_t sdcard_getresponse(void)
{
  REGS_SDCARD.cmd = 0x1300u;
  uint32_t time0 = timer_read();
  while ((REGS_SDCARD.cmd & 0x100u))
    if ((timer_read() - time0) > MS_TO_TICKS(20)) {
      REGS_SDCARD.cmd = 0x1000u;
      return 0xff;
    }
  return REGS_SDCARD.cmd;
}

static uint8_t sdcard_docmd_nodeselect(uint8_t cmd, uint32_t param, uint8_t crc)
{
  sdcard_sendbyte(cmd);
  sdcard_sendbyte(param >> 24);
  sdcard_sendbyte(param >> 16);
  sdcard_sendbyte(param >> 8);
  sdcard_sendbyte(param);
  sdcard_sendbyte(crc);
  return sdcard_getresponse();
}

static uint8_t sdcard_docmd(uint8_t cmd, uint32_t param, uint8_t crc)
{
  uint8_t r = sdcard_docmd_nodeselect(cmd, param, crc);
  sdcard_deselect();
  return r;
}

static uint32_t sdcard_getr7(void)
{
  uint32_t r = sdcard_sendbyte(0);
  r <<= 8; r |= sdcard_sendbyte(0);
  r <<= 8; r |= sdcard_sendbyte(0);
  r <<= 8; r |= sdcard_sendbyte(0);
  sdcard_deselect();
  return r;
}

void sdcard_activate()
{
  unsigned i;
  display_printf("Activating card\n");
  REGS_SDCARD.ctrl = SPI_SPEED(400000) << 8u;
  sdcard_deselect();
  uint8_t r1 = sdcard_docmd(0x40, 0, 0x95);
  display_printf("CMD0, R1 = %x\n", r1);
  if (r1 != 0x01)
    return;
  r1 = sdcard_docmd_nodeselect(0x48, 0x1aa, 0x87);
  uint32_t r7 = sdcard_getr7();
  display_printf("CMD8, R7 = %x %x\n", r1, r7);
}
