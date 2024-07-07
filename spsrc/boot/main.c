#include "global.h"
#include "timer.h"
#include "display.h"
#include "sdcard.h"
#include "uart.h"
#include "regs.h"
#include "fatfs.h"
#include "mem.h"

static int load_rom(const char *filename, uint8_t *ptr, uint32_t len)
{
  display_printf("%s...", filename);
  fatfs_filehandle_t fh;
  int r = fatfs_open(filename, &fh);
  if (r >= 0) {
    r = fatfs_read(&fh, ptr, (len? len : 0x00100000));
    if (r >= 0 && len && r < len) {
      display_printf("Short file\n");
      return -1;
    }
  }
  if (r < 0)
    display_printf("%x\n", (uint32_t)r);
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
  } else
      display_printf("ROM Loading failed!\n");
}
