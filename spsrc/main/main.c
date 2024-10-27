#include "global.h"
#include "timer.h"
#include "mem.h"
#include "regs.h"
#include "uart.h"
#include "display.h"
#include "sdcard.h"
#include "fatfs.h"
#include "zipfile.h"
#include "rpk.h"
#include "tape.h"
#include "fdc.h"
#include "strerr.h"
#include "overlay.h"
#include "keyboard.h"
#include "reset.h"

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

static int load_zipped_rom(const char *filename, const char *zipfilename,
			   fatfs_filehandle_t *fh, uint8_t *ptr, uint32_t len)
{
  int r = zipfile_open_fh(fh);
  if (!r) {
    r = zipfile_open_entry(filename);
    if (!r) {
      printf("[%s]...", zipfilename);
      fflush(stdout);
      r = zipfile_read(ptr, len);
      if (r >= (int)len)
	return r;
      if (r >= 0) {
	fprintf(stderr, "Short file\n");
	return -1;
      }
      fprintf(stderr, "%s\n", zipfile_strerror(r));
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
  int r = open_auxfile(filename, &fh);
  if (r >= 0) {
    r = fatfs_read(&fh, ptr, len);
    if (r >= 0 && r < len) {
      fprintf(stderr, "Short file\n");
      return -1;
    }
  } else if (zipfilename) {
    if (open_auxfile(zipfilename, &fh) >= 0) {
      int t = load_zipped_rom(filename, zipfilename, &fh, ptr, len);
      if (t) {
	r = t;
	if (r < 0)
	  return r;
      }
    }
  }
  if (r < 0) {
    fprintf(stderr, "%s\n", fatfs_strerror(-r));
  } else
    printf("Loaded\n");
  return r;
}

void main()
{
  printf("Main SP binary entered\n");

  timer_init();
  reset_set_other(true);
  reset_set_vdp(true);
  reset_set_vdp(false);
  keyboard_block();
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
      load_rom("fdc_dsr.u26", "ti99_fdc.zip", FDCROM, 4096) < 0 ||
      load_rom("fdc_dsr.u27", "ti99_fdc.zip", FDCROM+4096, 4096) < 0) {
    fprintf(stderr, "ROM Loading failed!\n");
    REGS_MISC.leds = 2u;
    return;
  }

  sdcard_set_card_number(0);
  reset_set_vdp(true);
  memset(VDPRAM, 0, 0x1000);
  reset_set_vdp(false);

  // Use LED3/LED4 for drive activity
  REGS_MISC.led3_rgb = 0x00ff00u;
  REGS_MISC.led4_rgb = 0x00ff00u;
  REGS_MISC.leds |= 0x00770000u;

  printf("Starting TMS9900\n");
  keyboard_unblock();
  keyboard_flush();
  reset_set_other(false);

  for(;;) {
    overlay_task();
    keyboard_task();
    tape_task();
    fdc_task();
  }
}
