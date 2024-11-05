#include "global.h"
#include "timer.h"
#include "display.h"
#include "sdcard.h"
#include "uart.h"
#include "regs.h"
#include "fatfs.h"
#include "strerr.h"
#include "mem.h"
#include "embedfile.h"

static int open_auxfile(const char *filename, fatfs_filehandle_t *fh)
{
  int r, r0;
  sdcard_set_card_number(0);
  for(;;) {
    fatfs_filehandle_t dirfh;
    if ((r = fatfs_open_dir("mega99", &dirfh)) >= 0 &&
	(r = fatfs_openat(filename, fh, &dirfh)) != -EFILENOTFOUND)
      return r;
    if ((r = fatfs_open(filename, fh)) >= 0)
      return r;
    if (sdcard_num_cards() < 2 || sdcard_get_card_number())
      break;
    r0 = r;
    sdcard_set_card_number(1);
  }
  if (r == -ENOCARD && sdcard_get_card_number())
    return r0;
  else
    return r;
}

static int load_rom(const char *filename, uint8_t *ptr, uint32_t len)
{
  display_printf("%s...", filename);
  uint32_t eflen;
  const void *ef = embedfile_find(filename, &eflen);
  if (ef) {
    if (len && eflen > len)
      eflen = len;
    display_printf("Embedded\n");
    memcpy(ptr, ef, eflen);
    return eflen;
  }
  fatfs_filehandle_t fh;
  int r = open_auxfile(filename, &fh);
  if (r >= 0) {
    r = fatfs_read(&fh, ptr, (len? len : 0x00100000));
    if (r >= 0 && len && r < len) {
      display_printf("Short file\n");
      return -1;
    }
  }
  if (r < 0)
    display_printf("%s\n", fatfs_strerror(-r));
  else
    display_printf("Loaded\n");
  return r;
}

void main()
{
  REGS_MISC.reset = 0xff;
  REGS_MISC.reset = 0xdf; // Release VDP from reset

  timer_init();
  uart_init();
  display_init();

  REGS_MISC.leds = 1u;

  /* Run main binary if it exists */
  if (load_rom("mega99sp.bin", (void *)0x40000000, 0) > 0)
    (*(void (*)(void))(void *)0x40000100)();

  /* Otherwise, just load the mandatory ROMs and start the CPU */
  if (load_rom("994a_rom_hb.u610", CPUROMH, 4096) >= 0 &&
      load_rom("994a_rom_lb.u611", CPUROML, 4096) >= 0 &&
      load_rom("994a_grom0.u500", GROM(0), 6144) >= 0 &&
      load_rom("994a_grom1.u501", GROM(1), 6144) >= 0 &&
      load_rom("994a_grom2.u502", GROM(2), 6144) >= 0) {
    REGS_MISC.reset = 0xff;
    memset(VDPRAM, 0, 0x1000);
    REGS_MISC.reset = 0x00; // Release CPU from reset
  } else {
      display_printf("ROM Loading failed!\n");
      REGS_MISC.leds = 2u;
  }
}
