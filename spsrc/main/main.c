#include "global.h"
#include "timer.h"
#include "mem.h"
#include "regs.h"
#include "uart.h"
#include "display.h"
#include "fatfs.h"
#include "zipfile.h"
#include "rpk.h"
#include "strerr.h"
#include "overlay.h"

static int load_zipped_rom(const char *filename, const char *zipfilename,
			   uint8_t *ptr, uint32_t len)
{
  int r = zipfile_open(zipfilename);
  if (!r) {
    r = zipfile_open_entry(filename);
    if (!r) {
      printf("[%s]...", zipfilename);
      fflush(stdout);
      r = zipfile_read(ptr, len);
      if (r >= (int)len)
	return r;
      if (r >= 0) {
	printf("Short file\n");
	return -1;
      }
      printf("%s\n", zipfile_strerror(r));
      return r;
    }
  }
  return 0;
}

static int load_rom(const char *filename, const char *zipfilename,
		    uint8_t *ptr, uint32_t len)
{
  printf("%s...", filename);
  fflush(stdout);
  fatfs_filehandle_t fh;
  int r = fatfs_open(filename, &fh);
  if (r >= 0) {
    r = fatfs_read(&fh, ptr, len);
    if (r >= 0 && r < len) {
      printf("Short file\n");
      return -1;
    }
  } else if (zipfilename) {
    int t = load_zipped_rom(filename, zipfilename, ptr, len);
    if (t) {
      r = t;
      if (r < 0)
	return r;
    }
  }
  if (r < 0) {
    printf("%s\n", fatfs_strerror(-r));
  } else
    printf("Loaded\n");
  return r;
}

void main()
{
  REGS_MISC.reset = 0xff;
  printf("Main SP binary entered\n");
  REGS_MISC.reset = 0xdf; // Release VDP from reset

  timer_init();
  display_init();
  overlay_init();

  REGS_MISC.leds = 1u;

  zipfile_init();

  if (load_rom("994a_rom_hb.u610", "ti99_4a.zip", CPUROMH, 4096) < 0 ||
      load_rom("994a_rom_lb.u611", "ti99_4a.zip", CPUROML, 4096) < 0 ||
      load_rom("994a_grom0.u500", "ti99_4a.zip", GROM(0), 6144) < 0 ||
      load_rom("994a_grom1.u501", "ti99_4a.zip", GROM(1), 6144) < 0 ||
      load_rom("994a_grom2.u502", "ti99_4a.zip", GROM(2), 6144) < 0 ||
      load_rom("cd2325a.vsm", "ti99_speech.zip", SPEECHROM, 16384) < 0 ||
      load_rom("cd2326a.vsm", "ti99_speech.zip", SPEECHROM+16384, 16384) < 0 ||
      load_rpk("extended_basic.rpk") < 0) {
    printf("ROM Loading failed!\n");
    return;
  }

  REGS_MISC.reset = 0xff;
  memset(VDPRAM, 0, 0x1000);
  REGS_MISC.reset = 0xdf;

  printf("Starting TMS9900\n");
  REGS_MISC.reset = 0x00;
}
