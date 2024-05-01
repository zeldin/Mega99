#include "global.h"
#include "timer.h"
#include "display.h"
#include "sdcard.h"
#include "regs.h"

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
	if (card_type == SDCARD_SDHC) {
	  uint8_t buf[512];
	  if (sdcard_read_block(8192u, buf)) {
	    unsigned i;
	    for (i=0; i<512; i++)
	      display_putc(buf[i] < ' '? '_' : buf[i]);
	  } else
	    display_printf("Failed to read block\n");
	}
      }
    }
  }

}
