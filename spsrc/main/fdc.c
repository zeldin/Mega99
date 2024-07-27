#include "global.h"
#include "fatfs.h"
#include "strerr.h"
#include "mem.h"
#include "fdc.h"

static fatfs_filehandle_t dsk[2];

void fdc_mount(unsigned drive, const fatfs_filehandle_t *fh)
{
  FDCREGS.mounted_wp &= ~(0x11 << drive);
  if (drive < 2) {
    if (fh) {
      dsk[drive] = *fh;
      FDCREGS.img_size = fh->size >> 8;
      FDCREGS.mounted_wp |= (0x11 << drive);
    } else
      dsk[drive].size = 0;
  }
}

void fdc_task(void)
{
  uint8_t rd_wr = FDCREGS.rd_wr;
  if (!rd_wr)
    return;
  uint32_t lba = FDCREGS.lba;
  lba -= 10;
  unsigned track = lba / 11;
  unsigned sector = lba % 11;
  lba = ((track*9)+sector) << 8;
  FDCREGS.ack = 1u;
  for (unsigned drive = 0; drive < 2; drive ++) {
    if ((rd_wr >> drive) & 0x01) {
      /* FIXME: Write */
    }
    if ((rd_wr >> drive) & 0x10) {
      /* Read */
      memset(FDCBUF, 0xff, 256);
      if (dsk[drive].size > lba) {
	int r = fatfs_setpos(&dsk[drive], lba);
	if (r >= 0)
	  r = fatfs_read(&dsk[drive], FDCBUF, 256);
	if (r < 0) {
	  printf("DSK%u: ", drive+1);
	  fprintf(stderr, "%s\n", fatfs_strerror(-r));
	}
      }
    }
  }
  FLUSH;
  FDCREGS.ack = 0u;
}
