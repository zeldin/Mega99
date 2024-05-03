#include "global.h"
#include "timer.h"
#include "display.h"
#include "sdcard.h"
#include "regs.h"
#include "fatfs.h"

void main()
{
  timer_init();
  display_init();

  REGS_MISC.leds = 1u;

  display_printf("Good %s world!\n\n", "morning");

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
	  fatfs_filehandle_t fh;
	  if (fatfs_open("TESTFILE.TXT", &fh) >= 0) {
	    char buf[32];
	    int i, r;
	    display_printf("---vvv---\n");
	    while ((r = fatfs_read(&fh, buf, sizeof(buf))) > 0)
	      for (i=0; i<r; i++)
		display_putc(buf[i]);
	    display_printf("---^^^---\n");
	    if (r < 0)
	      display_printf("Error %x\n", (uint32_t)r);
	  } else
	    display_printf("fatfs_open failed\n");
	}
      }
    }
  }

}
