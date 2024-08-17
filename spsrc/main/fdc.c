#include "global.h"
#include "fatfs.h"
#include "strerr.h"
#include "mem.h"
#include "fdc.h"

static fatfs_filehandle_t dsk[3];
static uint8_t dsk_shape[3];
static uint8_t dsk_tracks[3];

void fdc_mount(unsigned drive, const fatfs_filehandle_t *fh)
{
  if (drive < 3) {
    FDCREGS.mounted_wp &= ~(0x11 << drive);
    uint8_t tracks = 0;
    uint8_t sectors = 0;
    uint8_t hdr[20];

    if (fh) {
      dsk[drive] = *fh;
      uint16_t nsec;
      int r = fatfs_read(&dsk[drive], hdr, 20);
      if (r == 20 && hdr[0xd] == 'D' && hdr[0xe] == 'S' && hdr[0xf] == 'K' &&
	  hdr[0xc] > 0 && hdr[0xc] < 32 && hdr[0x11] < 64 &&
	  hdr[0x12] <= 2 && hdr[0x13] <= 2 &&
	  (nsec = (hdr[0xa]<<8)|hdr[0xb]) % hdr[0xc] == 0 &&
	  (!hdr[0x11] || nsec == hdr[0x0c]*hdr[0x11]*(hdr[0x12] == 2? 2 : 1))
	  && dsk[drive].size >= (nsec << 8)) {
	sectors = hdr[0xc];
	tracks = hdr[0x11];
	if (!tracks) {
	  tracks = nsec / sectors;
	  if (hdr[0x12] == 2 || (hdr[0x12] == 0 && tracks >= 64))
	    sectors |= 0x80;
	} else if (hdr[0x12] == 2) {
	  tracks <<= 1;
	  sectors |= 0x80;
	}
	if (hdr[0x13] == 2 || (hdr[0x13] == 0 && hdr[0xc] >= 16))
	  sectors |= 0x40;
	unsigned i;
	for (i = 10; i>0 && hdr[i-1] == 0x20; --i)
	  ;
	hdr[i] = 0;
      } else {
	strcpy(hdr, "UNKNOWN");
	tracks = 40;
	switch(dsk[drive].size) {
	case 9*40*256:
	  sectors = 9;
	  break;
	case 9*40*2*256:
	  sectors = 18;
	  break;
	case 9*40*4*256:
	  sectors = 18;
	  tracks = 80;
	  break;
	}
	if (dsk[drive].size < ((tracks*sectors)<<8))
	  sectors = 0;
	if (!sectors) {
	  fprintf(stderr, "Error: Not a valid disk image\n");
	  fh = NULL;
	} else {
	  fprintf(stderr, "Warning: ");
	  printf("Image is not formatted, guessing type\n");
	}
      }
    }

    if (fh) {
      if (sectors & 0x10)
	sectors |= 0x40; /* DD */
      if (tracks & 0x40)
	sectors |= 0x80; /* DS */
      dsk_shape[drive] = sectors;
      dsk_tracks[drive] = tracks;
      FDCREGS.img_shape = sectors;
      if (fatfs_is_readonly(&dsk[drive]))
	FDCREGS.mounted_wp |= (0x01 << drive);
      FDCREGS.mounted_wp |= (0x10 << drive);
      printf("Mounted disk \"%s\" %u tracks %cS/%cD\n",
	     hdr,
	     (unsigned)((sectors & 0x80)? (tracks >> 1) : tracks),
	     ((sectors & 0x80)? 'D' : 'S'),
	     ((sectors & 0x40)? 'D' : 'S'));
    } else {
      dsk[drive].size = 0;
      dsk_shape[drive] = 0;
      dsk_tracks[drive] = 0;
    }
  }
}

void fdc_task(void)
{
  uint8_t rd_wr = FDCREGS.rd_wr;
  if (!rd_wr)
    return;
  uint8_t track_side = FDCREGS.track_side;
  uint8_t sector = FDCREGS.sector;
  FDCREGS.ack = 1u;
  for (unsigned drive = 0; drive < 3; drive ++) {
    if (!((rd_wr >> drive) & 0x11) || !dsk[drive].size)
      // Not selected, or not mounted
      continue;
    uint8_t track = track_side;
    uint8_t sps = dsk_shape[drive] & 0x3f;
    if (!(dsk_shape[drive] & 0x80))
      // Single sided
      track >>= 1;
    if (track >= dsk_tracks[drive] || sector >= sps)
      // Outside disk
      continue;
    uint32_t img_offs = (track * sps + sector) << 8;
    if (((rd_wr >> drive) & 0x01) && !((FDCREGS.mounted_wp >> drive) & 0x01)) {
      /* Write */
      int r = fatfs_setpos(&dsk[drive], img_offs);
      if (r >= 0)
	r = fatfs_write(&dsk[drive], FDCBUF, 256);
      if (r < 0) {
	printf("DSK%u: ", drive+1);
	fprintf(stderr, "%s\n", fatfs_strerror(-r));
      }
    }
    if ((rd_wr >> drive) & 0x10) {
      /* Read */
      memset(FDCBUF, 0xff, 256);
      int r = fatfs_setpos(&dsk[drive], img_offs);
      if (r >= 0)
	r = fatfs_read(&dsk[drive], FDCBUF, 256);
      if (r < 0) {
	printf("DSK%u: ", drive+1);
	fprintf(stderr, "%s\n", fatfs_strerror(-r));
      }
    }
  }
  FLUSH;
  FDCREGS.ack = 0u;
}
