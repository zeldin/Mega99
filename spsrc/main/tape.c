#include "global.h"
#include "fatfs.h"
#include "strerr.h"
#include "regs.h"

#define FORMAT_8BIT   0u
#define FORMAT_16BIT  2u
#define FORMAT_MONO   0u
#define FORMAT_STEREO 4u
#define FORMAT_TAP    8u

static fatfs_filehandle_t tape_file;

void tape_task(void)
{
  uint16_t head = REGS_TAPE.head;
  uint16_t tail = REGS_TAPE.tail;
  if (!tape_file.size) {
    uint16_t control = REGS_TAPE.control;
    if ((control & 1)) {
      if (head == tail)
	REGS_TAPE.control = 0;
    }
    return;
  }
  uint16_t memsize = REGS_TAPE.memsize;
  uint16_t room = memsize + head - tail;
  if (!(room &= ~511))
    return;
  uint32_t pos = tape_file.filepos;
  int n = fatfs_read(&tape_file, TAPE_SAMPLES+(tail & (memsize-1)), room);
  if (n <= 0) {
    tape_file.size = 0;
    if (n < 0) {
      printf("CS1: ");
      fprintf(stderr, "%s\n", fatfs_strerror(-n));
    }
  } else
    REGS_TAPE.tail = tail + n;
}

static int tape_check_format(void)
{
  uint8_t hdr[16];
  int r = fatfs_read(&tape_file, hdr, 12);
  if (r < 0)
    return r;
  if (r > 0 && hdr[0] == 0xff) {
    /* TAP file */
    if ((r = fatfs_setpos(&tape_file, 0)) < 0)
      return r;
    memset(TAPE_SAMPLES, 0, 768);
    REGS_TAPE.tail = 768u;
    REGS_TAPE.sample_rate = 1279u;
    return FORMAT_TAP | 1u;
  }
  if (r < 12) {
    fprintf(stderr, "Short file\n");
    return 0;
  }
  if (memcmp(hdr, "RIFF", 4) || memcmp(hdr+8, "WAVE", 4)) {
    fprintf(stderr, "Unknown file format\n");
    return 0;
  }
  unsigned format = 0;
  while ((r = fatfs_read(&tape_file, hdr, 8)) == 8) {
    uint32_t len = hdr[4] | (hdr[5] << 8) | (hdr[6] << 16) | (hdr[7] << 24);
    if (!format && !memcmp(hdr, "fmt ", 4) && len >= 16) {
      len += tape_file.filepos;
      if ((r = fatfs_read(&tape_file, hdr, 16)) < 16)
	break;
      uint16_t wFormatTag = hdr[0] | (hdr[1] << 8);
      uint16_t nChannels = hdr[2] | (hdr[3] << 8);
      uint32_t nSamplesPerSec = hdr[4] | (hdr[5] << 8) | (hdr[6] << 16) | (hdr[7] << 24);
      uint16_t wBitsPerSample  = hdr[14] | (hdr[15] << 8);
      if (nSamplesPerSec < 2000u || nSamplesPerSec > 48000u) {
	fprintf(stderr, "Invalid sample rate\n");
	return 0;
      }
      if (wFormatTag != 1u || nChannels < 1u || nChannels > 2u ||
	  (wBitsPerSample != 8u && wBitsPerSample != 16u)) {
	fprintf(stderr, "Invalid sample format\n");
	return 0;
      }
      REGS_TAPE.sample_rate = (3579545u + (nSamplesPerSec >> 1)) / nSamplesPerSec - 1u;
      format = 1u;
      if (nChannels == 2u)
	format |= FORMAT_STEREO;
      else
	format |= FORMAT_MONO;
      if (wBitsPerSample == 16u)
	format |= FORMAT_16BIT;
      else
	format |= FORMAT_8BIT;
    } else
	len += tape_file.filepos;
    if (!memcmp(hdr, "data", 4)) {
      if (len < tape_file.size)
	tape_file.size = len;
      break;
    }
    if ((r = fatfs_setpos(&tape_file, len)) < 0)
      break;
  }
  if (r < 0)
    return r;
  if (!format) {
    fprintf(stderr, "Missing fmt chunk\n");
    return 0;
  }
  return format;
}

void tape_start(const fatfs_filehandle_t *fh)
{
  tape_file = *fh;
  if (!tape_file.size)
    return;
  REGS_TAPE.control = 0;
  REGS_TAPE.head = 0;
  REGS_TAPE.tail = 0;

  int r = tape_check_format();
  if (!r) return;

  if (r >= 0 && (tape_file.filepos & 0x1ffu)) {
    uint16_t tail = REGS_TAPE.tail;
    int n = fatfs_read(&tape_file, TAPE_SAMPLES+tail,
		       0x200u-(tape_file.filepos & 0x1ffu));
    if (n < 0)
      r = n;
    else
      REGS_TAPE.tail = tail + n;
  }
  if (r < 0) {
    fprintf(stderr, "%s\n", fatfs_strerror(-r));
    return;
  }

  tape_task();
  REGS_TAPE.control = r;
}
