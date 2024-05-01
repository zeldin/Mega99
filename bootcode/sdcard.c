#include "global.h"
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

static uint8_t sdcard_docmd_nodeselect(uint8_t cmd, uint32_t param)
{
  sdcard_sendbyte(0x40 | cmd);
  sdcard_sendbyte(param >> 24);
  sdcard_sendbyte(param >> 16);
  sdcard_sendbyte(param >> 8);
  sdcard_sendbyte(param);
  sdcard_sendbyte(REGS_SDCARD.cmd >> 24);
  return sdcard_getresponse();
}

static uint8_t sdcard_docmd(uint8_t cmd, uint32_t param)
{
  uint8_t r = sdcard_docmd_nodeselect(cmd, param);
  sdcard_deselect();
  return r;
}

static uint8_t sdcard_docmd_noparam(uint8_t cmd)
{
  return sdcard_docmd(cmd, 0u);
}

static uint32_t sdcard_getextresponse(void)
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
  uint8_t r1;
  uint32_t time0 = timer_read();
  do {
    r1 = sdcard_docmd_noparam(0);
    if ((timer_read() - time0) > MS_TO_TICKS(2000))
      break;
  } while(r1 != 1u);
  display_printf("CMD0, R1 = %x\n", r1);
  if (r1 != 1u)
    return;
  r1 = sdcard_docmd_nodeselect(8, 0x1aa);
  uint32_t r7 = sdcard_getextresponse();
  display_printf("CMD8, R7 = %x %x\n", r1, r7);
  uint32_t p = 0;
  if (!(r1 & 4u) && r7 == 0x1aa) {
    display_printf("Card is SD2\n");
    p = 0x40000000;
  } else {
    display_printf("Card is SD1\n");
  }
  time0 = timer_read();
  do {
    r1 = sdcard_docmd_noparam(55);
    if ((r1 & ~1)) {
      display_printf("CMD55, R1 = %x\n", r1);
      return;
    }
    r1 = sdcard_docmd(41, p);
    if ((timer_read() - time0) > MS_TO_TICKS(2000))
      break;
  } while (r1 == 1);
  display_printf("ACMD41, R1 = %x\n", r1);
  if (r1 != 0)
    return;
  if (p) {
    r1 = sdcard_docmd_nodeselect(58, 0);
    uint32_t r3 = sdcard_getextresponse();
    display_printf("CMD58, R3 = %x %x\n", r1, r3);
    if (r1 != 0)
      return;
    if (((r3 >> 30) & 3u) == 3u)
      display_printf("Card is SDHC\n");
  }
}
