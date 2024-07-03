#include "global.h"
#include "timer.h"
#include "display.h"
#include "sdcard.h"
#include "uart.h"
#include "regs.h"
#include "fatfs.h"
#include "mem.h"

static void load_rom(const char *filename, uint8_t *ptr, uint32_t len)
{
  display_printf("%s...", filename);
  fatfs_filehandle_t fh;
  int r = fatfs_open(filename, &fh);
  if (r >= 0) {
    r = fatfs_read(&fh, ptr, len);
    if (r >= 0 && r < len) {
      display_printf("Short file\n");
      return;
    }
  }
  if (r < 0)
    display_printf("%x\n", (uint32_t)r);
  else
    display_printf("Loaded\n");
}

void main()
{
  REGS_MISC.reset = 0xf;
  REGS_MISC.reset = 0xd; // Release VDP from reset

  timer_init();
  uart_init();
  display_init();

  REGS_MISC.leds = 1u;

  load_rom("994a_rom_hb.u610", CPUROMH, 4096);
  load_rom("994a_rom_lb.u611", CPUROML, 4096);
  load_rom("994a_grom0.u500", GROM(0), 6144);
  load_rom("994a_grom1.u501", GROM(1), 6144);
  load_rom("994a_grom2.u502", GROM(2), 6144);
  load_rom("phm3023g.bin", GROM(3), 6144);

  uint32_t last_sdstatus = ~0;
  for (;;) {
    uint32_t sdstatus = sdcard_status();
    if ((sdstatus & 4u) || sdstatus != last_sdstatus) {
      last_sdstatus = sdstatus;
      display_printf("%x\n", sdstatus);
      if ((sdstatus & 5u) == 5u) {
	sdcard_type_t card_type = sdcard_activate();
	display_printf("Activate => %x\n", (uint32_t)card_type);
	if (card_type > SDCARD_INVALID) {
	  REGS_MISC.reset = 0x0; // Release CPU from reset
	}
      }
    }
  }

}
