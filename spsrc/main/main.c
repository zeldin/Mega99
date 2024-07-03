#include "global.h"
#include "mem.h"
#include "regs.h"
#include "uart.h"
#include "display.h"
#include "fatfs.h"

static int load_rom(const char *filename, uint8_t *ptr, uint32_t len)
{
  display_printf("%s...", filename);
  fatfs_filehandle_t fh;
  int r = fatfs_open(filename, &fh);
  if (r >= 0) {
    r = fatfs_read(&fh, ptr, len);
    if (r >= 0 && r < len) {
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
  REGS_MISC.reset = 0xf;
  uart_puts("Main SP binary entered\n");
  REGS_MISC.reset = 0xd; // Release VDP from reset

  display_init();

  REGS_MISC.leds = 1u;

  if (load_rom("994a_rom_hb.u610", CPUROMH, 4096) < 0 ||
      load_rom("994a_rom_lb.u611", CPUROML, 4096) < 0 ||
      load_rom("994a_grom0.u500", GROM(0), 6144) < 0 ||
      load_rom("994a_grom1.u501", GROM(1), 6144) < 0 ||
      load_rom("994a_grom2.u502", GROM(2), 6144) < 0 ||
      load_rom("phm3023g.bin", GROM(3), 6144) < 0) {
    display_printf("ROM Loading failed!\n");
    return;
  }

  REGS_MISC.reset = 0xf;  
  __builtin_memset(VDPRAM, 0, 0x1000);
  REGS_MISC.reset = 0xd;

  uart_puts("Starting TMS9900\n");
  REGS_MISC.reset = 0x0;
}