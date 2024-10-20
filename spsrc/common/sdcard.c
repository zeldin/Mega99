#include "global.h"
#include "timer.h"
#include "regs.h"
#include "sdcard.h"

#include "display.h"

#define SPI_SPEED(n) ((TICKS_PER_SEC+(2u*(n)-1u)) / (2u*(n)) - 1u)

#define DEBOUNCE_TIME    MS_TO_TICKS(20)
#define TIMEOUT_DEBOUNCE MS_TO_TICKS(100)
#define TIMEOUT_RESPONSE MS_TO_TICKS(20)
#define TIMEOUT_IDLE     MS_TO_TICKS(500)
#define TIMEOUT_ACTIVE   MS_TO_TICKS(500)
#define TIMEOUT_READBLK  MS_TO_TICKS(125)
#define TIMEOUT_WRITEBLK MS_TO_TICKS(250)

#define DEBUG_PRINT(...) do { } while(0)
// #define DEBUG_PRINT(...) do { display_printf(__VA_ARGS__); } while(0)


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
	if ((t - time0) >= TIMEOUT_DEBOUNCE) {
	  // The card failed to debounce, just report card extracted
	  ctrl = 0;
	  break;
	}
      } else if((t - time_last) >= DEBOUNCE_TIME)
	// Debounce complete
	break;
    }
    ctrl |= SDCARD_STATUS_CHANGED;
  }
  if (!(ctrl & SDCARD_STATUS_PRESENT))
    // Mask WP if no card inserted
    ctrl &= ~SDCARD_STATUS_WRITEPROT;
  return ctrl &
    (SDCARD_STATUS_PRESENT | SDCARD_STATUS_WRITEPROT | SDCARD_STATUS_CHANGED);
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

static uint8_t sdcard_recvbyte(void)
{
  return sdcard_sendbyte(0xff);
}

static uint8_t sdcard_getresponse(void)
{
  REGS_SDCARD.cmd = 0x13ffu;
  uint32_t time0 = timer_read();
  while ((REGS_SDCARD.cmd & 0x100u))
    if ((timer_read() - time0) > TIMEOUT_RESPONSE) {
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
  sdcard_sendbyte(REGS_SDCARD.crc7);
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
  uint32_t r = sdcard_recvbyte();
  r <<= 8; r |= sdcard_recvbyte();
  r <<= 8; r |= sdcard_recvbyte();
  r <<= 8; r |= sdcard_recvbyte();
  sdcard_deselect();
  return r;
}

sdcard_type_t sdcard_activate()
{
  unsigned i;
  DEBUG_PRINT("Activating card\n");
  REGS_SDCARD.ctrl = SPI_SPEED(400000u) << 8u;
  sdcard_deselect();
  uint8_t r1;
  uint32_t time0 = timer_read();
  do {
    if (!(REGS_SDCARD.ctrl & 1))
      return SDCARD_REMOVED;
    r1 = sdcard_docmd_noparam(0);
    if ((timer_read() - time0) > TIMEOUT_IDLE)
      break;
  } while(r1 != 1u);
  DEBUG_PRINT("CMD0, R1 = %x\n", r1);
  if (r1 != 1u)
    return SDCARD_INVALID;
  r1 = sdcard_docmd_nodeselect(8, 0x1aa);
  uint32_t r7 = sdcard_getextresponse();
  DEBUG_PRINT("CMD8, R7 = %x %x\n", r1, r7);
  sdcard_type_t card_type;
  if (!(r1 & 4u) && (r7 & 0x1ff) == 0x1aa) {
    DEBUG_PRINT("Card is SD2\n");
    card_type = SDCARD_SD2;
  } else {
    DEBUG_PRINT("Card is SD1\n");
    card_type = SDCARD_SD1;
  }
  time0 = timer_read();
  do {
    if (!(REGS_SDCARD.ctrl & 1))
      return SDCARD_REMOVED;
    r1 = sdcard_docmd_noparam(55);
    if ((r1 & 0x80) || (r1 & ~1)) {
      DEBUG_PRINT("CMD55, R1 = %x\n", r1);
      return SDCARD_INVALID;
    }
    r1 = sdcard_docmd(41, (card_type == SDCARD_SD2? 0x40000000 : 0));
    if ((timer_read() - time0) > TIMEOUT_ACTIVE)
      break;
  } while (r1 == 1);
  DEBUG_PRINT("ACMD41, R1 = %x\n", r1);
  if (r1 != 0)
    return SDCARD_INVALID;
  if (card_type == SDCARD_SD2) {
    r1 = sdcard_docmd_nodeselect(58, 0);
    uint32_t r3 = sdcard_getextresponse();
    DEBUG_PRINT("CMD58, R3 = %x %x\n", r1, r3);
    if (r1 != 0)
      return SDCARD_INVALID;
    if (((r3 >> 30) & 3u) == 3u) {
      DEBUG_PRINT("Card is SDHC\n");
      card_type = SDCARD_SDHC;
    }
  }
  REGS_SDCARD.ctrl = SPI_SPEED(16000000u) << 8u;
  return card_type;
}

bool sdcard_read_block(uint32_t blkid, uint8_t *ptr)
{
  bool result = false;
  DEBUG_PRINT("Read block %x\n", blkid);
  uint8_t r1 = sdcard_docmd_nodeselect(17, blkid);
  DEBUG_PRINT("CMD17, R1 = %x\n", r1);
  if (r1 == 0) {
    uint32_t time0 = timer_read();
    uint8_t byt;
    do
      byt = sdcard_recvbyte();
    while(byt == 0xff && (REGS_SDCARD.ctrl & 1) &&
	  (timer_read() - time0) < TIMEOUT_READBLK);
    if (byt == 0xfe) {
      REGS_SDCARD.crc16 = 0;
      unsigned i;
      for (i=0; i<512; i++)
	ptr[i] = sdcard_recvbyte();
      uint16_t crc16_calc = REGS_SDCARD.crc16;
      uint16_t crc16_recv = sdcard_recvbyte();
      crc16_recv <<= 8; crc16_recv |= sdcard_recvbyte();
      if (crc16_recv == crc16_calc)
	result = true;
      DEBUG_PRINT("CRC16 = %x %x\n", crc16_recv, crc16_calc);
    } else {
      DEBUG_PRINT("No data from card\n");
    }
  }
  sdcard_deselect();
  return result;
}

#ifndef BOOTCODE
bool sdcard_write_block(uint32_t blkid, const uint8_t *ptr)
{
  bool result = false;
  DEBUG_PRINT("Write block %x\n", blkid);
  uint8_t r1 = sdcard_docmd_nodeselect(24, blkid);
  DEBUG_PRINT("CMD24, R1 = %x\n", r1);
  if (r1 == 0) {
    uint32_t time0 = timer_read();
    uint8_t byt;
    unsigned i;
    sdcard_sendbyte(0xfe);
    REGS_SDCARD.crc16 = 1;
    for (i=0; i<512; i++)
      sdcard_sendbyte(ptr[i]);
    uint16_t crc16_calc = REGS_SDCARD.crc16;
    DEBUG_PRINT("CRC16 = %x\n", crc16_calc);
    sdcard_sendbyte(crc16_calc >> 8);
    sdcard_sendbyte(crc16_calc);
    do
      byt = sdcard_recvbyte();
    while(byt == 0xff && (REGS_SDCARD.ctrl & 1) &&
	  (timer_read() - time0) < TIMEOUT_WRITEBLK);
    if ((byt & 0x1f) == 0x05) {
      do
	byt = sdcard_recvbyte();
      while(byt == 0x00 && (REGS_SDCARD.ctrl & 1) &&
	    (timer_read() - time0) < TIMEOUT_WRITEBLK);
      if (byt != 0x00)
	result = true;
      else {
	DEBUG_PRINT("Card did not leave busy state\n");
      }
    } else {
      DEBUG_PRINT("Data not accepted by card (%x)\n", byt);
    }
  }
  sdcard_deselect();
  return result;
}
#endif

unsigned sdcard_num_cards(void)
{
  return (REGS_SDCARD.ctrl >> 4) & 0xfu;
}

unsigned sdcard_get_card_number(void)
{
  return REGS_SDCARD.sd_select;
}

void sdcard_set_card_number(unsigned n)
{
  REGS_SDCARD.sd_select = n;
}
